import Foundation

enum MockDataProvider {
    // MARK: - Mock Media Items

    static let mediaItems: [MediaItem] = [
        MediaItem(
            id: "1", ratingKey: "1", title: "Inception", year: 2010,
            addedAt: date("2025-01-15"), library: "Movies",
            container: "MKV", duration: 148, bitrate: 25.4, fileSize: 15.2,
            filePath: "/media/movies/Inception (2010)/Inception.mkv",
            videoCodec: .h265, videoResolution: .uhd4K, frameRate: 23.976,
            hdrFormat: .dolbyVision, colorSpace: "BT.2020",
            audioCodec: "TrueHD", audioChannels: "7.1", audioProfile: "Dolby Atmos",
            subtitles: [SubtitleTrack(language: "English", format: "SRT"), SubtitleTrack(language: "Spanish", format: "SRT")]
        ),
        MediaItem(
            id: "2", ratingKey: "2", title: "The Dark Knight", year: 2008,
            addedAt: date("2025-01-20"), library: "Movies",
            container: "MKV", duration: 152, bitrate: 22.1, fileSize: 12.8,
            filePath: "/media/movies/The Dark Knight (2008)/The Dark Knight.mkv",
            videoCodec: .h265, videoResolution: .uhd4K, frameRate: 23.976,
            hdrFormat: .hdr10, colorSpace: "BT.2020",
            audioCodec: "DTS-HD MA", audioChannels: "5.1", audioProfile: nil,
            subtitles: [SubtitleTrack(language: "English", format: "PGS")]
        ),
        MediaItem(
            id: "3", ratingKey: "3", title: "Interstellar", year: 2014,
            addedAt: date("2025-02-01"), library: "Movies",
            container: "MKV", duration: 169, bitrate: 28.3, fileSize: 18.5,
            filePath: "/media/movies/Interstellar (2014)/Interstellar.mkv",
            videoCodec: .h265, videoResolution: .uhd4K, frameRate: 23.976,
            hdrFormat: .dolbyVision, colorSpace: "BT.2020",
            audioCodec: "TrueHD", audioChannels: "7.1", audioProfile: "Dolby Atmos",
            subtitles: [SubtitleTrack(language: "English", format: "SRT"), SubtitleTrack(language: "French", format: "SRT")]
        ),
        MediaItem(
            id: "4", ratingKey: "4", title: "The Matrix", year: 1999,
            addedAt: date("2024-12-10"), library: "Movies",
            container: "MKV", duration: 136, bitrate: 12.5, fileSize: 8.2,
            filePath: "/media/movies/The Matrix (1999)/The Matrix.mkv",
            videoCodec: .h264, videoResolution: .fullHD, frameRate: 23.976,
            hdrFormat: nil, colorSpace: nil,
            audioCodec: "DTS-HD MA", audioChannels: "5.1", audioProfile: nil,
            subtitles: [SubtitleTrack(language: "English", format: "SRT")]
        ),
        MediaItem(
            id: "5", ratingKey: "5", title: "Pulp Fiction", year: 1994,
            addedAt: date("2024-11-25"), library: "Movies",
            container: "MKV", duration: 154, bitrate: 10.2, fileSize: 6.4,
            filePath: "/media/movies/Pulp Fiction (1994)/Pulp Fiction.mkv",
            videoCodec: .h264, videoResolution: .fullHD, frameRate: 23.976,
            hdrFormat: nil, colorSpace: nil,
            audioCodec: "AC3", audioChannels: "5.1", audioProfile: nil,
            subtitles: [SubtitleTrack(language: "English", format: "SRT")]
        ),
        MediaItem(
            id: "6", ratingKey: "6", title: "Breaking Bad S01E01", year: 2008,
            addedAt: date("2025-02-10"), library: "TV Shows",
            container: "MKV", duration: 58, bitrate: 8.5, fileSize: 3.2,
            filePath: "/media/tv/Breaking Bad/Season 01/Breaking Bad - S01E01.mkv",
            videoCodec: .h265, videoResolution: .fullHD, frameRate: 23.976,
            hdrFormat: nil, colorSpace: nil,
            audioCodec: "AC3", audioChannels: "5.1", audioProfile: nil,
            subtitles: [SubtitleTrack(language: "English", format: "SRT")]
        ),
        MediaItem(
            id: "7", ratingKey: "7", title: "Toy Story", year: 1995,
            addedAt: date("2025-01-05"), library: "Kids Movies",
            container: "MKV", duration: 81, bitrate: 9.2, fileSize: 4.8,
            filePath: "/media/kids_movies/Toy Story (1995)/Toy Story.mkv",
            videoCodec: .h264, videoResolution: .fullHD, frameRate: 23.976,
            hdrFormat: nil, colorSpace: nil,
            audioCodec: "AC3", audioChannels: "5.1", audioProfile: nil,
            subtitles: [SubtitleTrack(language: "English", format: "SRT")]
        ),
        MediaItem(
            id: "8", ratingKey: "8", title: "Avatar: The Way of Water", year: 2022,
            addedAt: date("2025-02-18"), library: "Movies",
            container: "MKV", duration: 192, bitrate: 32.8, fileSize: 22.4,
            filePath: "/media/movies/Avatar The Way of Water (2022)/Avatar.mkv",
            videoCodec: .h265, videoResolution: .uhd4K, frameRate: 23.976,
            hdrFormat: .dolbyVision, colorSpace: "BT.2020",
            audioCodec: "TrueHD", audioChannels: "7.1", audioProfile: "Dolby Atmos",
            subtitles: [SubtitleTrack(language: "English", format: "PGS")]
        ),
        MediaItem(
            id: "9", ratingKey: "9", title: "Blade Runner 2049", year: 2017,
            addedAt: date("2025-01-28"), library: "Movies",
            container: "MKV", duration: 164, bitrate: 30.1, fileSize: 20.3,
            filePath: "/media/movies/Blade Runner 2049 (2017)/Blade Runner 2049.mkv",
            videoCodec: .h265, videoResolution: .uhd4K, frameRate: 23.976,
            hdrFormat: .hdr10Plus, colorSpace: "BT.2020",
            audioCodec: "DTS-HD MA", audioChannels: "7.1", audioProfile: nil,
            subtitles: [SubtitleTrack(language: "English", format: "SRT")]
        ),
        MediaItem(
            id: "10", ratingKey: "10", title: "Dune: Part Two", year: 2024,
            addedAt: date("2025-02-20"), library: "Movies",
            container: "MKV", duration: 166, bitrate: 35.2, fileSize: 24.1,
            filePath: "/media/movies/Dune Part Two (2024)/Dune Part Two.mkv",
            videoCodec: .h265, videoResolution: .uhd4K, frameRate: 23.976,
            hdrFormat: .dolbyVision, colorSpace: "BT.2020",
            audioCodec: "TrueHD", audioChannels: "7.1", audioProfile: "Dolby Atmos",
            subtitles: [SubtitleTrack(language: "English", format: "PGS"), SubtitleTrack(language: "French", format: "SRT")]
        ),
        MediaItem(
            id: "11", ratingKey: "11", title: "The Shawshank Redemption", year: 1994,
            addedAt: date("2024-10-15"), library: "Movies",
            container: "MKV", duration: 142, bitrate: 11.8, fileSize: 7.1,
            filePath: "/media/movies/The Shawshank Redemption (1994)/Shawshank.mkv",
            videoCodec: .h264, videoResolution: .fullHD, frameRate: 23.976,
            hdrFormat: nil, colorSpace: nil,
            audioCodec: "AC3", audioChannels: "5.1", audioProfile: nil,
            subtitles: [SubtitleTrack(language: "English", format: "SRT")]
        ),
        MediaItem(
            id: "12", ratingKey: "12", title: "Stranger Things S04E01", year: 2022,
            addedAt: date("2025-01-12"), library: "TV Shows",
            container: "MKV", duration: 78, bitrate: 14.2, fileSize: 5.6,
            filePath: "/media/tv/Stranger Things/Season 04/Stranger Things - S04E01.mkv",
            videoCodec: .h265, videoResolution: .uhd4K, frameRate: 23.976,
            hdrFormat: .hdr10, colorSpace: "BT.2020",
            audioCodec: "EAC3", audioChannels: "5.1", audioProfile: "Dolby Atmos",
            subtitles: [SubtitleTrack(language: "English", format: "SRT")]
        ),
        MediaItem(
            id: "13", ratingKey: "13", title: "Finding Nemo", year: 2003,
            addedAt: date("2024-09-20"), library: "Kids Movies",
            container: "MKV", duration: 100, bitrate: 8.8, fileSize: 4.5,
            filePath: "/media/kids_movies/Finding Nemo (2003)/Finding Nemo.mkv",
            videoCodec: .h264, videoResolution: .fullHD, frameRate: 23.976,
            hdrFormat: nil, colorSpace: nil,
            audioCodec: "AC3", audioChannels: "5.1", audioProfile: nil,
            subtitles: [SubtitleTrack(language: "English", format: "SRT")]
        ),
        MediaItem(
            id: "14", ratingKey: "14", title: "Bluey S01E01", year: 2018,
            addedAt: date("2025-02-05"), library: "Kids TV Shows",
            container: "MKV", duration: 7, bitrate: 4.2, fileSize: 0.3,
            filePath: "/media/kids_tv/Bluey/Season 01/Bluey - S01E01.mkv",
            videoCodec: .h264, videoResolution: .fullHD, frameRate: 25.0,
            hdrFormat: nil, colorSpace: nil,
            audioCodec: "AAC", audioChannels: "2.0", audioProfile: nil,
            subtitles: [SubtitleTrack(language: "English", format: "SRT")]
        ),
        MediaItem(
            id: "15", ratingKey: "15", title: "Goodfellas", year: 1990,
            addedAt: date("2024-08-14"), library: "Movies",
            container: "MKV", duration: 146, bitrate: 6.8, fileSize: 4.2,
            filePath: "/media/movies/Goodfellas (1990)/Goodfellas.mkv",
            videoCodec: .h264, videoResolution: .hd, frameRate: 23.976,
            hdrFormat: nil, colorSpace: nil,
            audioCodec: "AC3", audioChannels: "2.0", audioProfile: nil,
            subtitles: [SubtitleTrack(language: "English", format: "SRT")]
        ),
    ]

