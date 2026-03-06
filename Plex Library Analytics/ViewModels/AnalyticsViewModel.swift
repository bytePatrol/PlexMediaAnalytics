import Foundation
import Combine

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let title: String
    let year: Int?
    let items: [MediaItem]

    var totalWasted: Double {
        // Wasted space = all files minus the largest (keep best quality)
        let sorted = items.sorted { $0.fileSize > $1.fileSize }
        return sorted.dropFirst().reduce(0) { $0 + $1.fileSize }
    }
}

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var storageByLibrary: [(name: String, sizeGB: Double)] = []
    @Published var qualityDistribution: [(name: String, value: Int)] = []
    @Published var contentOverTime: [MockDataProvider.MonthlyEntry] = []
    @Published var audioFormats: [MockDataProvider.AudioFormatEntry] = []
    @Published var fileSizeDistribution: [MockDataProvider.FileSizeBucket] = []

    // Summary stats
    @Published var averageFileSize: Double = 0
    @Published var averageBitrate: Double = 0
    @Published var hdrPercentage: Int = 0
    @Published var hdrCount: Int = 0

    // Month-over-month trends (positive = grew)
    @Published var fileSizeTrend: Double = 0      // percentage change
    @Published var bitrateTrend: Double = 0
    @Published var hdrTrend: Double = 0

    // Duplicate candidates
    @Published var duplicateCandidates: [DuplicateGroup] = []
    @Published var totalDuplicateWastedGB: Double = 0

    private let repository: PlexRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: PlexRepositoryProtocol) {
        self.repository = repository

        repository.libraries
            .combineLatest(repository.allItems)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] libs, items in
                self?.computeAnalytics(libraries: libs, items: items)
            }
            .store(in: &cancellables)

        // Load mock data
        if repository.libraries.value.isEmpty {
            loadMockData()
        }
    }

    func loadMockData() {
        let libs = MockDataProvider.libraries
        storageByLibrary = libs.map { ($0.title, $0.totalSizeGB) }

        let totalDist = libs.reduce(QualityDistribution(ultra4K: 0, fullHD1080p: 0, hd720p: 0, sd: 0)) { acc, lib in
            QualityDistribution(
                ultra4K: acc.ultra4K + lib.qualityDistribution.ultra4K,
                fullHD1080p: acc.fullHD1080p + lib.qualityDistribution.fullHD1080p,
                hd720p: acc.hd720p + lib.qualityDistribution.hd720p,
                sd: acc.sd + lib.qualityDistribution.sd
            )
        }
        qualityDistribution = totalDist.segments.map { ($0.label, $0.value) }

        contentOverTime = MockDataProvider.contentOverTime
        audioFormats = MockDataProvider.audioFormats
        fileSizeDistribution = MockDataProvider.fileSizeDistribution

        averageFileSize = 8.4
        averageBitrate = 14.2
        hdrPercentage = 12
        hdrCount = 482

        // Compute duplicates from mock items
        computeDuplicates(items: MockDataProvider.mediaItems)
    }

    private func computeAnalytics(libraries: [PlexLibrary], items: [MediaItem]) {
        guard !libraries.isEmpty else { return }

        storageByLibrary = libraries.map { ($0.title, $0.totalSizeGB) }

        let totalDist = libraries.reduce(QualityDistribution(ultra4K: 0, fullHD1080p: 0, hd720p: 0, sd: 0)) { acc, lib in
            QualityDistribution(
                ultra4K: acc.ultra4K + lib.qualityDistribution.ultra4K,
                fullHD1080p: acc.fullHD1080p + lib.qualityDistribution.fullHD1080p,
                hd720p: acc.hd720p + lib.qualityDistribution.hd720p,
                sd: acc.sd + lib.qualityDistribution.sd
            )
        }
        qualityDistribution = totalDist.segments.map { ($0.label, $0.value) }

        if !items.isEmpty {
            averageFileSize = items.reduce(0) { $0 + $1.fileSize } / Double(items.count)
            let highResItems = items.filter { $0.videoResolution == .uhd4K || $0.videoResolution == .fullHD }
            averageBitrate = highResItems.isEmpty ? 0 : highResItems.reduce(0) { $0 + $1.bitrate } / Double(highResItems.count)

            let hdrItems = items.filter { $0.hdrFormat != nil }
            hdrCount = hdrItems.count
            hdrPercentage = Int(Double(hdrCount) / Double(items.count) * 100)

            // Month-over-month trends
            computeTrends(items: items)

            // Content added over time — group by month
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            var monthCounts: [String: Int] = [:]
            var monthOrder: [String: Date] = [:]
            for item in items {
                let components = Calendar.current.dateComponents([.year, .month], from: item.addedAt)
                let key = dateFormatter.string(from: item.addedAt)
                let orderKey = "\(components.year ?? 0)-\(components.month ?? 0)"
                monthCounts[orderKey, default: 0] += 1
                if monthOrder[orderKey] == nil {
                    monthOrder[orderKey] = item.addedAt
                }
            }
            contentOverTime = monthOrder
                .sorted { $0.value < $1.value }
                .map { key, date in
                    MockDataProvider.MonthlyEntry(
                        month: dateFormatter.string(from: date),
                        items: monthCounts[key] ?? 0
                    )
                }

            // Audio format breakdown
            var audioCounts: [String: Int] = [:]
            for item in items {
                let format = item.audioProfile ?? item.audioCodec
                audioCounts[format, default: 0] += 1
            }
            audioFormats = audioCounts
                .sorted { $0.value > $1.value }
                .map { MockDataProvider.AudioFormatEntry(name: $0.key, value: $0.value) }

            // File size distribution
            var buckets = [0, 0, 0, 0, 0]
            for item in items {
                switch item.fileSize {
                case ..<2: buckets[0] += 1
                case 2..<5: buckets[1] += 1
                case 5..<10: buckets[2] += 1
                case 10..<20: buckets[3] += 1
                default: buckets[4] += 1
                }
            }
            let ranges = ["0-2 GB", "2-5 GB", "5-10 GB", "10-20 GB", "20+ GB"]
            fileSizeDistribution = zip(ranges, buckets)
                .map { MockDataProvider.FileSizeBucket(range: $0, count: $1) }

            // Duplicate detection
            computeDuplicates(items: items)
        }
    }

    // MARK: - Trend Computation

    private func computeTrends(items: [MediaItem]) {
        let cal = Calendar.current
        let now = Date()
        guard let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)),
              let lastMonthStart = cal.date(byAdding: .month, value: -1, to: thisMonthStart) else { return }

        let thisMonth = items.filter { $0.addedAt >= thisMonthStart }
        let lastMonth = items.filter { $0.addedAt >= lastMonthStart && $0.addedAt < thisMonthStart }

        fileSizeTrend = trendPercent(
            current: thisMonth.isEmpty ? 0 : thisMonth.reduce(0) { $0 + $1.fileSize } / Double(thisMonth.count),
            previous: lastMonth.isEmpty ? 0 : lastMonth.reduce(0) { $0 + $1.fileSize } / Double(lastMonth.count)
        )

        let thisHighRes = thisMonth.filter { $0.videoResolution == .uhd4K || $0.videoResolution == .fullHD }
        let lastHighRes = lastMonth.filter { $0.videoResolution == .uhd4K || $0.videoResolution == .fullHD }
        bitrateTrend = trendPercent(
            current: thisHighRes.isEmpty ? 0 : thisHighRes.reduce(0) { $0 + $1.bitrate } / Double(thisHighRes.count),
            previous: lastHighRes.isEmpty ? 0 : lastHighRes.reduce(0) { $0 + $1.bitrate } / Double(lastHighRes.count)
        )

        let thisHDRPct = thisMonth.isEmpty ? 0.0 : Double(thisMonth.filter { $0.hdrFormat != nil }.count) / Double(thisMonth.count) * 100
        let lastHDRPct = lastMonth.isEmpty ? 0.0 : Double(lastMonth.filter { $0.hdrFormat != nil }.count) / Double(lastMonth.count) * 100
        hdrTrend = trendPercent(current: thisHDRPct, previous: lastHDRPct)
    }

    private func trendPercent(current: Double, previous: Double) -> Double {
        guard previous > 0 else { return 0 }
        return (current - previous) / previous * 100
    }

    // MARK: - Duplicate Detection

    private func computeDuplicates(items: [MediaItem]) {
        var groups: [String: [MediaItem]] = [:]
        for item in items {
            let yearStr = item.year.map { " (\($0))" } ?? ""
            let key = "\(item.title.lowercased().trimmingCharacters(in: .whitespaces))\(yearStr)"
            groups[key, default: []].append(item)
        }

        let dupes = groups
            .filter { $0.value.count > 1 }
            .map { _, items -> DuplicateGroup in
                let first = items[0]
                return DuplicateGroup(title: first.title, year: first.year, items: items)
            }
            .sorted { $0.totalWasted > $1.totalWasted }

        duplicateCandidates = dupes
        totalDuplicateWastedGB = dupes.reduce(0) { $0 + $1.totalWasted }
    }

    // MARK: - Trend label helpers

    func trendLabel(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", value))%"
    }
}
