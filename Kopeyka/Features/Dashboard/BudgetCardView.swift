import SwiftUI

struct BudgetCardView: View {
    let spent: Decimal
    let budget: Decimal
    let currencyCode: String

    private var remaining: Decimal { budget - spent }

    private var progress: Double {
        guard budget > 0 else { return 0 }
        let spentValue = NSDecimalNumber(decimal: spent).doubleValue
        let budgetValue = NSDecimalNumber(decimal: budget).doubleValue
        return min(max(spentValue / budgetValue, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(CurrencyFormatter.string(remaining, currencyCode: currencyCode))
                .font(.sum(34))
                .foregroundStyle(remaining < 0 ? .red : .primary)

            Text("Остаток из \(CurrencyFormatter.string(budget, currencyCode: currencyCode))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: progress)
                .tint(AppTheme.accent)
                .animation(.easeInOut(duration: 0.35), value: progress)

            HStack {
                Text("Потрачено: \(CurrencyFormatter.string(spent, currencyCode: currencyCode))")
                Spacer()
                Text("Бюджет: \(CurrencyFormatter.string(budget, currencyCode: currencyCode))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    BudgetCardView(spent: 850_000, budget: 1_500_000, currencyCode: "UZS")
        .padding()
        .preferredColorScheme(.dark)
}
