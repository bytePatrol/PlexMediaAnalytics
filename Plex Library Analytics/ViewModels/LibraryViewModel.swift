import Foundation
import Combine
import AppKit

@MainActor
final class LibraryViewModel: ObservableObject {
    // Data
    @Published var items: [MediaItem] = []
    @Published var filteredItems: [MediaItem] = []
    @Published var availableLibraries: [String] = []

    // Search & Filters
    @Published var searchText = ""
    @Published var selectedResolutions: Set<VideoResolution> = []
    @Published var selectedCodecs: Set<VideoCodec> = []
    @Published var fileSizeRange: ClosedRange<Double> = 0...30
    @Published var dateFilter: DateFilter = .all
    @Published var selectedLibrary: String? = nil

    // Sorting
    @Published var sortColumn: SortColumn = .dateAdded
    @Published var sortAscending = false

    // Pagination — reads from settings, falls back to 20
    @Published var currentPage = 1
    var itemsPerPage: Int {
        let stored = UserDefaults.standard.integer(forKey: "itemsPerPage")
        return stored > 0 ? stored : 20
    }

    // Detail
    @Published var selectedItem: MediaItem?
    @Published var showDetail = false

    private let repository: PlexRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    var totalPages: Int {
        max(1, Int(ceil(Double(filteredItems.count) / Double(itemsPerPage))))
    }

    var paginatedItems: [MediaItem] {
        let start = (currentPage - 1) * itemsPerPage
        let end = min(start + itemsPerPage, filteredItems.count)
        guard start < filteredItems.count else { return [] }
        return Array(filteredItems[start..<end])
    }

    var activeFilterCount: Int {
        var count = 0
        if selectedLibrary != nil { count += 1 }
        if !selectedResolutions.isEmpty { count += 1 }
        if !selectedCodecs.isEmpty { count += 1 }
        if fileSizeRange != 0...30 { count += 1 }
        if dateFilter != .all { count += 1 }
        return count
    }

    init(repository: PlexRepositoryProtocol) {
        self.repository = repository

        repository.libraries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] libs in
                self?.availableLibraries = libs.map(\.title)
            }
            .store(in: &cancellables)

        repository.allItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
                self?.applyFilters()
            }
            .store(in: &cancellables)

        // React to filter changes
        $searchText.combineLatest($selectedResolutions, $selectedCodecs)
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.currentPage = 1
                self?.applyFilters()
            }
            .store(in: &cancellables)

        $dateFilter.combineLatest($fileSizeRange, $selectedLibrary)
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.currentPage = 1
                self?.applyFilters()
            }
            .store(in: &cancellables)

        $sortColumn.combineLatest($sortAscending)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)

        // Load mock data for demo
        if repository.allItems.value.isEmpty {
            items = MockDataProvider.mediaItems
            availableLibraries = Array(Set(MockDataProvider.mediaItems.map(\.library))).sorted()
            applyFilters()
        }
    }

    func clearFilters() {
        searchText = ""
        selectedResolutions = []
        selectedCodecs = []
        fileSizeRange = 0...30
        dateFilter = .all
        selectedLibrary = nil
    }

    func selectItem(_ item: MediaItem) {
        selectedItem = item
        showDetail = true
    }

    func goToPage(_ page: Int) {
        currentPage = max(1, min(page, totalPages))
    }

    func resolutionCount(_ resolution: VideoResolution) -> Int {
        items.filter { $0.videoResolution == resolution }.count
    }

    func codecCount(_ codec: VideoCodec) -> Int {
        items.filter { $0.videoCodec == codec }.count
    }

    // MARK: - CSV Export

    func exportCSV() {
        let panel = NSSavePanel()
        panel.title = "Export Library"
        panel.nameFieldStringValue = "plex_library.csv"
        panel.allowedContentTypes = [.commaSeparatedText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        var lines = ["Title,Year,Library,Resolution,Codec,HDR,Audio,Channels,Container,File Size (GB),Bitrate (Mbps),Duration (min),Date Added,File Path"]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        for item in filteredItems {
            let fields: [String] = [
                csvEscape(item.title),
                item.year.map(String.init) ?? "",
                csvEscape(item.library),
                item.videoResolution.rawValue,
                item.videoCodec.rawValue,
                item.hdrFormat?.rawValue ?? "",
                csvEscape(item.audioProfile ?? item.audioCodec),
                item.audioChannels,
                item.container.uppercased(),
                String(format: "%.2f", item.fileSize),
                String(format: "%.1f", item.bitrate),
                String(item.duration),
                dateFormatter.string(from: item.addedAt),
                csvEscape(item.filePath),
            ]
            lines.append(fields.joined(separator: ","))
        }

        let csv = lines.joined(separator: "\n")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Private

    private func csvEscape(_ string: String) -> String {
        let needsQuoting = string.contains(",") || string.contains("\"") || string.contains("\n")
        if needsQuoting {
            return "\"" + string.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return string
    }

    private func applyFilters() {
        var result = items

        // Search: title, year, codec, resolution, audio
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query)
                || ($0.year.map { String($0) } ?? "").contains(query)
                || $0.videoCodec.rawValue.lowercased().contains(query)
                || $0.videoResolution.rawValue.lowercased().contains(query)
                || $0.audioCodec.lowercased().contains(query)
            }
        }

        // Resolution
        if !selectedResolutions.isEmpty {
            result = result.filter { selectedResolutions.contains($0.videoResolution) }
        }

        // Codec
        if !selectedCodecs.isEmpty {
            result = result.filter { selectedCodecs.contains($0.videoCodec) }
        }

        // File size
        if fileSizeRange != 0...30 {
            result = result.filter {
                $0.fileSize >= fileSizeRange.lowerBound && $0.fileSize <= fileSizeRange.upperBound
            }
        }

        // Date
        if let cutoff = dateFilter.cutoffDate {
            result = result.filter { $0.addedAt >= cutoff }
        }

        // Library
        if let lib = selectedLibrary {
            result = result.filter { $0.library == lib }
        }

        // Sort
        result.sort { a, b in
            let comparison: Bool
            switch sortColumn {
            case .title:
                comparison = a.title.localizedCompare(b.title) == .orderedAscending
            case .dateAdded:
                comparison = a.addedAt < b.addedAt
            case .fileSize:
                comparison = a.fileSize < b.fileSize
            case .resolution:
                comparison = a.videoResolution.sortOrder < b.videoResolution.sortOrder
            case .bitrate:
                comparison = a.bitrate < b.bitrate
            }
            return sortAscending ? comparison : !comparison
        }

        filteredItems = result
    }
}

enum SortColumn: String, CaseIterable {
    case title = "Title"
    case dateAdded = "Date Added"
    case fileSize = "File Size"
    case resolution = "Resolution"
    case bitrate = "Bitrate"
}

enum DateFilter: String, CaseIterable {
    case all = "All Time"
    case week = "Last 7 Days"
    case month = "Last 30 Days"
    case year = "Last Year"

    var cutoffDate: Date? {
        let cal = Calendar.current
        switch self {
        case .all: return nil
        case .week: return cal.date(byAdding: .day, value: -7, to: Date())
        case .month: return cal.date(byAdding: .day, value: -30, to: Date())
        case .year: return cal.date(byAdding: .year, value: -1, to: Date())
        }
    }
}
