import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeTab: SettingsTab = .general

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 2) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button {
                        activeTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                activeTab == tab
                                    ? PlexTheme.systemBlue
                                    : Color.clear
                            )
                            .foregroundStyle(
                                activeTab == tab
                                    ? .white
                                    : PlexTheme.textSecondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(8)
            .frame(width: 160)
            .background(PlexTheme.bgLevel2)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(PlexTheme.border, lineWidth: 1)
            )

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch activeTab {
                    case .general: GeneralSettingsSection()
                    case .servers: ServerSettingsSection()
                    case .display: DisplaySettingsSection()
                    case .performance: PerformanceSettingsSection(onIntervalChange: appState.startAutoRefreshTimer)
                    case .about: AboutSettingsSection()
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PlexTheme.bgLevel2)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(PlexTheme.border, lineWidth: 1)
            )
        }
        .padding(20)
        .frame(width: 700, height: 500)
        .background(PlexTheme.bgLevel1)
        .preferredColorScheme(.dark)
    }
}

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case servers = "Servers"
    case display = "Display"
    case performance = "Performance"
    case about = "About"
}

// MARK: - General

struct GeneralSettingsSection: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    @AppStorage("defaultView") private var defaultView = "dashboard"
    @AppStorage("showFilePaths") private var showFilePaths = false
    @AppStorage("dateFormat") private var dateFormat = "relative"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("General Settings")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PlexTheme.textPrimary)
                .padding(.bottom, 20)

            SettingRow(label: "Launch at login", description: "Automatically start the app when you log in") {
                Toggle("", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .tint(PlexTheme.systemBlue)
            }

            SettingRow(label: "Default view", description: "Choose which view to show on startup") {
                Picker("", selection: $defaultView) {
                    Text("Dashboard").tag("dashboard")
                    Text("Libraries").tag("libraries")
                    Text("Analytics").tag("analytics")
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            }

            SettingRow(label: "Show file paths", description: "Display full file paths in the library browser") {
                Toggle("", isOn: $showFilePaths)
                    .toggleStyle(.switch)
                    .tint(PlexTheme.systemBlue)
            }

            SettingRow(label: "Date format", description: "Choose how dates are displayed") {
                Picker("", selection: $dateFormat) {
                    Text("Relative (2 days ago)").tag("relative")
                    Text("Absolute (Feb 23, 2025)").tag("absolute")
                }
                .pickerStyle(.menu)
                .frame(width: 220)
            }
        }
    }
}

// MARK: - Servers

struct ServerSettingsSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Server Connections")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PlexTheme.textPrimary)
                .padding(.bottom, 20)

            if appState.savedServers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 28))
                        .foregroundStyle(PlexTheme.textSecondary.opacity(0.4))
                    Text("No saved servers")
                        .font(.system(size: 13))
                        .foregroundStyle(PlexTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    ForEach(appState.savedServers) { server in
                        LiveServerRow(
                            server: server,
                            isCurrent: appState.currentServer?.id == server.id,
                            connectionStatus: appState.connectionStatus
                        ) {
                            appState.connectToServer(server)
                        } onRemove: {
                            appState.removeServer(server)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Button("Add Server") {
                    appState.showServerSetup = true
                }
                .buttonStyle(.borderedProminent)
                .tint(PlexTheme.systemBlue)
                .padding(.top, 16)

                if appState.currentServer != nil {
                    Button("Disconnect") {
                        appState.disconnectFromServer()
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 16)
                    .foregroundStyle(PlexTheme.errorRed)
                }
            }
        }
    }
}

struct LiveServerRow: View {
    let server: PlexServer
    let isCurrent: Bool
    let connectionStatus: ServerConnectionStatus
    let onConnect: () -> Void
    let onRemove: () -> Void

    var isOnline: Bool { isCurrent && connectionStatus.isConnected }

