import SwiftUI

/// The "лёгкая анимация" half of ТЗ 4.1 — every tappable tile/chip/button in
/// the app compresses slightly on press instead of sitting static.
struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func pressScale(_ scale: CGFloat = 0.94) -> some View {
        buttonStyle(PressScaleButtonStyle(scale: scale))
    }
}
