import SwiftUI

struct WelcomeBannerView: View {
    let onDismiss: () -> Void
    let onConnect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 20))
                .foregroundStyle(PlexTheme.plexOrange)
                .padding(12)
                .background(PlexTheme.plexOrange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to Plex Library Analytics!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(PlexTheme.textPrimary)

                Text("Get deep insights into your media collection with powerful analytics and visualizations. Explore your libraries, analyze quality distributions, and track your content growth over time.")
                    .font(.system(size: 13))
                    .foregroundStyle(PlexTheme.textSecondary)
                    .lineSpacing(2)

                HStack(spacing: 12) {
                    Button(action: onConnect) {
                        Text("Connect Server")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(PlexTheme.systemBlue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    Button("Learn More") {
                        // No-op for now
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PlexTheme.textSecondary)
                }
                .padding(.top, 4)
            }

            Spacer()

            // Dismiss
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PlexTheme.textSecondary)
                    .padding(6)
                    .background(PlexTheme.bgLevel1.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    PlexTheme.plexOrange.opacity(0.15),
                    PlexTheme.systemBlue.opacity(0.1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(PlexTheme.plexOrange.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    WelcomeBannerView(onDismiss: {}, onConnect: {})
        .padding()
        .background(PlexTheme.bgLevel1)
}
