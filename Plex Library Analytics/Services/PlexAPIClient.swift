import Foundation

protocol PlexAPIClientProtocol {
    func testConnection(server: PlexServer) async throws -> Bool
    func fetchLibraries(server: PlexServer) async throws -> [PlexLibrary]
    func fetchLibraryItems(server: PlexServer, libraryKey: String, libraryTitle: String, libraryType: LibraryType) async throws -> [MediaItem]
    func thumbnailURL(server: PlexServer, ratingKey: String, width: Int, height: Int) -> URL?
    func fetchMachineIdentifier(server: PlexServer) async throws -> String
}

final class PlexAPIClient: PlexAPIClientProtocol {
    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            // Local Plex servers typically use self-signed SSL certificates.
            // Create a URLSession that trusts them so connections don't fail.
            self.session = URLSession(
                configuration: .default,
                delegate: PlexTrustDelegate.shared,
                delegateQueue: nil
            )
        }
    }

    // MARK: - Connection Test

    func testConnection(server: PlexServer) async throws -> Bool {
        let url = try buildURL(server: server, path: "/")
        let request = authenticatedRequest(url: url, token: server.token)
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode == 200
    }

    // MARK: - Libraries

    func fetchLibraries(server: PlexServer) async throws -> [PlexLibrary] {
        let url = try buildURL(server: server, path: "/library/sections")
        let request = authenticatedRequest(url: url, token: server.token)
        let (data, _) = try await session.data(for: request)

        let container = try JSONDecoder().decode(LibrarySectionsResponse.self, from: data)
        return container.mediaContainer.directory.map { dir in
            PlexLibrary(
                id: dir.key,
                title: dir.title,
                type: LibraryType(rawValue: dir.type) ?? .movie,
                icon: iconForLibrary(title: dir.title, type: dir.type),
                itemCount: 0,
                totalSizeGB: 0,
                qualityDistribution: QualityDistribution(ultra4K: 0, fullHD1080p: 0, hd720p: 0, sd: 0)
            )
        }
    }

    // MARK: - Library Items (paginated internally)

    func fetchLibraryItems(server: PlexServer, libraryKey: String, libraryTitle: String, libraryType: LibraryType) async throws -> [MediaItem] {
        let pageSize = 500
        var allItems: [MediaItem] = []
        var start = 0

        while true {
            let url = try buildURL(server: server, path: "/library/sections/\(libraryKey)/all")
            var request = authenticatedRequest(url: url, token: server.token)

            // Append paging query parameters
            var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            var queryItems = components.queryItems ?? []
            queryItems.append(contentsOf: [
                URLQueryItem(name: "X-Plex-Container-Start", value: String(start)),
                URLQueryItem(name: "X-Plex-Container-Size", value: String(pageSize)),
            ])
            // For show libraries, request episode-level metadata (type=4) which
            // includes Media/Part data needed to compute file sizes and quality.
            if libraryType == .show {
                queryItems.append(URLQueryItem(name: "type", value: "4"))
            }
            components.queryItems = queryItems
            request.url = components.url

            let (data, _) = try await session.data(for: request)
            let container = try JSONDecoder().decode(LibraryItemsResponse.self, from: data)

            let page = container.mediaContainer.metadata?.compactMap { metadata in
                parseMediaItem(from: metadata, libraryTitle: libraryTitle)
            } ?? []

            allItems.append(contentsOf: page)

            let total = container.mediaContainer.totalSize ?? page.count
            start += pageSize
            if start >= total || page.isEmpty { break }
        }

        return allItems
    }

    // MARK: - Server Identity

    func fetchMachineIdentifier(server: PlexServer) async throws -> String {
        let url = try buildURL(server: server, path: "/identity")
        let request = authenticatedRequest(url: url, token: server.token)
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(IdentityResponse.self, from: data)
        return response.mediaContainer.machineIdentifier
    }

    // MARK: - Thumbnail URL

    func thumbnailURL(server: PlexServer, ratingKey: String, width: Int = 200, height: Int = 300) -> URL? {
        guard let base = server.baseURL else { return nil }
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        components.path = "/photo/:/transcode"
        components.queryItems = [
            URLQueryItem(name: "url", value: "/library/metadata/\(ratingKey)/thumb"),
            URLQueryItem(name: "width", value: String(width)),
            URLQueryItem(name: "height", value: String(height)),
            URLQueryItem(name: "minSize", value: "1"),
            URLQueryItem(name: "X-Plex-Token", value: server.token),
        ]
        return components.url
    }

    // MARK: - Private Helpers

    private func buildURL(server: PlexServer, path: String) throws -> URL {
        guard let baseURL = server.baseURL else {
            throw PlexAPIError.invalidURL
        }
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw PlexAPIError.invalidURL
        }
        return url
    }

    private func authenticatedRequest(url: URL, token: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("PlexLibraryAnalytics", forHTTPHeaderField: "X-Plex-Product")
        request.setValue("1.0.0", forHTTPHeaderField: "X-Plex-Version")
        request.setValue("macOS", forHTTPHeaderField: "X-Plex-Platform")
        request.timeoutInterval = 30
        return request
    }

    private func iconForLibrary(title: String, type: String) -> String {
        let lowered = title.lowercased()
        if lowered.contains("kid") {
            return type == "movie" ? "🎨" : "🧸"
        }
        return type == "movie" ? "🎬" : "📺"
    }

    private func parseMediaItem(from metadata: MetadataResponse, libraryTitle: String) -> MediaItem? {
        guard let media = metadata.media?.first,
              let part = media.part?.first else { return nil }

        let videoStream = media.part?.first?.stream?.first(where: { $0.streamType == 1 })
        let audioStream = media.part?.first?.stream?.first(where: { $0.streamType == 2 })
        let subtitleStreams = media.part?.first?.stream?.filter { $0.streamType == 3 } ?? []

        let resolution = VideoResolution(from: media.videoResolution ?? "unknown")
        let codec = VideoCodec(from: media.videoCodec ?? "unknown")

        var hdrFormat: HDRFormat?
        if let colorTrc = videoStream?.colorTrc {
            if colorTrc.contains("dovi") || colorTrc.contains("dolby") {
                hdrFormat = .dolbyVision
            } else if colorTrc.contains("smpte2084") || colorTrc.contains("pq") {
                hdrFormat = .hdr10
            } else if colorTrc.contains("hlg") {
                hdrFormat = .hlg
            }
        }

        let addedDate: Date
        if let addedAt = metadata.addedAt {
            addedDate = Date(timeIntervalSince1970: TimeInterval(addedAt))
        } else {
            addedDate = Date()
        }

        return MediaItem(
            id: metadata.ratingKey,
            ratingKey: metadata.ratingKey,
            title: metadata.title,
            year: metadata.year,
            addedAt: addedDate,
            library: libraryTitle,
            container: media.container ?? part.container ?? "unknown",
            duration: (media.duration ?? 0) / 60000, // ms to minutes
            bitrate: Double(media.bitrate ?? 0) / 1000.0,
            fileSize: Double(part.size ?? 0) / 1_073_741_824.0,  // bytes to GB
            filePath: part.file ?? "",
            videoCodec: codec,
            videoResolution: resolution,
            frameRate: Double(media.videoFrameRate?.replacingOccurrences(of: "p", with: "") ?? "") ?? nil,
            hdrFormat: hdrFormat,
            colorSpace: videoStream?.colorSpace,
            audioCodec: audioStream?.codec ?? media.audioCodec ?? "unknown",
            audioChannels: audioStream?.channels.map { "\($0 == 8 ? "7.1" : $0 == 6 ? "5.1" : $0 == 2 ? "2.0" : "\($0).0")" } ?? "2.0",
            audioProfile: audioStream?.displayTitle,
            subtitles: subtitleStreams.compactMap { stream in
                guard let language = stream.language ?? stream.languageTag else { return nil }
                return SubtitleTrack(language: language, format: stream.codec ?? "SRT")
            }
        )
    }
}

