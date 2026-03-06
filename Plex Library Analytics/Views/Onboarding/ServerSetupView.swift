import SwiftUI

struct ServerSetupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var phase: SetupPhase = .signIn
    @State private var oauthService = PlexOAuthService()
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    // OAuth results
    @State private var authToken: String?
    @State private var discoveredServers: [DiscoveredServer] = []
    @State private var selectedServer: DiscoveredServer?

    // Manual entry
    @State private var showManualEntry = false
    @State private var manualHost = ""
    @State private var manualPort = "32400"
    @State private var manualToken = ""
    @State private var manualName = ""
    @State private var manualSSL = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Content switches by phase
            switch phase {
            case .signIn:
                signInPhase
            case .waitingForAuth:
                waitingPhase
            case .selectServer:
                serverSelectionPhase
            case .connected:
                connectedPhase
            }
        }
        .frame(width: 520, height: showManualEntry ? 620 : 520)
        .background(PlexTheme.bgLevel2)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: phase)
        .animation(.easeInOut(duration: 0.25), value: showManualEntry)
        .onDisappear {
            oauthService.cancel()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(PlexTheme.plexOrange.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: headerIcon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(PlexTheme.plexOrange)
            }
            .padding(.top, 28)

            Text(headerTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(PlexTheme.textPrimary)

            Text(headerSubtitle)
                .font(.system(size: 13))
                .foregroundStyle(PlexTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.bottom, 20)
    }

    private var headerIcon: String {
        switch phase {
        case .signIn: return "person.crop.circle.badge.plus"
        case .waitingForAuth: return "globe"
        case .selectServer: return "server.rack"
        case .connected: return "checkmark.circle"
        }
    }

    private var headerTitle: String {
        switch phase {
        case .signIn: return "Connect to Plex"
        case .waitingForAuth: return "Waiting for Sign In"
        case .selectServer: return "Select a Server"
        case .connected: return "Connected!"
        }
    }

    private var headerSubtitle: String {
        switch phase {
        case .signIn: return "Sign in with your Plex account to get started"
        case .waitingForAuth: return "Complete sign-in in your browser, then come back here"
        case .selectServer: return "Choose which Plex server to analyze"
        case .connected: return "Your server is ready to go"
        }
    }

    // MARK: - Phase 1: Sign In

    private var signInPhase: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                // Primary: OAuth button
                Button {
                    startOAuth()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14))
                        Text("Sign in with Plex")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(PlexTheme.plexOrange)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(isSigningIn)

                Text("Opens plex.tv in your browser for secure sign-in")
                    .font(.system(size: 11))
                    .foregroundStyle(PlexTheme.textSecondary)

                // Divider
                HStack {
                    Rectangle().fill(PlexTheme.border).frame(height: 1)
                    Text("OR")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(PlexTheme.textSecondary)
                        .padding(.horizontal, 12)
                    Rectangle().fill(PlexTheme.border).frame(height: 1)
                }
                .padding(.vertical, 8)

                // Secondary: Manual entry toggle
                Button {
                    withAnimation { showManualEntry.toggle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 13))
                        Text("Enter server details manually")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: showManualEntry ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(PlexTheme.bgLevel3.opacity(0.5))
                    .foregroundStyle(PlexTheme.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(PlexTheme.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Manual entry form
                if showManualEntry {
                    manualEntryForm
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 32)

            // Error
            if let error = errorMessage {
                errorBanner(error)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
            }

            Spacer()

            // Footer
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Spacer()
                if showManualEntry {
                    Button("Connect") { connectManual() }
                        .buttonStyle(.borderedProminent)
                        .tint(PlexTheme.systemBlue)
                        .controlSize(.large)
                        .disabled(manualHost.isEmpty || manualToken.isEmpty)
                }
            }
            .padding(24)
        }
    }

    // MARK: - Manual Entry Form

    private var manualEntryForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            FormField(label: "Server Name") {
                TextField("My Plex Server", text: $manualName)
                    .textFieldStyle(.roundedBorder)
            }

            FormField(label: "Host Address") {
                TextField("192.168.1.100 or plex.example.com", text: $manualHost)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                FormField(label: "Port") {
                    TextField("32400", text: $manualPort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }
                FormField(label: "") {
                    Toggle("Use HTTPS", isOn: $manualSSL)
                        .toggleStyle(.switch)
                        .tint(PlexTheme.systemBlue)
                }
            }

            FormField(label: "Plex Token") {
                SecureField("Authentication token", text: $manualToken)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Phase 2: Waiting for Browser Auth

    private var waitingPhase: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                // Animated spinner
                ProgressView()
                    .controlSize(.large)
                    .tint(PlexTheme.plexOrange)

                Text("Checking for sign-in completion...")
                    .font(.system(size: 13))
                    .foregroundStyle(PlexTheme.textSecondary)

                // Re-open browser link
                Button {
                    startOAuth()
                } label: {
                    Text("Reopen browser")
                        .font(.system(size: 12))
                        .foregroundStyle(PlexTheme.systemBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)

            if let error = errorMessage {
                errorBanner(error)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    oauthService.cancel()
                    phase = .signIn
                    isSigningIn = false
                    errorMessage = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                Spacer()
            }
            .padding(24)
        }
    }

    // MARK: - Phase 3: Server Selection

    private var serverSelectionPhase: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(discoveredServers) { server in
                        ServerSelectionRow(
                            server: server,
                            isSelected: selectedServer?.id == server.id
                        ) {
                            selectedServer = server
                        }
                    }

                    if discoveredServers.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 28))
                                .foregroundStyle(PlexTheme.warningOrange)
                            Text("No servers found on your account")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(PlexTheme.textPrimary)
                            Text("Make sure your Plex server is running and claimed to your account.")
                                .font(.system(size: 12))
                                .foregroundStyle(PlexTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 30)
                    }
                }
                .padding(.horizontal, 32)
            }
            .frame(maxHeight: 280)

            if let error = errorMessage {
                errorBanner(error)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }

            Spacer()

            HStack {
                Button("Back") {
                    phase = .signIn
                    selectedServer = nil
                    errorMessage = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Spacer()

                Button("Connect") {
                    connectToSelected()
                }
                .buttonStyle(.borderedProminent)
                .tint(PlexTheme.systemBlue)
                .controlSize(.large)
                .disabled(selectedServer == nil)
            }
            .padding(24)
        }
    }

    // MARK: - Phase 4: Connected

    private var connectedPhase: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(PlexTheme.successGreen)

                if let server = selectedServer {
                    VStack(spacing: 4) {
                        Text(server.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(PlexTheme.textPrimary)
                        Text("\(server.host):\(server.port)")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(PlexTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(PlexTheme.systemBlue)
                .controlSize(.large)
            }
            .padding(24)
        }
    }

    // MARK: - Shared Components

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 12))
            Text(message)
                .font(.system(size: 12))
            Spacer()
            Button {
                errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(PlexTheme.errorRed)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(PlexTheme.errorRed)
        .padding(10)
        .background(PlexTheme.errorRed.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Actions

    private func startOAuth() {
        isSigningIn = true
        errorMessage = nil
        phase = .waitingForAuth

        Task {
            do {
                let pin = try await oauthService.startOAuth()
                let token = try await oauthService.pollForToken(pinID: pin.id)

                authToken = token
                isSigningIn = false

                // Fetch servers
                let servers = try await oauthService.fetchServers(token: token)
                discoveredServers = servers

                if servers.count == 1 {
                    // Auto-select if only one server
                    selectedServer = servers.first
                    connectToSelected()
                } else {
                    phase = .selectServer
                }
            } catch is CancellationError {
                isSigningIn = false
            } catch {
                isSigningIn = false
                errorMessage = error.localizedDescription
                phase = .signIn
            }
        }
    }

    private func connectToSelected() {
        guard let server = selectedServer else { return }

        let plexServer = server.toPlexServer()
        try? KeychainManager.save(token: plexServer.token, for: plexServer.id)
        appState.connectToServer(plexServer)

        phase = .connected

        // Auto-dismiss after a moment
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        }
    }

    private func connectManual() {
        guard let port = Int(manualPort) else {
            errorMessage = "Invalid port number"
            return
        }

        let server = PlexServer(
            name: manualName.isEmpty ? "Plex Server" : manualName,
            host: manualHost,
            port: port,
            token: manualToken,
            isSecure: manualSSL
        )

        try? KeychainManager.save(token: manualToken, for: server.id)
        appState.connectToServer(server)
        dismiss()
    }
}

