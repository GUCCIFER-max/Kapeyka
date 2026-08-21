import SwiftUI
import CoreData

struct DebtsListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)],
        predicate: NSPredicate(format: "isDebt == YES")
    )
    private var debts: FetchedResults<Income>

    private var active: [Income] { debts.filter { !$0.isSettled } }
    private var settled: [Income] { debts.filter { $0.isSettled } }

    var body: some View {
        List {
            if debts.isEmpty {
                EmptyStateView(systemImage: "creditcard", title: "Долгов нет")
            } else {
                if !active.isEmpty {
                    Section("Активные") {
                        ForEach(active, id: \.id) { debt in
                            DebtRowView(debt: debt)
                        }
                    }
                }
                if !settled.isEmpty {
                    Section("Закрытые") {
                        ForEach(settled, id: \.id) { debt in
                            DebtRowView(debt: debt)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Долги")
    }
}

private struct DebtRowView: View {
    @ObservedObject var debt: Income

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(debt.source ?? "Долг")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(RelativeDateFormatter.string(debt.date ?? Date()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: debt.repaymentProgress)
                .tint(debt.isSettled ? .green : AppTheme.accent)

            Text(
                debt.isSettled
                    ? "Погашено"
                    : "Осталось: \(CurrencyFormatter.string(debt.remainingDebt, currencyCode: debt.currency ?? "UZS"))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        DebtsListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
