import Foundation

enum Formatters {
    // MARK: - File Size

    static func fileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useGB, .useTB, .useMB]
        return formatter.string(fromByteCount: bytes)
    }

    static func fileSizeGB(_ gb: Double) -> String {
        if gb >= 1000 {
            return String(format: "%.1f TB", gb / 1000)
        }
        return String(format: "%.1f GB", gb)
    }

    static func storageTB(_ gb: Double) -> String {
        String(format: "%.1f TB", gb / 1000)
    }

    // MARK: - Duration

    static func duration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    // MARK: - Bitrate

    static func bitrate(_ mbps: Double) -> String {
        String(format: "%.1f Mbps", mbps)
    }

    // MARK: - Date

    static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    static func absoluteDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/dd"
        return formatter.string(from: date)
    }

    // MARK: - Numbers

    static func count(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func percentage(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }

    static func percentageInt(_ value: Int) -> String {
        "\(value)%"
    }
}
