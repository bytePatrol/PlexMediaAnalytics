import SwiftUI

// MARK: - Design Tokens
// Matches the Figma dark theme: Plex-branded colors with macOS system integration

enum PlexTheme {
    // Brand
    static let plexOrange = Color(red: 0.898, green: 0.627, blue: 0.051)  // #E5A00D

    // System colors (macOS HIG aligned)
    static let systemBlue = Color(red: 0.039, green: 0.518, blue: 1.0)     // #0A84FF
    static let successGreen = Color(red: 0.196, green: 0.843, blue: 0.294)  // #32D74B
    static let warningOrange = Color(red: 1.0, green: 0.624, blue: 0.039)   // #FF9F0A
    static let errorRed = Color(red: 1.0, green: 0.271, blue: 0.227)        // #FF453A

    // Background levels (dark mode)
    static let bgLevel1 = Color(red: 0.110, green: 0.110, blue: 0.118)  // #1C1C1E
    static let bgLevel2 = Color(red: 0.173, green: 0.173, blue: 0.180)  // #2C2C2E
    static let bgLevel3 = Color(red: 0.227, green: 0.227, blue: 0.235)  // #3A3A3C

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.596, green: 0.596, blue: 0.616) // #98989D

    // Border
    static let border = Color.white.opacity(0.1)

    // Chart palette
    static let chart4K = plexOrange
    static let chart1080p = systemBlue
    static let chart720p = successGreen
    static let chartSD = Color(red: 0.596, green: 0.596, blue: 0.616)

    // Quality badge colors
    static func qualityColor(for resolution: String) -> Color {
        switch resolution {
        case "4K": return plexOrange
        case "1080p": return systemBlue
        case "720p": return successGreen
        case "SD": return textSecondary
        default: return textSecondary
        }
    }

    static func hdrColor(for format: String) -> Color {
        switch format {
        case "Dolby Vision", "HDR10+": return plexOrange
        case "HDR10": return warningOrange
        case "HLG": return successGreen
        default: return textSecondary
        }
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(PlexTheme.bgLevel2)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(PlexTheme.border, lineWidth: 1)
            )
    }
}

struct BadgeStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func badgeStyle(color: Color) -> some View {
        modifier(BadgeStyle(color: color))
    }
}