// MARK: - API Response Models

struct IdentityResponse: Decodable {
    let mediaContainer: IdentityContainer
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
}
struct IdentityContainer: Decodable {
    let machineIdentifier: String
}

struct LibrarySectionsResponse: Decodable {
    let mediaContainer: LibrarySectionsContainer

    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct LibrarySectionsContainer: Decodable {
    let directory: [LibraryDirectoryResponse]

    enum CodingKeys: String, CodingKey {
        case directory = "Directory"
    }
}

struct LibraryDirectoryResponse: Decodable {
    let key: String
    let title: String
    let type: String
}

struct LibraryItemsResponse: Decodable {
    let mediaContainer: LibraryItemsContainer

    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct LibraryItemsContainer: Decodable {
    let metadata: [MetadataResponse]?
    let totalSize: Int?

    enum CodingKeys: String, CodingKey {
        case metadata = "Metadata"
        case totalSize
    }
}

struct MetadataResponse: Decodable {
    let ratingKey: String
    let title: String
    let year: Int?
    let addedAt: Int?
    let media: [MediaResponse]?

    enum CodingKeys: String, CodingKey {
        case ratingKey
        case title
        case year
        case addedAt
        case media = "Media"
    }
}

struct MediaResponse: Decodable {
    let id: Int?
    let duration: Int?
    let bitrate: Int?
    let container: String?
    let videoCodec: String?
    let videoResolution: String?
    let videoFrameRate: String?
    let audioCodec: String?
    let audioChannels: Int?
    let part: [PartResponse]?

    enum CodingKeys: String, CodingKey {
        case id
        case duration
        case bitrate
        case container
        case videoCodec
        case videoResolution
        case videoFrameRate
        case audioCodec
        case audioChannels
        case part = "Part"
    }
}

struct PartResponse: Decodable {
    let id: Int?
    let file: String?
    let size: Int64?
    let container: String?
    let stream: [StreamResponse]?

    enum CodingKeys: String, CodingKey {
        case id
        case file
        case size
        case container
        case stream = "Stream"
    }
}

struct StreamResponse: Decodable {
    let streamType: Int
    let codec: String?
    let language: String?
    let languageTag: String?
    let channels: Int?
    let displayTitle: String?
    let colorTrc: String?
    let colorSpace: String?
}

// MARK: - SSL Trust Delegate

/// Accepts self-signed certificates from local Plex servers.
class PlexTrustDelegate: NSObject, URLSessionDelegate {
    static let shared = PlexTrustDelegate()

    /// Pre-built URLSession that trusts Plex self-signed certs. Use for image loading.
    static let sharedSession = URLSession(
        configuration: .default,
        delegate: PlexTrustDelegate.shared,
        delegateQueue: nil
    )

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            return (.useCredential, URLCredential(trust: serverTrust))
        }
        return (.performDefaultHandling, nil)
    }
}

// MARK: - Errors

enum PlexAPIError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case serverUnreachable
    case decodingFailed(Error)
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .notAuthenticated: return "Not authenticated with Plex server"
        case .serverUnreachable: return "Cannot reach Plex server"
        case .decodingFailed(let error): return "Failed to parse server response: \(error.localizedDescription)"
        case .httpError(let code): return "Server returned error \(code)"
        }
    }
}
