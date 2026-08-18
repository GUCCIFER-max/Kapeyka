import SwiftUI

/// Letter avatar standing in for a category icon (ТЗ 4.1), colored purely
/// from its stored `hue` via `CategoryPalette`.
struct CategoryAvatarView: View {
    let letter: String
    let hue: Double
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(CategoryPalette.color(forHue: hue))
            .frame(width: size, height: size)
            .overlay(
                Text(letter)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.75))
            )
    }
}

#Preview {
    HStack {
        ForEach(CategoryPalette.defaultCategories, id: \.name) { seed in
            CategoryAvatarView(letter: seed.letter, hue: seed.hue)
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}
