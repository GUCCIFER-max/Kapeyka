import SwiftUI

/// Seed data for a default category, before it becomes a Core Data `Category`.
struct DefaultCategorySeed {
    let name: String
    let letter: String
    let hue: Double
}

/// Assigns and renders category colors from a single hue value, per category,
/// via `oklch()` — never picked by hand, so the palette stays consistent no
/// matter how many categories (default or user-added) exist.
enum CategoryPalette {

    // Fixed lightness/chroma tuned for readable avatar chips on the app's
    // dark background; only hue varies between categories.
    static let lightness: Double = 0.78
    static let chroma: Double = 0.13

    static func color(forHue hue: Double) -> Color {
        .oklch(l: lightness, c: chroma, h: hue)
    }

    /// Golden angle: successive hues spread maximally apart regardless of
    /// how many categories end up existing.
    static let goldenAngle: Double = 137.507764

    static func hue(forIndex index: Int, base: Double = 30) -> Double {
        (base + Double(index) * goldenAngle).truncatingRemainder(dividingBy: 360)
    }

    static let defaultCategories: [DefaultCategorySeed] = [
        DefaultCategorySeed(name: "Транспорт", letter: "Тр", hue: hue(forIndex: 0)),
        DefaultCategorySeed(name: "Еда", letter: "Ед", hue: hue(forIndex: 1)),
        DefaultCategorySeed(name: "Сигареты", letter: "Си", hue: hue(forIndex: 2)),
        DefaultCategorySeed(name: "Кофе", letter: "Ко", hue: hue(forIndex: 3)),
        DefaultCategorySeed(name: "Связь", letter: "Св", hue: hue(forIndex: 4)),
        DefaultCategorySeed(name: "Разное", letter: "Ра", hue: hue(forIndex: 5)),
    ]
}
