import SwiftUI

struct MiniPieChart: View {
    let segments: [(label: String, value: Int, color: Color)]
    let size: CGFloat

    init(distribution: QualityDistribution, size: CGFloat = 80) {
        self.segments = [
            ("4K", distribution.ultra4K, PlexTheme.chart4K),
            ("1080p", distribution.fullHD1080p, PlexTheme.chart1080p),
            ("720p", distribution.hd720p, PlexTheme.chart720p),
            ("SD", distribution.sd, PlexTheme.chartSD),
        ]
        self.size = size
    }

    var body: some View {
        ZStack {
            ForEach(Array(segmentAngles.enumerated()), id: \.offset) { index, segment in
                PieSlice(
                    startAngle: .degrees(segment.start),
                    endAngle: .degrees(segment.end)
                )
                .fill(segments[index].color)
            }

            // Inner cutout for donut style
            Circle()
                .fill(PlexTheme.bgLevel2)
                .frame(width: size * 0.45, height: size * 0.45)
        }
        .frame(width: size, height: size)
    }

    private var total: Double {
        Double(segments.reduce(0) { $0 + $1.value })
    }

    private var segmentAngles: [(start: Double, end: Double)] {
        guard total > 0 else { return [] }
        var angles: [(start: Double, end: Double)] = []
        var currentAngle = -90.0

        for segment in segments {
            let sweep = (Double(segment.value) / total) * 360.0
            angles.append((start: currentAngle, end: currentAngle + sweep))
            currentAngle += sweep
        }

        return angles
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle, endAngle: endAngle,
                    clockwise: false)
        path.closeSubpath()

        return path
    }
}

#Preview {
    MiniPieChart(
        distribution: QualityDistribution(ultra4K: 288, fullHD1080p: 425, hd720p: 98, sd: 36)
    )
    .padding()
    .background(PlexTheme.bgLevel2)
}
