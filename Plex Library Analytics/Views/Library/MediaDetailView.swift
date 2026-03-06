import SwiftUI

struct MediaDetailView: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @AppStorage("showThumbnails") private var showThumbnails = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    // Gradient header
                    LinearGradient(
                        colors: [PlexTheme.bgLevel3, PlexTheme.bgLevel2],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .overlay(alignment: .leading) {
                        HStack(spacing: 14) {
                            // Poster (async if server available, placeholder otherwise)
                            PosterImage(
                                url: showThumbnails ? appState.thumbnailURL(ratingKey: item.ratingKey, width: 120, height: 180) : nil,
                                width: 60, height: 90
                            )
                            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(PlexTheme.textPrimary)
                                    .lineLimit(2)

                                if let year = item.year {
                                    Text("\(year)")
                                        .font(.system(size: 14))
                                        .foregroundStyle(PlexTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(PlexTheme.textSecondary)
                        .padding(8)
                        .background(PlexTheme.bgLevel3)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(16)
            }

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // File Information
                    DetailSection(title: "FILE INFORMATION") {
                        DetailRow(label: "File Path", value: item.filePath, isMono: true)
                        DetailRow(label: "Container", value: item.container.uppercased())
                        DetailRow(label: "File Size", value: Formatters.fileSizeGB(item.fileSize))
                        DetailRow(label: "Duration", value: Formatters.duration(minutes: item.duration))
                        DetailRow(label: "Bitrate", value: Formatters.bitrate(item.bitrate))
                    }

                    // Video
                    DetailSection(title: "VIDEO") {
                        DetailRow(label: "Resolution") {
                            ResolutionBadge(resolution: item.videoResolution)
                        }
                        DetailRow(label: "Codec", value: item.videoCodec.rawValue)
                        if let fps = item.frameRate {
                            DetailRow(label: "Frame Rate", value: String(format: "%.3f fps", fps))
                        }
                        if let hdr = item.hdrFormat {
                            DetailRow(label: "HDR") {
                                HDRBadge(format: hdr)
                            }
                        }
                        if let colorSpace = item.colorSpace {
                            DetailRow(label: "Color Space", value: colorSpace)
                        }
                    }

                    // Audio
                    DetailSection(title: "AUDIO") {
                        if let profile = item.audioProfile {
                            DetailRow(label: "Format", value: profile)
                        }
                        DetailRow(label: "Codec", value: item.audioCodec)
                        DetailRow(label: "Channels", value: item.audioChannels)
                    }

                    // Subtitles
                    if !item.subtitles.isEmpty {
                        DetailSection(title: "SUBTITLES") {
                            ForEach(item.subtitles, id: \.self) { sub in
                                DetailRow(label: sub.language, value: sub.format)
                            }
                        }
                    }

                    // Metadata
                    DetailSection(title: "METADATA") {
                        DetailRow(label: "Date Added", value: Formatters.absoluteDate(item.addedAt))
                        DetailRow(label: "Library", value: item.library)
                    }
                }
                .padding(24)
            }

            Divider().overlay(PlexTheme.border)

            // Footer actions
            HStack(spacing: 12) {
                Button {
                    openInPlex()
                } label: {
                    Label("Open in Plex", systemImage: "arrow.up.right.square")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(PlexTheme.systemBlue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(appState.currentServer == nil || appState.machineIdentifier == nil)

                Button {
                    showInFinder()
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(PlexTheme.bgLevel3)
                        .foregroundStyle(PlexTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(PlexTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(PlexTheme.bgLevel2)
    }

    // MARK: - Actions

    private func openInPlex() {
        guard let server = appState.currentServer,
              let machineId = appState.machineIdentifier,
              let base = server.baseURL else { return }
        // Build the URL as a raw string — URLComponents would percent-encode
        // the '?' and '=' inside the fragment, breaking Plex's hash-based routing.
        let urlString = "\(base.absoluteString)/web/index.html#!/server/\(machineId)/details?key=%2Flibrary%2Fmetadata%2F\(item.ratingKey)"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    private func showInFinder() {
        let fileURL = URL(fileURLWithPath: item.filePath)
        if FileManager.default.fileExists(atPath: item.filePath) {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } else {
            // File is on a remote server — copy the path to clipboard instead
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.filePath, forType: .string)
        }
    }
}

// MARK: - Plex Async Image

struct PlexAsyncImage: View {
    let url: URL?
    let placeholderIcon: String

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: placeholderIcon)
                    .foregroundStyle(PlexTheme.textSecondary.opacity(0.5))
            }
        }
        .onAppear { loadImage() }
        .onChange(of: url?.absoluteString) { loadImage() }
    }

    private func loadImage() {
        guard let url else { return }
        Task {
            var request = URLRequest(url: url)
            request.setValue("PlexLibraryAnalytics", forHTTPHeaderField: "X-Plex-Product")
            request.setValue("1.0.0", forHTTPHeaderField: "X-Plex-Version")
            request.setValue("macOS", forHTTPHeaderField: "X-Plex-Platform")
            guard let (data, response) = try? await PlexTrustDelegate.sharedSession.data(for: request),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let loaded = NSImage(data: data) else { return }
            await MainActor.run { image = loaded }
        }
    }
}

// MARK: - Poster Image

struct PosterImage: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        PlexAsyncImage(url: url, placeholderIcon: "film")
            .font(.system(size: width * 0.35))
            .frame(width: width, height: height)
            .background(PlexTheme.bgLevel3)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Detail Section

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(PlexTheme.textSecondary)
                .tracking(1)

            VStack(spacing: 0) {
                content
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow<Trailing: View>: View {
    let label: String
    let trailing: Trailing

    init(label: String, @ViewBuilder trailing: () -> Trailing) {
        self.label = label
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(PlexTheme.textSecondary)
                .frame(minWidth: 100, alignment: .leading)

            Spacer()

            trailing
        }
        .padding(.vertical, 6)
    }
}

extension DetailRow where Trailing == AnyView {
    init(label: String, value: String, isMono: Bool = false) {
        self.label = label
        self.trailing = AnyView(
            Text(value)
                .font(.system(size: isMono ? 11 : 13, design: isMono ? .monospaced : .default))
                .foregroundStyle(PlexTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        )
    }
}

#Preview {
    MediaDetailView(item: MockDataProvider.mediaItems[0])
        .environmentObject(AppState())
        .frame(width: 480, height: 700)
        .preferredColorScheme(.dark)
}
