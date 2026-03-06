import Foundation
import Combine

protocol PlexRepositoryProtocol {
    var connectionStatus: CurrentValueSubject<ServerConnectionStatus, Never> { get }
    var libraries: CurrentValueSubject<[PlexLibrary], Never> { get }
    var allItems: CurrentValueSubject<[MediaItem], Never> { get }
    var isLoading: CurrentValueSubject<Bool, Never> { get }
    var lastRefresh: CurrentValueSubject<Date?, Never> { get }
    var machineIdentifier: CurrentValueSubject<String?, Never> { get }

    func connect(to server: PlexServer) async throws
    func refreshLibraries() async throws
    func fetchItemsForLibrary(_ libraryKey: String) async throws -> [MediaItem]
    func refreshAll() async throws
}

final class PlexRepository: PlexRepositoryProtocol {
    let connectionStatus = CurrentValueSubject<ServerConnectionStatus, Never>(.disconnected)
    let libraries = CurrentValueSubject<[PlexLibrary], Never>([])
    let allItems = CurrentValueSubject<[MediaItem], Never>([])
    let isLoading = CurrentValueSubject<Bool, Never>(false)
    let lastRefresh = CurrentValueSubject<Date?, Never>(nil)
    let machineIdentifier = CurrentValueSubject<String?, Never>(nil)

    private let apiClient: PlexAPIClientProtocol
    private var currentServer: PlexServer?
    private var itemsByLibrary: [String: [MediaItem]] = [:]

    init(apiClient: PlexAPIClientProtocol = PlexAPIClient()) {
        self.apiClient = apiClient
    }

    func connect(to server: PlexServer) async throws {
        connectionStatus.send(.connecting)

        do {
            let success = try await apiClient.testConnection(server: server)
            if success {
                currentServer = server
                connectionStatus.send(.connected)
                if let id = try? await apiClient.fetchMachineIdentifier(server: server) {
                    machineIdentifier.send(id)
                }
                // Don't call refreshLibraries() here — it would push libraries with 0 stats,
                // causing Analytics to show zeros. AppState calls refreshAll() after connect()
                // which populates fully-computed stats before sending to the subject.
            } else {
                connectionStatus.send(.error("Connection test failed"))
            }
        } catch {
            connectionStatus.send(.error(error.localizedDescription))
            throw error
        }
    }

    func refreshLibraries() async throws {
        guard let server = currentServer else {
            throw PlexAPIError.notAuthenticated
        }

        isLoading.send(true)
        defer { isLoading.send(false) }

        let libs = try await apiClient.fetchLibraries(server: server)
        libraries.send(libs)
    }

    func fetchItemsForLibrary(_ libraryKey: String) async throws -> [MediaItem] {
        guard let server = currentServer else {
            throw PlexAPIError.notAuthenticated
        }

        let lib = libraries.value.first(where: { $0.id == libraryKey })
        let libType = lib?.type ?? .movie
        let libTitle = lib?.title ?? libraryKey
        let items = try await apiClient.fetchLibraryItems(server: server, libraryKey: libraryKey, libraryTitle: libTitle, libraryType: libType)
        itemsByLibrary[libraryKey] = items

        // Update all items
        let all = itemsByLibrary.values.flatMap { $0 }
        allItems.send(Array(all))

        // Update library stats
        updateLibraryStats(libraryKey: libraryKey, items: items)

        return items
    }

    func refreshAll() async throws {
        guard let server = currentServer else {
            throw PlexAPIError.notAuthenticated
        }

        isLoading.send(true)
        defer {
            isLoading.send(false)
            lastRefresh.send(Date())
        }

        let libs = try await apiClient.fetchLibraries(server: server)

        var updatedLibraries: [PlexLibrary] = []
        for lib in libs {
            let items = try await apiClient.fetchLibraryItems(server: server, libraryKey: lib.id, libraryTitle: lib.title, libraryType: lib.type)
            itemsByLibrary[lib.id] = items

            var updatedLib = lib
            updatedLib.itemCount = items.count
            updatedLib.totalSizeGB = items.reduce(0) { $0 + $1.fileSize }
            updatedLib.qualityDistribution = computeQualityDistribution(items: items)
            updatedLib.lastAdded = items.sorted(by: { $0.addedAt > $1.addedAt }).first

            updatedLibraries.append(updatedLib)
        }

        libraries.send(updatedLibraries)
        allItems.send(itemsByLibrary.values.flatMap { $0 })
    }

    // MARK: - Private

    private func updateLibraryStats(libraryKey: String, items: [MediaItem]) {
        var libs = libraries.value
        guard let index = libs.firstIndex(where: { $0.id == libraryKey }) else { return }

        libs[index].itemCount = items.count
        libs[index].totalSizeGB = items.reduce(0) { $0 + $1.fileSize }
        libs[index].qualityDistribution = computeQualityDistribution(items: items)
        libs[index].lastAdded = items.sorted(by: { $0.addedAt > $1.addedAt }).first

        libraries.send(libs)
    }

    private func computeQualityDistribution(items: [MediaItem]) -> QualityDistribution {
        var dist = QualityDistribution(ultra4K: 0, fullHD1080p: 0, hd720p: 0, sd: 0)
        for item in items {
            switch item.videoResolution {
            case .uhd4K: dist.ultra4K += 1
            case .fullHD: dist.fullHD1080p += 1
            case .hd: dist.hd720p += 1
            case .sd, .unknown: dist.sd += 1
            }
        }
        return dist
    }
}
