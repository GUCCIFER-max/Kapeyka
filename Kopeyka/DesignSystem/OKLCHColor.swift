import SwiftUI

/// SwiftUI has no native `oklch()`. This reimplements the conversion so that
/// category and accent colors stay perceptually consistent across any hue,
/// the way `oklch()` would in CSS.
enum OKLCH {

    /// Builds a `Color` from OKLCH components.
    /// - Parameters:
    ///   - lightness: 0...1
    ///   - chroma: typically 0...0.4 for sRGB-representable colors
    ///   - hue: degrees, 0...360
    static func color(lightness: Double, chroma: Double, hue: Double, opacity: Double = 1) -> Color {
        let (r, g, b) = rgb(lightness: lightness, chroma: chroma, hue: hue)
        return Color(red: r, green: g, blue: b, opacity: opacity)
    }

    /// OKLCH -> linear sRGB -> gamma-corrected sRGB, clamped to [0, 1].
    static func rgb(lightness: Double, chroma: Double, hue: Double) -> (Double, Double, Double) {
        let hueRadians = hue * .pi / 180
        let a = chroma * cos(hueRadians)
        let b = chroma * sin(hueRadians)

        // OKLab -> LMS (cube root domain)
        let l_ = lightness + 0.3963377774 * a + 0.2158037573 * b
        let m_ = lightness - 0.1055613458 * a - 0.0638541728 * b
        let s_ = lightness - 0.0894841775 * a - 1.2914855480 * b

        let l = l_ * l_ * l_
        let m = m_ * m_ * m_
        let s = s_ * s_ * s_

        // LMS -> linear sRGB
        let rLinear = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        let gLinear = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        let bLinear = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

        return (
            gammaCorrect(rLinear).clamped(),
            gammaCorrect(gLinear).clamped(),
            gammaCorrect(bLinear).clamped()
        )
    }

    private static func gammaCorrect(_ channel: Double) -> Double {
        if channel <= 0.0031308 {
            return 12.92 * channel
        }
        return 1.055 * pow(channel, 1 / 2.4) - 0.055
    }
}

private extension Double {
    func clamped() -> Double {
        min(max(self, 0), 1)
    }
}

extension Color {
    /// `Color.oklch(l: 0.75, c: 0.15, h: 145)` — mirrors CSS `oklch()`.
    static func oklch(l: Double, c: Double, h: Double, opacity: Double = 1) -> Color {
        OKLCH.color(lightness: l, chroma: c, hue: h, opacity: opacity)
    }
}
