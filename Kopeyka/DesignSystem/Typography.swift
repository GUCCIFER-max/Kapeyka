import SwiftUI

extension Font {
    /// Serif (New York), reserved for prominent money amounts — ТЗ 4.1.
    static func sum(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
