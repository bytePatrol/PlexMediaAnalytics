import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: DashboardViewModel

    init(repository: PlexRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome Banner
                if viewModel.showWelcomeBanner && appState.currentServer == nil {
                    WelcomeBannerView(onDismiss: viewModel.dismissWelcome) {
                        appState.showServerSetup = true
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Quick Stats Row
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    StatCardView(
                        label: "Total Items",
                        value: Formatters.count(viewModel.totalItems),
                        icon: "film",
                        iconColor: PlexTheme.systemBlue
                    )
                    StatCardView(
                        label: "Total Storage",
                        value: Formatters.storageTB(viewModel.totalStorageGB),
                        icon: "internaldrive",
                        iconColor: PlexTheme.successGreen
                    )
                    StatCardView(
                        label: "4K Content",
                        value: "\(viewModel.percent4K)%",
                        icon: "4k.tv",
                        iconColor: PlexTheme.plexOrange
                    )
                    StatCardView(
                        label: "Recently Added",
                        value: "\(viewModel.recentlyAdded)",
                        icon: "calendar.badge.plus",
                        iconColor: PlexTheme.warningOrange
                    )
                }

                // Library Overview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Library Overview")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(PlexTheme.textPrimary)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        ForEach(viewModel.libraries, id: \.id) { library in
                            LibraryCardView(library: library) {
                                appState.selectedLibraryName = library.title
                                appState.selectedTab = .libraries
                            }
                        }
                    }
                }

                // Recent Activity Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity (Last 30 Days)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(PlexTheme.textPrimary)

                    RecentActivityChart(data: viewModel.recentActivity)
                        .frame(height: 200)
                        .padding(20)
                        .cardStyle()
                }
            }
            .padding(24)
        }
        .background(PlexTheme.bgLevel1)
    }
}

// MARK: - Recent Activity Chart

struct RecentActivityChart: View {
    let data: [MockDataProvider.TimelineEntry]

    var body: some View {
        Chart(data) { entry in
            BarMark(
                x: .value("Date", entry.date),
                y: .value("Count", entry.count)
            )
            .foregroundStyle(PlexTheme.systemBlue)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 12)) { value in
                AxisValueLabel()
                    .foregroundStyle(PlexTheme.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(Color.white.opacity(0.05))
                AxisValueLabel()
                    .foregroundStyle(PlexTheme.textSecondary)
            }
        }
    }
}

#Preview {
    DashboardView(repository: PlexRepository())
        .environmentObject(AppState())
        .frame(width: 1400, height: 900)
        .preferredColorScheme(.dark)
}
