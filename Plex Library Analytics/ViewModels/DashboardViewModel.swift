import SwiftUI
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var libraries: [PlexLibrary] = []
    @Published var totalItems: Int = 0
    @Published var totalStorageGB: Double = 0
    @Published var percent4K: Int = 0
    @Published var recentlyAdded: Int = 0
    @Published var showWelcomeBanner = true
    @Published var recentActivity: [MockDataProvider.TimelineEntry] = []

    private let repository: PlexRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: PlexRepositoryProtocol) {
        self.repository = repository

        repository.libraries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] libs in
                self?.libraries = libs
                self?.computeStats(from: libs)
            }
            .store(in: &cancellables)

        repository.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .connected {
                    self?.showWelcomeBanner = false
                }
            }
            .store(in: &cancellables)

        // Load mock data for preview/demo
        if repository.libraries.value.isEmpty {
            loadMockData()
        }
    }

    func loadMockData() {
        libraries = MockDataProvider.libraries
        recentActivity = MockDataProvider.recentActivity
        computeStats(from: libraries)
    }

    func dismissWelcome() {
        withAnimation(.easeOut(duration: 0.3)) {
            showWelcomeBanner = false
        }
    }

    private func computeStats(from libs: [PlexLibrary]) {
        totalItems = libs.reduce(0) { $0 + $1.itemCount }
        totalStorageGB = libs.reduce(0) { $0 + $1.totalSizeGB }

        let total4K = libs.reduce(0) { $0 + $1.qualityDistribution.ultra4K }
        let totalAll = libs.reduce(0) { $0 + $1.qualityDistribution.total }
        percent4K = totalAll > 0 ? Int(Double(total4K) / Double(totalAll) * 100) : 0

        // Count items added in last 7 days
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let allItems = repository.allItems.value
        if !allItems.isEmpty {
            recentlyAdded = allItems.filter { $0.addedAt >= sevenDaysAgo }.count
        } else {
            recentlyAdded = 42 // Mock value
        }
    }

}