// MARK: - Setup Phase

private enum SetupPhase: Equatable {
    case signIn
    case waitingForAuth
    case selectServer
    case connected
}

// MARK: - Server Selection Row

private struct ServerSelectionRow: View {
    let server: DiscoveredServer
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? PlexTheme.systemBlue : PlexTheme.textSecondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 18, height: 18)

                    if isSelected {
                        Circle()
                            .fill(PlexTheme.systemBlue)
                            .frame(width: 10, height: 10)
                    }
                }

                // Server icon
                Image(systemName: "server.rack")
                    .font(.system(size: 18))
                    .foregroundStyle(PlexTheme.plexOrange)
                    .frame(width: 32)

                // Details
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(server.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(PlexTheme.textPrimary)

                        if server.isOwned {
                            Text("OWNED")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(PlexTheme.plexOrange.opacity(0.2))
                                .foregroundStyle(PlexTheme.plexOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }

                    Text("\(server.host):\(server.port)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(PlexTheme.textSecondary)

                    // Connection types
                    HStack(spacing: 6) {
                        if server.connections.contains(where: { $0.isLocal }) {
                            connectionBadge("Local", color: PlexTheme.successGreen)
                        }
                        if server.connections.contains(where: { !$0.isLocal && !$0.isRelay }) {
                            connectionBadge("Remote", color: PlexTheme.systemBlue)
                        }
                        if server.connections.contains(where: { $0.isRelay }) {
                            connectionBadge("Relay", color: PlexTheme.warningOrange)
                        }
                        if server.isSecure {
                            connectionBadge("SSL", color: PlexTheme.textSecondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(
                isSelected
                    ? PlexTheme.systemBlue.opacity(0.08)
                    : PlexTheme.bgLevel3.opacity(0.3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? PlexTheme.systemBlue.opacity(0.4) : PlexTheme.border,
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func connectionBadge(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

// MARK: - Form Field (preserved from original)

struct FormField<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PlexTheme.textSecondary)
            }

            content
        }
    }
}

#Preview {
    ServerSetupView()
        .environmentObject(AppState())
}
