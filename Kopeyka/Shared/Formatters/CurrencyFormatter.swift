import Foundation

enum CurrencyFormatter {
    static func string(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let number = formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        return "\(number) \(symbol(for: currencyCode))"
    }

    private static func symbol(for currencyCode: String) -> String {
        switch currencyCode {
        case "UZS": return "сум"
        case "USD": return "$"
        default: return currencyCode
        }
    }
}
