import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: AnalyticsViewModel
    @State private var showDuplicates = false

    init(repository: PlexRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Row: Storage + Quality
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    // Storage by Library
                    ChartCardView(title: "Storage by Library") {
                        Chart(viewModel.storageByLibrary, id: \.name) { entry in
                            BarMark(
                                x: .value("Size", entry.sizeGB / 1000),
                                y: .value("Library", entry.name)
                            )
                            .foregroundStyle(PlexTheme.systemBlue)
                            .cornerRadius(4)
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(String(format: "%.1f TB", v))
                                            .foregroundStyle(PlexTheme.textSecondary)
                                    }
                                }
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                    .foregroundStyle(Color.white.opacity(0.05))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .foregroundStyle(PlexTheme.textSecondary)
                            }
                        }
                        .frame(height: 220)
                    }

                    // Quality Distribution
                    ChartCardView(title: "Quality Distribution") {
                        HStack(spacing: 20) {
                            // Pie chart
                            Chart(viewModel.qualityDistribution, id: \.name) { entry in
                                SectorMark(
                                    angle: .value("Count", entry.value),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(qualityChartColor(for: entry.name))
                                .cornerRadius(3)
                            }
                            .frame(width: 160, height: 160)

                            // Legend
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(viewModel.qualityDistribution, id: \.name) { entry in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(qualityChartColor(for: entry.name))
                                            .frame(width: 8, height: 8)

                                        Text(entry.name)
                                            .font(.system(size: 12))
                                            .foregroundStyle(PlexTheme.textPrimary)

                                        Spacer()

                                        Text("\(entry.value)")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundStyle(PlexTheme.textSecondary)

                                        Text(percentageString(entry.value))
                                            .font(.system(size: 11))
                                            .foregroundStyle(PlexTheme.textSecondary)
                                            .frame(width: 40, alignment: .trailing)
                                    }
                                }
                            }
                        }
                        .frame(height: 220)
                    }
                }

                // Middle Row: Content Over Time + Audio
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    // Content Added Over Time
                    ChartCardView(title: "Content Added Over Time") {
                        Chart(viewModel.contentOverTime) { entry in
                            LineMark(
                                x: .value("Month", entry.month),
                                y: .value("Items", entry.items)
                            )
                            .foregroundStyle(PlexTheme.systemBlue)
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            PointMark(
                                x: .value("Month", entry.month),
                                y: .value("Items", entry.items)
                            )
                            .foregroundStyle(PlexTheme.systemBlue)
                            .symbolSize(30)

                            AreaMark(
                                x: .value("Month", entry.month),
                                y: .value("Items", entry.items)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [PlexTheme.systemBlue.opacity(0.2), PlexTheme.systemBlue.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .foregroundStyle(PlexTheme.textSecondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                    .foregroundStyle(Color.white.opacity(0.05))
                                AxisValueLabel()
                                    .foregroundStyle(PlexTheme.textSecondary)
                            }
                        }
                        .frame(height: 220)
                    }

                    // Audio Format Breakdown
                    ChartCardView(title: "Audio Format Breakdown") {
                        HStack(spacing: 20) {
                            Chart(viewModel.audioFormats) { entry in
                                SectorMark(
                                    angle: .value("Count", entry.value),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(audioChartColor(for: entry.name))
                                .cornerRadius(3)
                            }
                            .frame(width: 160, height: 160)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.audioFormats) { entry in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(audioChartColor(for: entry.name))
                                            .frame(width: 8, height: 8)

                                        Text(entry.name)
                                            .font(.system(size: 12))
                                            .foregroundStyle(PlexTheme.textPrimary)

                                        Spacer()

                                        Text("\(entry.value)")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundStyle(PlexTheme.textSecondary)
                                    }
                                }
                            }
                        }
                        .frame(height: 220)
                    }
                }

                // Full Width: File Size Distribution
                ChartCardView(title: "File Size Distribution") {
                    Chart(viewModel.fileSizeDistribution) { bucket in
                        BarMark(
                            x: .value("Range", bucket.range),
                            y: .value("Count", bucket.count)
                        )
                        .foregroundStyle(PlexTheme.plexOrange)
                        .cornerRadius(4)
                        .annotation(position: .top, alignment: .center) {
                            Text("\(bucket.count)")
                                .font(.system(size: 11))
                                .foregroundStyle(PlexTheme.textPrimary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(PlexTheme.textSecondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(Color.white.opacity(0.05))
                            AxisValueLabel()
                                .foregroundStyle(PlexTheme.textSecondary)
                        }
                    }
                    .frame(height: 200)
                }

                // Summary Stats Row (real trend values)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                    AnalyticsStatBox(
                        title: "Average File Size",
                        value: String(format: "%.1f GB", viewModel.averageFileSize),
                        subtitle: "Across all libraries",
                        trend: viewModel.trendLabel(viewModel.fileSizeTrend),
                        isPositive: viewModel.fileSizeTrend >= 0
                    )
                    AnalyticsStatBox(
                        title: "Bitrate Average",
                        value: String(format: "%.1f Mbps", viewModel.averageBitrate),
                        subtitle: "For 1080p and above",
                        trend: viewModel.trendLabel(viewModel.bitrateTrend),
                        isPositive: viewModel.bitrateTrend >= 0
                    )
                    AnalyticsStatBox(
                        title: "HDR Content",
                        value: "\(viewModel.hdrPercentage)%",
                        subtitle: "\(viewModel.hdrCount) items",
                        trend: viewModel.trendLabel(viewModel.hdrTrend),
                        isPositive: viewModel.hdrTrend >= 0
                    )
                }

                // Duplicate Candidates
                if !viewModel.duplicateCandidates.isEmpty {
                    DuplicateCandidatesCard(
                        groups: viewModel.duplicateCandidates,
                        totalWastedGB: viewModel.totalDuplicateWastedGB,
                        isExpanded: $showDuplicates
                    )
                }
            }
            .padding(24)
        }
        .background(PlexTheme.bgLevel1)
    }

    // MARK: - Helpers

    private func qualityChartColor(for name: String) -> Color {
        PlexTheme.qualityColor(for: name)
    }

    private func audioChartColor(for name: String) -> Color {
        switch name {
        case "Dolby Atmos": return PlexTheme.plexOrange
        case "DTS-HD MA": return PlexTheme.systemBlue
        case "TrueHD": return PlexTheme.successGreen
        case "AC3": return PlexTheme.warningOrange
        case "AAC": return PlexTheme.errorRed
        default: return PlexTheme.textSecondary
        }
    }

    private func percentageString(_ value: Int) -> String {
        let total = viewModel.qualityDistribution.reduce(0) { $0 + $1.value }
        guard total > 0 else { return "0%" }
        return String(format: "%.0f%%", Double(value) / Double(total) * 100)
    }
}

