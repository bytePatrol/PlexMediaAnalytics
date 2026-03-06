import SwiftUI

struct MediaTableView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Table header
            HStack(spacing: 0) {
                TableHeaderCell(title: "Title", width: nil, alignment: .leading)
                TableHeaderCell(title: "Added", width: 110, alignment: .leading)
                TableHeaderCell(title: "Size", width: 100, alignment: .leading)
                TableHeaderCell(title: "Resolution", width: 90, alignment: .leading)
                TableHeaderCell(title: "Codec", width: 70, alignment: .leading)
                TableHeaderCell(title: "Bitrate", width: 80, alignment: .leading)
                TableHeaderCell(title: "Audio", width: 120, alignment: .leading)
                TableHeaderCell(title: "HDR", width: 100, alignment: .leading)
                TableHeaderCell(title: "", width: 40, alignment: .center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(PlexTheme.bgLevel3.opacity(0.5))

            Divider().overlay(PlexTheme.border)

            // Table body
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.paginatedItems.enumerated()), id: \.element.id) { index, item in
                        MediaTableRow(
                            item: item,
                            thumbnailURL: appState.thumbnailURL(ratingKey: item.ratingKey, width: 64, height: 88),
                            isEven: index % 2 == 0
                        ) {
                            viewModel.selectItem(item)
                        }

                        if index < viewModel.paginatedItems.count - 1 {
                            Divider().overlay(PlexTheme.border.opacity(0.5))
                        }
                    }
                }
            }
        }
        .background(PlexTheme.bgLevel2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(PlexTheme.border, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Table Header Cell

struct TableHeaderCell: View {
    let title: String
    let width: CGFloat?
    let alignment: Alignment

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(PlexTheme.textSecondary)
            .frame(maxWidth: width ?? .infinity, alignment: alignment)
    }
}

// MARK: - Media Table Row

struct MediaTableRow: View {
    let item: MediaItem
    let thumbnailURL: URL?
    let isEven: Bool
    let onSelect: () -> Void

    @State private var isHovered = false
    @State private var thumbnailImage: NSImage?

    var body: some View {
        HStack(spacing: 0) {
            // Title with quality indicator
            HStack(spacing: 10) {
                // Quality color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(qualityBarColor)
                    .frame(width: 3, height: 44)

                // Poster thumbnail
                ZStack {
                    if let thumbnailImage {
                        Image(nsImage: thumbnailImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "film")
                            .font(.system(size: 10))
                            .foregroundStyle(PlexTheme.textSecondary.opacity(0.5))
                    }
                }
                .frame(width: 32, height: 44)
                .background(PlexTheme.bgLevel3)
                .clipShape(RoundedRectangle(cornerRadius: 3))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PlexTheme.textPrimary)
                        .lineLimit(1)

                    if let year = item.year {
                        Text("\(year)")
                            .font(.system(size: 11))
                            .foregroundStyle(PlexTheme.textSecondary)
                    }
                }

                Spacer()
            }

            // Date Added
            Text(Formatters.relativeDate(item.addedAt))
                .font(.system(size: 12))
                .foregroundStyle(PlexTheme.textSecondary)
                .frame(width: 110, alignment: .leading)

            // File Size
            VStack(alignment: .leading, spacing: 4) {
                Text(Formatters.fileSizeGB(item.fileSize))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(PlexTheme.textPrimary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(PlexTheme.bgLevel3)
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(PlexTheme.systemBlue)
                            .frame(width: geo.size.width * min(item.fileSize / 30.0, 1.0), height: 3)
                    }
                }
                .frame(height: 3)
            }
            .frame(width: 100, alignment: .leading)

            // Resolution
            ResolutionBadge(resolution: item.videoResolution)
                .frame(width: 90, alignment: .leading)

            // Codec
            Text(item.videoCodec.rawValue)
                .font(.system(size: 12))
                .foregroundStyle(PlexTheme.textSecondary)
                .frame(width: 70, alignment: .leading)

            // Bitrate
            Text(Formatters.bitrate(item.bitrate))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(PlexTheme.textSecondary)
                .frame(width: 80, alignment: .leading)

            // Audio
            VStack(alignment: .leading, spacing: 2) {
                Text(item.audioProfile ?? item.audioCodec)
                    .font(.system(size: 12))
                    .foregroundStyle(PlexTheme.textPrimary)
                    .lineLimit(1)

                Text(item.audioChannels)
                    .font(.system(size: 11))
                    .foregroundStyle(PlexTheme.textSecondary)
            }
            .frame(width: 120, alignment: .leading)

            // HDR
            Group {
                if let hdr = item.hdrFormat {
                    HDRBadge(format: hdr)
                } else {
                    Text("--")
                        .font(.system(size: 12))
                        .foregroundStyle(PlexTheme.textSecondary.opacity(0.5))
                }
            }
            .frame(width: 100, alignment: .leading)

            // Actions
            Button {
                onSelect()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12))
                    .foregroundStyle(PlexTheme.textSecondary)
                    .padding(6)
                    .background(isHovered ? PlexTheme.bgLevel3 : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .frame(width: 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            isHovered
                ? PlexTheme.bgLevel3.opacity(0.4)
                : (isEven ? PlexTheme.bgLevel1.opacity(0.3) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            onSelect()
        }
        .onAppear { loadThumbnail() }
        .onChange(of: thumbnailURL?.absoluteString) { loadThumbnail() }
    }

    private func loadThumbnail() {
        guard let url = thumbnailURL else { return }
        Task {
            var request = URLRequest(url: url)
            request.setValue("PlexLibraryAnalytics", forHTTPHeaderField: "X-Plex-Product")
            request.setValue("1.0.0", forHTTPHeaderField: "X-Plex-Version")
            request.setValue("macOS", forHTTPHeaderField: "X-Plex-Platform")
            guard let (data, response) = try? await PlexTrustDelegate.sharedSession.data(for: request),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let loaded = NSImage(data: data) else { return }
            await MainActor.run { thumbnailImage = loaded }
        }
    }

    private var qualityBarColor: Color {
        if item.videoResolution == .uhd4K && item.hdrFormat != nil {
            return PlexTheme.successGreen
        }
        return PlexTheme.qualityColor(for: item.videoResolution.rawValue)
    }
}

#Preview {
    MediaTableView(viewModel: LibraryViewModel(repository: PlexRepository()))
        .frame(width: 1000, height: 400)
        .preferredColorScheme(.dark)
}
