import SwiftUI

struct FilterSidebarView: View {
    @ObservedObject var viewModel: LibraryViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Filters")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PlexTheme.textPrimary)

                    Spacer()

                    if viewModel.activeFilterCount > 0 {
                        Button("Clear All") {
                            viewModel.clearFilters()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(PlexTheme.systemBlue)
                    }
                }
                .padding(.bottom, 16)

                // Library
                if !viewModel.availableLibraries.isEmpty {
                    FilterSection(title: "Library", isExpanded: true) {
                        Button {
                            viewModel.selectedLibrary = nil
                        } label: {
                            HStack {
                                Image(systemName: viewModel.selectedLibrary == nil ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(viewModel.selectedLibrary == nil ? PlexTheme.systemBlue : PlexTheme.textSecondary)
                                Text("All Libraries")
                                    .font(.system(size: 12))
                                    .foregroundStyle(viewModel.selectedLibrary == nil ? PlexTheme.textPrimary : PlexTheme.textSecondary)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        ForEach(viewModel.availableLibraries, id: \.self) { library in
                            Button {
                                viewModel.selectedLibrary = library
                            } label: {
                                HStack {
                                    Image(systemName: viewModel.selectedLibrary == library ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 14))
                                        .foregroundStyle(viewModel.selectedLibrary == library ? PlexTheme.systemBlue : PlexTheme.textSecondary)
                                    Text(library)
                                        .font(.system(size: 12))
                                        .foregroundStyle(viewModel.selectedLibrary == library ? PlexTheme.textPrimary : PlexTheme.textSecondary)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Resolution
                FilterSection(title: "Resolution", isExpanded: true) {
                    ForEach(VideoResolution.allCases, id: \.self) { resolution in
                        FilterCheckbox(
                            label: resolution.rawValue,
                            count: viewModel.resolutionCount(resolution),
                            isSelected: viewModel.selectedResolutions.contains(resolution)
                        ) {
                            if viewModel.selectedResolutions.contains(resolution) {
                                viewModel.selectedResolutions.remove(resolution)
                            } else {
                                viewModel.selectedResolutions.insert(resolution)
                            }
                        }
                    }
                }

                // Video Codec
                FilterSection(title: "Video Codec") {
                    ForEach(VideoCodec.allCases, id: \.self) { codec in
                        FilterCheckbox(
                            label: codec.rawValue,
                            count: viewModel.codecCount(codec),
                            isSelected: viewModel.selectedCodecs.contains(codec)
                        ) {
                            if viewModel.selectedCodecs.contains(codec) {
                                viewModel.selectedCodecs.remove(codec)
                            } else {
                                viewModel.selectedCodecs.insert(codec)
                            }
                        }
                    }
                }

                // Date Added
                FilterSection(title: "Date Added") {
                    ForEach(DateFilter.allCases, id: \.self) { filter in
                        Button {
                            viewModel.dateFilter = filter
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 12))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    viewModel.dateFilter == filter
                                        ? PlexTheme.systemBlue.opacity(0.15)
                                        : PlexTheme.bgLevel3.opacity(0.5)
                                )
                                .foregroundStyle(
                                    viewModel.dateFilter == filter
                                        ? PlexTheme.systemBlue
                                        : PlexTheme.textSecondary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            viewModel.dateFilter == filter
                                                ? PlexTheme.systemBlue.opacity(0.3)
                                                : PlexTheme.border,
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(PlexTheme.bgLevel2)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(PlexTheme.border)
                .frame(width: 1)
        }
    }
}

// MARK: - Filter Section

struct FilterSection<Content: View>: View {
    let title: String
    let content: Content
    @State private var isExpanded: Bool

    init(title: String, isExpanded: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isExpanded = State(initialValue: isExpanded)
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PlexTheme.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(PlexTheme.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 10)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    content
                }
                .padding(.bottom, 12)
            }

            Divider()
                .overlay(PlexTheme.border)
        }
    }
}

// MARK: - Filter Checkbox

struct FilterCheckbox: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? PlexTheme.systemBlue : PlexTheme.textSecondary)

                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(PlexTheme.textPrimary)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 11))
                    .foregroundStyle(PlexTheme.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterSidebarView(viewModel: LibraryViewModel(repository: PlexRepository()))
        .frame(width: 260, height: 600)
        .preferredColorScheme(.dark)
}
