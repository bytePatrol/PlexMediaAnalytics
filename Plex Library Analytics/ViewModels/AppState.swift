import Foundation
import Combine

// MARK: - Server Record (UserDefaults-safe, no token)

private struct ServerRecord: Codable {
    let id: String
    let name: String
    let host: String
    let port: Int
    let isSecure: Bool
}

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .dashboard
    @Published var connectionStatus: ServerConnectionStatus = .disconnected
    @Published var currentServer: PlexServer?
    @Published var isLoading = false
    @Published var showServerSetup = false
    @Published var selectedLibraryName: String? = nil
    @Published var machineIdentifier: String? = nil

    // Saved server list (tokens kept in Keychain, metadata in UserDefaults)
    @Published var savedServers: [PlexServer] = []

    let repository: PlexRepositoryProtocol

    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: AnyCancellable?

    private static let savedServersKey = "savedServers"

    init(repository: PlexRepositoryProtocol = PlexRepository()) {
        self.repository = repository

        // Apply default tab from settings
        if let raw = UserDefaults.standard.string(forKey: "defaultView"),
           let tab = AppTab(rawValue: raw.capitalized) {
            self.selectedTab = tab
        }

        repository.connectionStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionStatus)

        repository.isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        repository.machineIdentifier
            .receive(on: DispatchQueue.main)
            .assign(to: &$machineIdentifier)

        loadSavedServers()
        autoConnectIfNeeded()
        startAutoRefreshTimer()
    }

    // MARK: - Server Connect

    func connectToServer(_ server: PlexServer) {
        currentServer = server
        addOrUpdateServer(server)
        UserDefaults.standard.set(server.id, forKey: "lastConnectedServerID")
        Task {
            do {
                try await repository.connect(to: server)
                try await repository.refreshAll()
            } catch {
                print("Connection error: \(error.localizedDescription)")
            }
        }
    }

    func disconnectFromServer() {
        currentServer = nil
        repository.connectionStatus.send(.disconnected)
    }

    // MARK: - Saved Servers

    func addOrUpdateServer(_ server: PlexServer) {
        if let index = savedServers.firstIndex(where: { $0.id == server.id }) {
            savedServers[index] = server
        } else {
            savedServers.append(server)
        }
        persistServers()
    }

    func removeServer(_ server: PlexServer) {
        savedServers.removeAll { $0.id == server.id }
        KeychainManager.deleteToken(for: server.id)
        persistServers()
        if currentServer?.id == server.id {
            disconnectFromServer()
        }
    }

    // MARK: - Thumbnail

    func thumbnailURL(ratingKey: String, width: Int = 200, height: Int = 300) -> URL? {
        guard let server = currentServer, let base = server.baseURL else { return nil }
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        components.path = "/library/metadata/\(ratingKey)/thumb"
        components.queryItems = [
            URLQueryItem(name: "X-Plex-Token", value: server.token),
        ]
        return components.url
    }

    // MARK: - Refresh

    func refreshData() {
        Task {
            do {
                try await repository.refreshAll()
            } catch {
                print("Refresh error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Auto Refresh

    func startAutoRefreshTimer() {
        refreshTimer?.cancel()
        refreshTimer = nil

        let interval = UserDefaults.standard.string(forKey: "autoRefreshInterval") ?? "off"
        guard let seconds = refreshIntervalSeconds(interval) else { return }

        refreshTimer = Timer.publish(every: seconds, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.connectionStatus.isConnected else { return }
                self.refreshData()
            }
    }

    // MARK: - Private

    private func loadSavedServers() {
        guard let data = UserDefaults.standard.data(forKey: Self.savedServersKey),
              let records = try? JSONDecoder().decode([ServerRecord].self, from: data) else { return }

        savedServers = records.compactMap { record in
            guard let token = KeychainManager.loadToken(for: record.id), !token.isEmpty else { return nil }
            return PlexServer(id: record.id, name: record.name, host: record.host, port: record.port,
                              token: token, isSecure: record.isSecure)
        }
    }

    private func persistServers() {
        let records = savedServers.map { server in
            ServerRecord(id: server.id, name: server.name, host: server.host,
                         port: server.port, isSecure: server.isSecure)
        }
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: Self.savedServersKey)
        }
        // Persist tokens to Keychain
        for server in savedServers {
            try? KeychainManager.save(token: server.token, for: server.id)
        }
    }

    private func autoConnectIfNeeded() {
        guard let lastID = UserDefaults.standard.string(forKey: "lastConnectedServerID"),
              let server = savedServers.first(where: { $0.id == lastID }) else { return }
        connectToServer(server)
    }

    private func refreshIntervalSeconds(_ setting: String) -> TimeInterval? {
        switch setting {
        case "5m": return 300
        case "15m": return 900
        case "30m": return 1800
        case "1h": return 3600
        default: return nil
        }
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case libraries = "Libraries"
    case analytics = "Analytics"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .libraries: return "books.vertical"
        case .analytics: return "chart.bar"
        }
    }
}
