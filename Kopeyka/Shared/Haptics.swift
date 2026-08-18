import UIKit

/// ТЗ 4.1: "Вибрация и лёгкая анимация вместо диалогов «Вы уверены?»" — every
/// destructive or confirming action gets a tap of feedback instead of an alert.
enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
