import SwiftUI

struct QualityBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .badgeStyle(color: badgeColor)
    }

    private var badgeColor: Color {
        switch label {
        case "4K": return PlexTheme.plexOrange
        case "1080p": return PlexTheme.systemBlue
        case "720p": return PlexTheme.successGreen
        case "SD": return PlexTheme.textSecondary
        case "Dolby Vision", "HDR10+": return PlexTheme.plexOrange
        case "HDR10": return PlexTheme.warningOrange
        case "HLG": return PlexTheme.successGreen
        case "H.265", "HEVC": return PlexTheme.systemBlue
        case "H.264", "AVC": return PlexTheme.textSecondary
        case "AV1": return PlexTheme.successGreen
        case "Dolby Atmos": return PlexTheme.plexOrange
        default: return PlexTheme.textSecondary
        }
    }
}

struct ResolutionBadge: View {
    let resolution: VideoResolution

    var body: some View {
        QualityBadge(label: resolution.rawValue)
    }
}

struct HDRBadge: View {
    let format: HDRFormat

    var body: some View {
        QualityBadge(label: format.rawValue)
    }
}

#Preview {
    HStack(spacing: 8) {
        QualityBadge(label: "4K")
        QualityBadge(label: "1080p")
        QualityBadge(label: "Dolby Vision")
        QualityBadge(label: "H.265")
        QualityBadge(label: "Dolby Atmos")
    }
    .padding()
    .background(PlexTheme.bgLevel1)
}
