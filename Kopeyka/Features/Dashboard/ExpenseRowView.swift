import SwiftUI
import CoreData

struct ExpenseRowView: View {
    @ObservedObject var expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            CategoryAvatarView(
                letter: expense.category?.letter ?? "?",
                hue: expense.category?.hue ?? 0,
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category?.name ?? "Без категории")
                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(CurrencyFormatter.string(expense.amount, currencyCode: expense.currency ?? "UZS"))
                .font(.sum(17))
        }
        .padding(.vertical, 4)
    }
}
