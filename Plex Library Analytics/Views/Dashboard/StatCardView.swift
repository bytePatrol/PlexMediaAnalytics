import SwiftUI

struct StatCardView: View {
    let label: String
    let value: String
    let icon: String
    let iconColor: Color

    @State private var isHovered = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(PlexTheme.textSecondary)

                Text(value)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(PlexTheme.textPrimary)
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .padding(12)
                .background(iconColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(20)
        .cardStyle()
        .shadow(color: .black.opacity(isHovered ? 0.3 : 0.1), radius: isHovered ? 8 : 2, y: isHovered ? 4 : 1)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        StatCardView(label: "Total Items", value: "2,579", icon: "film", iconColor: PlexTheme.systemBlue)
        StatCardView(label: "Total Storage", value: "13.1 TB", icon: "internaldrive", iconColor: PlexTheme.successGreen)
    }
    .padding()
    .background(PlexTheme.bgLevel1)
}
