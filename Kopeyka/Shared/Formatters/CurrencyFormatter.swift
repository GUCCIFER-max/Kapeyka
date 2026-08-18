import Foundation

enum CurrencyFormatter {
    static func string(_ amount: Decimal, currencyCode: String) -> String {
        amount.formatted(.currency(code: currencyCode))
    }
}
