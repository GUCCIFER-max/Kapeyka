import Foundation

/// "Сегодня, 14:32" / "Вчера, 09:15" / "3 авг, 18:20" — deterministic, not
/// tied to device locale (same reasoning as CurrencyFormatter).
enum RelativeDateFormatter {
    static func string(_ date: Date) -> String {
        let calendar = Calendar.current
        let time = timeString(date)

        if calendar.isDateInToday(date) {
            return "Сегодня, \(time)"
        }
        if calendar.isDateInYesterday(date) {
            return "Вчера, \(time)"
        }

        let day = calendar.component(.day, from: date)
        let month = monthAbbreviations[calendar.component(.month, from: date) - 1]
        return "\(day) \(month), \(time)"
    }

    private static func timeString(_ date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return String(format: "%02d:%02d", hour, minute)
    }

    private static let monthAbbreviations = [
        "янв", "фев", "мар", "апр", "мая", "июн",
        "июл", "авг", "сен", "окт", "ноя", "дек"
    ]
}
