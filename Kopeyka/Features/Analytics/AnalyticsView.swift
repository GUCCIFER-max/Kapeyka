import SwiftUI
import Charts
import CoreData

private enum StatsPeriod: String, CaseIterable, Identifiable {
    case day = "День"
    case week = "Неделя"
    case month = "Месяц"

    var id: String { rawValue }

    var start: Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        }
    }
}

private struct CategoryTotal: Identifiable {
    let id: UUID
    let name: String
    let letter: String
    let hue: Double
    let total: Decimal
}

struct AnalyticsView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Expense.date, ascending: false)])
    private var allExpenses: FetchedResults<Expense>

    @FetchRequest(sortDescriptors: [])
    private var settingsResults: FetchedResults<Settings>

    @State private var period: StatsPeriod = .month

    private var currencyCode: String { settingsResults.first?.defaultCurrency ?? "UZS" }

    private var periodExpenses: [Expense] {
        let start = period.start
        return allExpenses.filter { ($0.date ?? .distantPast) >= start }
    }

    private var total: Decimal {
        periodExpenses.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var categoryTotals: [CategoryTotal] {
        var totals: [UUID: CategoryTotal] = [:]
        for expense in periodExpenses {
            guard let category = expense.category, let id = category.id else { continue }
            let runningTotal = (totals[id]?.total ?? 0) + expense.amount
            totals[id] = CategoryTotal(
                id: id,
                name: category.name ?? "",
                letter: category.letter ?? "?",
                hue: category.hue,
                total: runningTotal
            )
        }
        return totals.values.sorted { $0.total > $1.total }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Период", selection: $period) {
                        ForEach(StatsPeriod.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(CurrencyFormatter.string(total, currencyCode: currencyCode))
                            .font(.sum(34))
                        Text("потрачено за период")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if categoryTotals.isEmpty {
                        EmptyStateView(systemImage: "chart.bar", title: "Нет трат за этот период")
                    } else {
                        Chart(categoryTotals) { item in
                            BarMark(
                                x: .value("Сумма", NSDecimalNumber(decimal: item.total).doubleValue),
                                y: .value("Категория", item.name)
                            )
                            .foregroundStyle(CategoryPalette.color(forHue: item.hue))
                        }
                        .frame(height: CGFloat(categoryTotals.count) * 44 + 20)

                        VStack(spacing: 0) {
                            ForEach(categoryTotals) { item in
                                HStack {
                                    CategoryAvatarView(letter: item.letter, hue: item.hue, size: 28)
                                    Text(item.name)
                                    Spacer()
                                    Text(CurrencyFormatter.string(item.total, currencyCode: currencyCode))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                                if item.id != categoryTotals.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Аналитика")
        }
    }
}

#Preview {
    AnalyticsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
