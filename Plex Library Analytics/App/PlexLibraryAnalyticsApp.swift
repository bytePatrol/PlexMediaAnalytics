import SwiftUI

@main
struct PlexLibraryAnalyticsApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1100, minHeight: 700)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1400, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("View") {
                ForEach(AppTab.allCases) { tab in
                    Button(tab.rawValue) {
                        appState.selectedTab = tab
                    }
                    .keyboardShortcut(keyboardShortcut(for: tab))
                }
            }
            CommandMenu("Server") {
                Button("Refresh Libraries") {
                    appState.refreshData()
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("Connect to Server...") {
                    appState.showServerSetup = true
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }

    private func keyboardShortcut(for tab: AppTab) -> KeyEquivalent {
        switch tab {
        case .dashboard: return "1"
        case .libraries: return "2"
        case .analytics: return "3"
        }
    }
}