// MARK: - Duplicate Candidates Card

struct DuplicateCandidatesCard: View {
    let groups: [DuplicateGroup]
    let totalWastedGB: Double
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundStyle(PlexTheme.warningOrange)

                    Text("Duplicate Candidates")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PlexTheme.textPrimary)

                    Spacer()

                    HStack(spacing: 12) {
                        Text("\(groups.count) groups")
                            .font(.system(size: 12))
                            .foregroundStyle(PlexTheme.textSecondary)

                        Text(String(format: "%.1f GB potentially wasted", totalWastedGB))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(PlexTheme.warningOrange)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11))
                            .foregroundStyle(PlexTheme.textSecondary)
                    }
                }
                .padding(20)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .overlay(PlexTheme.border)

                VStack(spacing: 0) {
                    ForEach(groups.prefix(10)) { group in
                        DuplicateGroupRow(group: group)

                        if group.id != groups.prefix(10).last?.id {
                            Divider()
                                .overlay(PlexTheme.border.opacity(0.5))
                                .padding(.horizontal, 20)
                        }
                    }

                    if groups.count > 10 {
                        Text("and \(groups.count - 10) more...")
                            .font(.system(size: 12))
                            .foregroundStyle(PlexTheme.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct DuplicateGroupRow: View {
    let group: DuplicateGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(group.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(PlexTheme.textPrimary)
                        if let year = group.year {
                            Text("(\(year))")
                                .font(.system(size: 12))
                                .foregroundStyle(PlexTheme.textSecondary)
                        }
                    }
                    Text("\(group.items.count) copies")
                        .font(.system(size: 11))
                        .foregroundStyle(PlexTheme.textSecondary)
                }

                Spacer()

                Text(String(format: "%.1f GB wasted", group.totalWasted))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PlexTheme.warningOrange)
            }

            // Show each file
            ForEach(group.items, id: \.id) { item in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(PlexTheme.textSecondary.opacity(0.3))
                        .frame(width: 3, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(item.videoResolution.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(PlexTheme.systemBlue.opacity(0.15))
                                .foregroundStyle(PlexTheme.systemBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 3))

                            Text(item.videoCodec.rawValue)
                                .font(.system(size: 11))
                                .foregroundStyle(PlexTheme.textSecondary)

                            if let hdr = item.hdrFormat {
                                Text(hdr.rawValue)
                                    .font(.system(size: 11))
                                    .foregroundStyle(PlexTheme.plexOrange)
                            }
                        }

                        Text(item.filePath)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(PlexTheme.textSecondary.opacity(0.7))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    Text(String(format: "%.1f GB", item.fileSize))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(PlexTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Chart Card

struct ChartCardView<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PlexTheme.textPrimary)

            content
        }
        .padding(20)
        .cardStyle()
    }
}

// MARK: - Analytics Stat Box

struct AnalyticsStatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let trend: String
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(PlexTheme.textSecondary)

            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(PlexTheme.textPrimary)

            HStack {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(PlexTheme.textSecondary)

                Spacer()

                Text(trend)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isPositive ? PlexTheme.successGreen : PlexTheme.errorRed)
            }
        }
        .padding(20)
        .cardStyle()
    }
}

#Preview {
    AnalyticsView(repository: PlexRepository())
        .environmentObject(AppState())
        .frame(width: 1400, height: 900)
        .preferredColorScheme(.dark)
}
