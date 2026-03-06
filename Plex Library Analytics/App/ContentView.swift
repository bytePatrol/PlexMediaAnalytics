import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            TopNavigationBar()

            Group {
                switch appState.selectedTab {
                case .dashboard:
                    DashboardView(repository: appState.repository)
                case .libraries:
                    LibraryBrowserView(repository: appState.repository)
                case .analytics:
                    AnalyticsView(repository: appState.repository)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(PlexTheme.bgLevel1)
        .sheet(isPresented: $appState.showServerSetup) {
            ServerSetupView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Top Navigation Bar (matches Figma design)

struct TopNavigationBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            // Left: App title
            HStack(spacing: 8) {
                Image(systemName: "film")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PlexTheme.plexOrange)

                Text("Plex Library Analytics")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(PlexTheme.textPrimary)
            }

            Spacer()

            // Center: Tab switcher
            HStack(spacing: 2) {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                appState.selectedTab == tab
                                    ? PlexTheme.systemBlue
                                    : Color.clear
                            )
                            .foregroundStyle(
                                appState.selectedTab == tab
                                    ? .white
                                    : PlexTheme.textSecondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(PlexTheme.bgLevel3)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            // Right: Controls
            HStack(spacing: 12) {
                // Connection status
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(statusText)
                        .font(.system(size: 12))
                        .foregroundStyle(PlexTheme.textSecondary)
                }

                Divider()
                    .frame(height: 20)

                // Refresh
                Button {
                    appState.refreshData()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundStyle(PlexTheme.textSecondary)
                        .rotationEffect(.degrees(appState.isLoading ? 360 : 0))
                        .animation(
                            appState.isLoading
                                ? .linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: appState.isLoading
                        )
                }
                .buttonStyle(.plain)
                .help("Refresh Libraries (⌘R)")

                // Settings
                Button {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundStyle(PlexTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .background(PlexTheme.bgLevel2)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PlexTheme.border)
                .frame(height: 1)
        }
    }

    private var statusColor: Color {
        switch appState.connectionStatus {
        case .connected: return PlexTheme.successGreen
        case .connecting: return PlexTheme.warningOrange
        case .disconnected: return PlexTheme.textSecondary
        case .error: return PlexTheme.errorRed
        }
    }

    private var statusText: String {
        switch appState.connectionStatus {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Demo Mode"
        case .error: return "Connection Error"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 1400, height: 900)
}
