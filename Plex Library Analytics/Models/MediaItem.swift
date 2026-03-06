import Foundation

struct MediaItem: Identifiable, Hashable {
    let id: String
    let ratingKey: String
    let title: String
    let year: Int?
    let addedAt: Date
    let library: String

    // File info
    let container: String
    let duration: Int          // minutes
    let bitrate: Double        // Mbps
    let fileSize: Double       // GB
    let filePath: String

    // Video
    let videoCodec: VideoCodec
    let videoResolution: VideoResolution
    let frameRate: Double?
    let hdrFormat: HDRFormat?
    let colorSpace: String?

    // Audio
    let audioCodec: String
    let audioChannels: String
    let audioProfile: String?

    // Subtitles
    let subtitles: [SubtitleTrack]

    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum VideoResolution: String, CaseIterable, Hashable {
    case uhd4K = "4K"
    case fullHD = "1080p"
    case hd = "720p"
    case sd = "SD"
    case unknown = "Unknown"

    init(from string: String) {
        switch string.lowercased() {
        case "4k", "2160", "2160p": self = .uhd4K
        case "1080", "1080p": self = .fullHD
        case "720", "720p": self = .hd
        case "sd", "480", "480p", "576", "576p": self = .sd
        default: self = .unknown
        }
    }

    var sortOrder: Int {
        switch self {
        case .uhd4K: return 0
        case .fullHD: return 1
        case .hd: return 2
        case .sd: return 3
        case .unknown: return 4
        }
    }
}

enum VideoCodec: String, CaseIterable, Hashable {
    case h265 = "H.265"
    case h264 = "H.264"
    case av1 = "AV1"
    case vp9 = "VP9"
    case other = "Other"

    init(from string: String) {
        switch string.lowercased() {
        case "hevc", "h265", "h.265": self = .h265
        case "h264", "h.264", "avc": self = .h264
        case "av1": self = .av1
        case "vp9": self = .vp9
        default: self = .other
        }
    }
}

enum HDRFormat: String, CaseIterable, Hashable {
    case dolbyVision = "Dolby Vision"
    case hdr10Plus = "HDR10+"
    case hdr10 = "HDR10"
    case hlg = "HLG"
}

struct SubtitleTrack: Hashable {
    let language: String
    let format: String
}
