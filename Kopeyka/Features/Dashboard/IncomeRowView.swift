import SwiftUI
import CoreData

struct IncomeRowView: View {
    @ObservedObject var income: Income

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: income.isDebt ? "arrow.down.circle" : "plus")
                        .foregroundStyle(.green)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(income.source ?? "Доход")
                Text(RelativeDateFormatter.string(income.date ?? Date()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if income.isDebt {
                    Text("Долг")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Text("+" + CurrencyFormatter.string(income.amount, currencyCode: income.currency ?? "UZS"))
                .font(.sum(17))
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}