    // MARK: - Mock Libraries

    static let libraries: [PlexLibrary] = [
        PlexLibrary(
            id: "lib-1", title: "Movies", type: .movie, icon: "🎬",
            itemCount: 847, totalSizeGB: 4235,
            qualityDistribution: QualityDistribution(ultra4K: 288, fullHD1080p: 425, hd720p: 98, sd: 36),
            lastAdded: mediaItems[0]
        ),
        PlexLibrary(
            id: "lib-2", title: "TV Shows", type: .show, icon: "📺",
            itemCount: 1234, totalSizeGB: 6842,
            qualityDistribution: QualityDistribution(ultra4K: 124, fullHD1080p: 856, hd720p: 198, sd: 56),
            lastAdded: mediaItems[5]
        ),
        PlexLibrary(
            id: "lib-3", title: "Kids Movies", type: .movie, icon: "🎨",
            itemCount: 156, totalSizeGB: 782,
            qualityDistribution: QualityDistribution(ultra4K: 42, fullHD1080p: 89, hd720p: 18, sd: 7),
            lastAdded: mediaItems[6]
        ),
        PlexLibrary(
            id: "lib-4", title: "Kids TV Shows", type: .show, icon: "🧸",
            itemCount: 342, totalSizeGB: 1245,
            qualityDistribution: QualityDistribution(ultra4K: 28, fullHD1080p: 234, hd720p: 65, sd: 15)
        ),
    ]

