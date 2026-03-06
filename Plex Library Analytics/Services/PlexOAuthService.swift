import Foundation
import AppKit

/// Handles the Plex OAuth PIN-based authentication flow.
///
/// Flow:
/// 1. Request a PIN from plex.tv/api/v2/pins
/// 2. Open the Plex auth page in the user's browser with the PIN code
/// 3. Poll the PIN endpoint until the user completes sign-in (authToken becomes non-null)
/// 4. Use the authToken to fetch the user's available servers via plex.tv/api/v2/resources
final class PlexOAuthService {
    static let clientIdentifier = "plex-library-analytics-\(machineID)"

    private static var machineID: String {
        // Stable per-machine identifier so Plex recognizes this device across launches
        if let existing = UserDefaults.standard.string(forKey: "PlexClientIdentifier") {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: "PlexClientIdentifier")
        return id
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let session: URLSession
    private var pollingTask: Task<String, Error>?

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - OAuth Flow

    /// Step 1+2: Request a PIN and open the browser for the user to sign in.
    /// Returns the PIN id needed for polling.
    func startOAuth() async throws -> OAuthPIN {
        let pin = try await requestPIN()

        // Build the auth URL manually — the fragment after # uses its own query-like format.
        // URLComponents would percent-encode the fragment incorrectly, so we build the string
        // directly and use a permissive character set for URL(string:).
        let fragment = [
            "clientID=\(Self.clientIdentifier)",
            "code=\(pin.code)",
            "context%5Bdevice%5D%5Bproduct%5D=Plex%20Library%20Analytics",
            "context%5Bdevice%5D%5Bplatform%5D=macOS",
            "context%5Bdevice%5D%5Bdevice%5D=Plex%20Library%20Analytics",
        ].joined(separator: "&")

        let authURLString = "https://app.plex.tv/auth#?\(fragment)"

        if let url = URL(string: authURLString) {
            await MainActor.run {
                NSWorkspace.shared.open(url)
            }
        }

        return pin
    }

    /// Step 3: Poll until the user completes sign-in. Returns the auth token.
    func pollForToken(pinID: Int) async throws -> String {
        let maxAttempts = 120  // 2 minutes at 1s intervals
        for _ in 0..<maxAttempts {
            try Task.checkCancellation()
            try await Task.sleep(for: .seconds(1))

            let token = try await checkPIN(id: pinID)
            if let token {
                return token
            }
        }
        throw OAuthError.timeout
    }

    /// Step 4: Fetch the user's available servers using their auth token.
    func fetchServers(token: String) async throws -> [DiscoveredServer] {
        var components = URLComponents(string: "https://plex.tv/api/v2/resources")!
        components.queryItems = [
            URLQueryItem(name: "includeHttps", value: "1"),
            URLQueryItem(name: "includeRelay", value: "1"),
        ]

        var request = URLRequest(url: components.url!)
        applyHeaders(to: &request)
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OAuthError.serverFetchFailed
        }

        let resources = try Self.decoder.decode([PlexResourceResponse].self, from: data)

        return resources
            .filter { $0.provides.contains("server") }
            .compactMap { resource -> DiscoveredServer? in
                let conns = resource.connections ?? []
                guard let token = resource.accessToken, !token.isEmpty else { return nil }

                // Pick the best connection: prefer local, then remote, then relay
                let localConn = conns.first(where: { $0.local == true && $0.relay != true })
                let remoteConn = conns.first(where: { $0.local != true && $0.relay != true })
                let relayConn = conns.first(where: { $0.relay == true })
                let best = localConn ?? remoteConn ?? relayConn ?? conns.first

                return DiscoveredServer(
                    name: resource.name,
                    sourceTitle: resource.sourceTitle ?? resource.name,
                    host: best?.address ?? "unknown",
                    port: best?.port ?? 32400,
                    isSecure: best?.protocol == "https",
                    accessToken: token,
                    isOwned: resource.owned ?? false,
                    connections: conns.compactMap { conn in
                        guard let address = conn.address else { return nil }
                        return ServerConnection(
                            address: address,
                            port: conn.port ?? 32400,
                            isLocal: conn.local ?? false,
                            isRelay: conn.relay ?? false,
                            isSecure: conn.protocol == "https",
                            uri: conn.uri ?? ""
                        )
                    }
                )
            }
    }

