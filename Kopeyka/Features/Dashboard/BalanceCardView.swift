import SwiftUI

struct BalanceCardView: View {
    let balance: Decimal
    let income: Decimal
    let expenses: Decimal
    let debt: Decimal
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(CurrencyFormatter.string(balance, currencyCode: currencyCode))
                .font(.sum(34))
                .foregroundStyle(balance < 0 ? .red : .primary)

            Text("Баланс")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Text("Доход: \(CurrencyFormatter.string(income, currencyCode: currencyCode))")
                Spacer()
                Text("Расход: \(CurrencyFormatter.string(expenses, currencyCode: currencyCode))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if debt > 0 {
                Text("Из них в долг: \(CurrencyFormatter.string(debt, currencyCode: currencyCode))")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    BalanceCardView(balance: 649_000, income: 1_500_000, expenses: 851_000, debt: 300_000, currencyCode: "UZS")
        .padding()
        .preferredColorScheme(.dark)
}
