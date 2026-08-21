import SwiftUI

struct BalanceCardView: View {
    struct DebtEntry: Identifiable {
        let id: UUID
        let source: String
        let amount: Decimal
    }

    let balance: Decimal
    let income: Decimal
    let expenses: Decimal
    let debts: [DebtEntry]
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

            if !debts.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(debts) { debt in
                        Text("Из них в долг (\(debt.source)): \(CurrencyFormatter.string(debt.amount, currencyCode: currencyCode))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    BalanceCardView(
        balance: 649_000,
        income: 1_500_000,
        expenses: 851_000,
        debts: [
            BalanceCardView.DebtEntry(id: UUID(), source: "Uzum", amount: 500_000),
            BalanceCardView.DebtEntry(id: UUID(), source: "Tez", amount: 500_000)
        ],
        currencyCode: "UZS"
    )
    .padding()
    .preferredColorScheme(.dark)
}
