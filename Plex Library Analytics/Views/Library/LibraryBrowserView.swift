import SwiftUI

struct LibraryBrowserView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: LibraryViewModel

    init(repository: PlexRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(repository: repository))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Filter Sidebar
            FilterSidebarView(viewModel: viewModel)
                .frame(width: 260)

            // Main content
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $viewModel.searchText, activeFilterCount: viewModel.activeFilterCount)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // Results header
                HStack {
                    Text("Showing \(viewModel.paginatedItems.count) of \(viewModel.filteredItems.count) items")
                        .font(.system(size: 13))
                        .foregroundStyle(PlexTheme.textSecondary)

                    Spacer()

                    HStack(spacing: 12) {
                        // Sort picker
                        Menu {
                            ForEach(SortColumn.allCases, id: \.self) { column in
                                Button {
                                    if viewModel.sortColumn == column {
                                        viewModel.sortAscending.toggle()
                                    } else {
                                        viewModel.sortColumn = column
                                        viewModel.sortAscending = false
                                    }
                                } label: {
                                    HStack {
                                        Text(column.rawValue)
                                        if viewModel.sortColumn == column {
                                            Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.sortColumn.rawValue)
                                    .font(.system(size: 12))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(PlexTheme.bgLevel2)
                            .foregroundStyle(PlexTheme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(PlexTheme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // Export button
                        Button {
                            viewModel.exportCSV()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 11))
                                Text("Export")
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(PlexTheme.bgLevel2)
                            .foregroundStyle(PlexTheme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(PlexTheme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Media Table
                MediaTableView(viewModel: viewModel)

                // Pagination
                PaginationBar(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        }
        .background(PlexTheme.bgLevel1)
        .onAppear {
            if let name = appState.selectedLibraryName {
                viewModel.selectedLibrary = name
                appState.selectedLibraryName = nil
            }
        }
        .onChange(of: appState.selectedLibraryName) { name in
            if let name {
                viewModel.selectedLibrary = name
                appState.selectedLibraryName = nil
            }
        }
        .sheet(isPresented: $viewModel.showDetail) {
            if let item = viewModel.selectedItem {
                MediaDetailView(item: item)
                    .environmentObject(appState)
                    .frame(width: 480, height: 700)
            }
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let activeFilterCount: Int

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(PlexTheme.textSecondary)
                .padding(.leading, 12)

            TextField("Search by title, year, codec...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 8)
                .padding(.vertical, 9)

            if activeFilterCount > 0 {
                Text("\(activeFilterCount) active filters")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(PlexTheme.systemBlue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.trailing, 8)
            }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(PlexTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 10)
            }
        }
        .background(PlexTheme.bgLevel2)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(PlexTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Pagination

struct PaginationBar: View {
    @ObservedObject var viewModel: LibraryViewModel

    var body: some View {
        HStack {
            let startItem = (viewModel.currentPage - 1) * viewModel.itemsPerPage + 1
            let endItem = min(viewModel.currentPage * viewModel.itemsPerPage, viewModel.filteredItems.count)

            Text("\(startItem)-\(endItem) of \(viewModel.filteredItems.count)")
                .font(.system(size: 13))
                .foregroundStyle(PlexTheme.textSecondary)

            Spacer()

            HStack(spacing: 6) {
                PaginationButton(label: "Previous", disabled: viewModel.currentPage <= 1) {
                    viewModel.goToPage(viewModel.currentPage - 1)
                }

                ForEach(visiblePages, id: \.self) { page in
                    Button {
                        viewModel.goToPage(page)
                    } label: {
                        Text("\(page)")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 32, height: 28)
                            .background(viewModel.currentPage == page ? PlexTheme.systemBlue : PlexTheme.bgLevel2)
                            .foregroundStyle(viewModel.currentPage == page ? .white : PlexTheme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(PlexTheme.border, lineWidth: viewModel.currentPage == page ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.totalPages > 5 {
                    Text("...")
                        .foregroundStyle(PlexTheme.textSecondary)
                        .font(.system(size: 12))
                }

                PaginationButton(label: "Next", disabled: viewModel.currentPage >= viewModel.totalPages) {
                    viewModel.goToPage(viewModel.currentPage + 1)
                }
            }
        }
    }

    private var visiblePages: [Int] {
        Array(1...min(5, viewModel.totalPages))
    }
}

struct PaginationButton: View {
    let label: String
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(PlexTheme.bgLevel2)
                .foregroundStyle(disabled ? PlexTheme.textSecondary.opacity(0.5) : PlexTheme.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(PlexTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

#Preview {
    LibraryBrowserView(repository: PlexRepository())
        .environmentObject(AppState())
        .frame(width: 1400, height: 800)
        .preferredColorScheme(.dark)
}
