import SwiftUI

/// iOS 16-safe stand-in for `ContentUnavailableView` (iOS 17+), which the
/// app's minimum target doesn't have access to.
struct EmptyStateView: View {
    let systemImage: String
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.largeTitle)
            Text(title)
                .font(.subheadline)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    EmptyStateView(systemImage: "tray", title: "Пока нет трат")
        .preferredColorScheme(.dark)
}