    func cancel() {
        pollingTask?.cancel()
    }

    // MARK: - Private API Calls

    private func requestPIN() async throws -> OAuthPIN {
        var components = URLComponents(string: "https://plex.tv/api/v2/pins")!
        components.queryItems = [
            URLQueryItem(name: "strong", value: "true"),
            URLQueryItem(name: "X-Plex-Product", value: "Plex Library Analytics"),
            URLQueryItem(name: "X-Plex-Client-Identifier", value: Self.clientIdentifier),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        applyHeaders(to: &request)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...201).contains(http.statusCode) else {
            throw OAuthError.pinRequestFailed
        }

        let pinResponse = try Self.decoder.decode(PINResponse.self, from: data)
        return OAuthPIN(id: pinResponse.id, code: pinResponse.code)
    }

    private func checkPIN(id: Int) async throws -> String? {
        var request = URLRequest(url: URL(string: "https://plex.tv/api/v2/pins/\(id)")!)
        applyHeaders(to: &request)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OAuthError.pinCheckFailed
        }

        let pinResponse = try Self.decoder.decode(PINResponse.self, from: data)
        // authToken is null until the user completes sign-in in the browser
        guard let token = pinResponse.authToken, !token.isEmpty else {
            return nil
        }
        return token
    }

    private func applyHeaders(to request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
        request.setValue("Plex Library Analytics", forHTTPHeaderField: "X-Plex-Product")
        request.setValue("1.0.0", forHTTPHeaderField: "X-Plex-Version")
        request.setValue("macOS", forHTTPHeaderField: "X-Plex-Platform")
        request.setValue(ProcessInfo.processInfo.operatingSystemVersionString, forHTTPHeaderField: "X-Plex-Platform-Version")
        request.setValue(Host.current().localizedName ?? "Mac", forHTTPHeaderField: "X-Plex-Device-Name")
    }
}

// MARK: - Data Types

struct OAuthPIN {
    let id: Int
    let code: String
}

struct DiscoveredServer: Identifiable, Hashable {
    var id: String { name + host }
    let name: String
    let sourceTitle: String
    let host: String
    let port: Int
    let isSecure: Bool
    let accessToken: String
    let isOwned: Bool
    let connections: [ServerConnection]

    func toPlexServer() -> PlexServer {
        PlexServer(
            name: name,
            host: host,
            port: port,
            token: accessToken,
            isSecure: isSecure
        )
    }
}

struct ServerConnection: Hashable {
    let address: String
    let port: Int
    let isLocal: Bool
    let isRelay: Bool
    let isSecure: Bool
    let uri: String
}

// MARK: - API Response Models

private struct PINResponse: Decodable {
    let id: Int
    let code: String
    let authToken: String?
}

private struct PlexResourceResponse: Decodable {
    let name: String
    let provides: String
    let owned: Bool?
    let accessToken: String?
    let sourceTitle: String?
    let connections: [PlexConnectionResponse]?

    // Some Plex API versions use different key casing
    enum CodingKeys: String, CodingKey {
        case name
        case provides
        case owned
        case accessToken
        case sourceTitle
        case connections
    }
}

private struct PlexConnectionResponse: Decodable {
    let address: String?
    let port: Int?
    let uri: String?
    let local: Bool?
    let relay: Bool?
    let `protocol`: String?

    enum CodingKeys: String, CodingKey {
        case address
        case port
        case uri
        case local
        case relay
        case `protocol`
    }
}

// MARK: - Errors

enum OAuthError: LocalizedError {
    case pinRequestFailed
    case pinCheckFailed
    case timeout
    case serverFetchFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .pinRequestFailed: return "Failed to start Plex sign-in. Check your network connection."
        case .pinCheckFailed: return "Failed to verify sign-in status."
        case .timeout: return "Sign-in timed out. Please try again."
        case .serverFetchFailed: return "Failed to fetch your Plex servers."
        case .cancelled: return "Sign-in was cancelled."
        }
    }
}
