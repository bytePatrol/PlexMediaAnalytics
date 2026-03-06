import Foundation

struct PlexLibrary: Identifiable, Hashable {
    let id: String
    let title: String
    let type: LibraryType
    let icon: String
    var itemCount: Int
    var totalSizeGB: Double
    var qualityDistribution: QualityDistribution
    var lastAdded: MediaItem?

    var totalSizeTB: Double {
        totalSizeGB / 1000
    }

    var averageFileSizeGB: Double {
        guard itemCount > 0 else { return 0 }
        return totalSizeGB / Double(itemCount)
    }

    static func == (lhs: PlexLibrary, rhs: PlexLibrary) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum LibraryType: String, Codable, CaseIterable {
    case movie = "movie"
    case show = "show"

    var displayName: String {
        switch self {
        case .movie: return "Movies"
        case .show: return "TV Shows"
        }
    }
}

struct QualityDistribution: Hashable {
    var ultra4K: Int
    var fullHD1080p: Int
    var hd720p: Int
    var sd: Int

    var total: Int {
        ultra4K + fullHD1080p + hd720p + sd
    }

    var segments: [(label: String, value: Int, color: String)] {
        [
            ("4K", ultra4K, "4K"),
            ("1080p", fullHD1080p, "1080p"),
            ("720p", hd720p, "720p"),
            ("SD", sd, "SD")
        ]
    }
}