    // MARK: - Chart Data

    struct TimelineEntry: Identifiable {
        let id = UUID()
        let date: String
        let count: Int
    }

    static let recentActivity: [TimelineEntry] = [
        TimelineEntry(date: "2/01", count: 2),
        TimelineEntry(date: "2/03", count: 1),
        TimelineEntry(date: "2/04", count: 3),
        TimelineEntry(date: "2/06", count: 2),
        TimelineEntry(date: "2/07", count: 1),
        TimelineEntry(date: "2/08", count: 4),
        TimelineEntry(date: "2/10", count: 2),
        TimelineEntry(date: "2/11", count: 3),
        TimelineEntry(date: "2/12", count: 1),
        TimelineEntry(date: "2/14", count: 2),
        TimelineEntry(date: "2/15", count: 5),
        TimelineEntry(date: "2/16", count: 1),
        TimelineEntry(date: "2/18", count: 3),
        TimelineEntry(date: "2/19", count: 2),
        TimelineEntry(date: "2/20", count: 1),
        TimelineEntry(date: "2/22", count: 2),
        TimelineEntry(date: "2/23", count: 4),
        TimelineEntry(date: "2/24", count: 1),
        TimelineEntry(date: "2/25", count: 3),
    ]

    struct MonthlyEntry: Identifiable {
        let id = UUID()
        let month: String
        let items: Int
    }

    static let contentOverTime: [MonthlyEntry] = [
        MonthlyEntry(month: "Mar", items: 45),
        MonthlyEntry(month: "Apr", items: 52),
        MonthlyEntry(month: "May", items: 38),
        MonthlyEntry(month: "Jun", items: 65),
        MonthlyEntry(month: "Jul", items: 58),
        MonthlyEntry(month: "Aug", items: 72),
        MonthlyEntry(month: "Sep", items: 48),
        MonthlyEntry(month: "Oct", items: 82),
        MonthlyEntry(month: "Nov", items: 68),
        MonthlyEntry(month: "Dec", items: 91),
        MonthlyEntry(month: "Jan", items: 78),
        MonthlyEntry(month: "Feb", items: 64),
    ]

    struct FileSizeBucket: Identifiable {
        let id = UUID()
        let range: String
        let count: Int
    }

    static let fileSizeDistribution: [FileSizeBucket] = [
        FileSizeBucket(range: "0-2 GB", count: 234),
        FileSizeBucket(range: "2-5 GB", count: 456),
        FileSizeBucket(range: "5-10 GB", count: 782),
        FileSizeBucket(range: "10-20 GB", count: 634),
        FileSizeBucket(range: "20+ GB", count: 473),
    ]

    struct AudioFormatEntry: Identifiable {
        let id = UUID()
        let name: String
        let value: Int
    }

    static let audioFormats: [AudioFormatEntry] = [
        AudioFormatEntry(name: "Dolby Atmos", value: 342),
        AudioFormatEntry(name: "DTS-HD MA", value: 567),
        AudioFormatEntry(name: "TrueHD", value: 234),
        AudioFormatEntry(name: "AC3", value: 892),
        AudioFormatEntry(name: "AAC", value: 544),
    ]

    // MARK: - Helpers

    private static func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string) ?? Date()
    }
}
