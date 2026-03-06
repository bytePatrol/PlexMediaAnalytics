import SwiftUI

struct LibraryCardView: View {
    let library: PlexLibrary
    let onViewLibrary: () -> Void

    @EnvironmentObject var appState: AppState
    @AppStorage("showThumbnails") private var showThumbnails = true
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    Text(library.icon)
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(library.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(PlexTheme.textPrimary)

                        Text("\(Formatters.count(library.itemCount)) items")
                            .font(.system(size: 13))
                            .foregroundStyle(PlexTheme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Formatters.storageTB(library.totalSizeGB))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PlexTheme.textPrimary)

                    Text("Total size")
                        .font(.system(size: 11))
                        .foregroundStyle(PlexTheme.textSecondary)
                }
            }
            .padding(.bottom, 16)

            // Quality distribution chart + legend
            HStack(spacing: 20) {
                MiniPieChart(distribution: library.qualityDistribution, size: 80)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(library.qualityDistribution.segments, id: \.label) { segment in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(PlexTheme.qualityColor(for: segment.color))
                                .frame(width: 7, height: 7)

                            Text("\(segment.label): \(segment.value)")
                                .font(.system(size: 12))
                                .foregroundStyle(PlexTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(.bottom, 16)

            // Last added
            if let lastAdded = library.lastAdded {
                Divider()
                    .overlay(PlexTheme.border)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Added")
                        .font(.system(size: 11))
                        .foregroundStyle(PlexTheme.textSecondary)
                        .padding(.top, 12)

                    HStack(spacing: 10) {
                        PosterImage(
                            url: showThumbnails ? appState.thumbnailURL(ratingKey: lastAdded.ratingKey, width: 80, height: 112) : nil,
                            width: 40, height: 56
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(lastAdded.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(PlexTheme.textPrimary)
                                .lineLimit(1)

                            if let year = lastAdded.year {
                                Text("\(year)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(PlexTheme.textSecondary)
                            }

                            ResolutionBadge(resolution: lastAdded.videoResolution)
                        }
                    }
                }
            }

            // Hover action
            if isHovered {
                Button(action: onViewLibrary) {
                    Text("View Library")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(PlexTheme.systemBlue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(20)
        .cardStyle()
        .shadow(color: .black.opacity(isHovered ? 0.3 : 0.1), radius: isHovered ? 10 : 3, y: isHovered ? 4 : 1)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onViewLibrary()
        }
    }
}

#Preview {
    LibraryCardView(
        library: MockDataProvider.libraries[0],
        onViewLibrary: {}
    )
    .environmentObject(AppState())
    .frame(width: 500)
    .padding()
    .background(PlexTheme.bgLevel1)
}