    var body: some View {
        HStack {
            Circle()
                .fill(isOnline ? PlexTheme.successGreen : PlexTheme.textSecondary.opacity(0.3))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(server.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PlexTheme.textPrimary)
                    if isCurrent {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(PlexTheme.systemBlue.opacity(0.2))
                            .foregroundStyle(PlexTheme.systemBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                Text(server.displayAddress)
                    .font(.system(size: 12))
                    .foregroundStyle(PlexTheme.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                if !isCurrent {
                    Button("Connect") { onConnect() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }

                Button("Remove") { onRemove() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundStyle(PlexTheme.errorRed)
            }
        }
        .padding(12)
        .background(isCurrent ? PlexTheme.systemBlue.opacity(0.06) : PlexTheme.bgLevel3.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? PlexTheme.systemBlue.opacity(0.3) : PlexTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Display

struct DisplaySettingsSection: View {
    @AppStorage("compactMode") private var compactMode = false
    @AppStorage("showThumbnails") private var showThumbnails = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Display Settings")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PlexTheme.textPrimary)
                .padding(.bottom, 20)

            SettingRow(label: "Compact mode", description: "Show more content by reducing spacing") {
                Toggle("", isOn: $compactMode)
                    .toggleStyle(.switch)
                    .tint(PlexTheme.systemBlue)
            }

            SettingRow(label: "Show thumbnails", description: "Display poster images in library views") {
                Toggle("", isOn: $showThumbnails)
                    .toggleStyle(.switch)
                    .tint(PlexTheme.systemBlue)
            }
        }
    }
}

// MARK: - Performance

struct PerformanceSettingsSection: View {
    @AppStorage("autoRefreshInterval") private var autoRefreshInterval = "15m"
    @AppStorage("itemsPerPage") private var itemsPerPage = 20
    @AppStorage("enableCaching") private var enableCaching = true

    let onIntervalChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Performance Settings")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PlexTheme.textPrimary)
                .padding(.bottom, 20)

            SettingRow(label: "Auto-refresh interval", description: "How often to check for new content") {
                Picker("", selection: $autoRefreshInterval) {
                    Text("Off").tag("off")
                    Text("5 minutes").tag("5m")
                    Text("15 minutes").tag("15m")
                    Text("30 minutes").tag("30m")
                    Text("1 hour").tag("1h")
                }
                .pickerStyle(.menu)
                .frame(width: 180)
                .onChange(of: autoRefreshInterval) { _ in onIntervalChange() }
            }

            SettingRow(label: "Items per page", description: "Number of items to show in library views") {
                TextField("", value: $itemsPerPage, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }

            SettingRow(label: "Enable caching", description: "Cache library data for faster loading") {
                Toggle("", isOn: $enableCaching)
                    .toggleStyle(.switch)
                    .tint(PlexTheme.systemBlue)
            }
        }
    }
}

// MARK: - About

struct AboutSettingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("About")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PlexTheme.textPrimary)
                .padding(.bottom, 20)

            SettingRow(label: "Version", description: "Current version of the application") {
                Text("1.0.0")
                    .font(.system(size: 13))
                    .foregroundStyle(PlexTheme.textSecondary)
            }

            SettingRow(label: "Platform", description: "Operating system") {
                Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                    .font(.system(size: 13))
                    .foregroundStyle(PlexTheme.textSecondary)
            }

            SettingRow(label: "License", description: "License type") {
                Text("MIT License")
                    .font(.system(size: 13))
                    .foregroundStyle(PlexTheme.textSecondary)
            }
        }
    }
}

// MARK: - Setting Row

struct SettingRow<Trailing: View>: View {
    let label: String
    let description: String
    let trailing: Trailing

    init(label: String, description: String, @ViewBuilder trailing: () -> Trailing) {
        self.label = label
        self.description = description
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PlexTheme.textPrimary)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(PlexTheme.textSecondary)
            }

            Spacer()

            trailing
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider().overlay(PlexTheme.border)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
