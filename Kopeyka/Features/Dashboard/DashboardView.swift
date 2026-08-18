import SwiftUI
import CoreData

/// Also doubles as the "История" screen from ТЗ 3.1 #4 — search, category
/// filter, edit and delete all live in this feed since the ТЗ's own screen
/// list (§4.2) has no separate History screen.
struct DashboardView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)])
    private var categories: FetchedResults<Category>

    @FetchRequest(sortDescriptors: [])
    private var settingsResults: FetchedResults<Settings>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expense.date, ascending: false)],
        predicate: DashboardView.currentMonthPredicate()
    )
    private var monthExpenses: FetchedResults<Expense>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Expense.date, ascending: false)])
    private var allExpenses: FetchedResults<Expense>

    @State private var selectedCategoryID: UUID?
    @State private var searchText = ""
    @State private var isEditingExpense = false
    @State private var expenseBeingEdited: Expense?

    private var settings: Settings? { settingsResults.first }
    private var currencyCode: String { settings?.defaultCurrency ?? "UZS" }

    // Always the true month total — unaffected by the history filters below.
    private var spent: Decimal {
        monthExpenses.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var filteredExpenses: [Expense] {
        allExpenses.filter { expense in
            let matchesCategory = selectedCategoryID == nil || expense.category?.id == selectedCategoryID
            let matchesSearch = searchText.isEmpty
                || (expense.note ?? "").localizedCaseInsensitiveContains(searchText)
                || (expense.category?.name ?? "").localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BudgetCardView(
                        spent: spent,
                        budget: settings?.monthlyBudget ?? 0,
                        currencyCode: currencyCode
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    CategoryFilterRow(
                        categories: Array(categories),
                        selectedCategoryID: $selectedCategoryID
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section("История") {
                    if filteredExpenses.isEmpty {
                        EmptyStateView(systemImage: "tray", title: "Ничего не найдено")
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredExpenses, id: \.id) { expense in
                            ExpenseRowView(expense: expense)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    expenseBeingEdited = expense
                                    isEditingExpense = true
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(expense)
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Поиск по трате")
            .navigationTitle("Копейка")
            .sheet(isPresented: $isEditingExpense) {
                if let expenseBeingEdited {
                    QuickAddView(editingExpense: expenseBeingEdited)
                }
            }
        }
    }

    private func delete(_ expense: Expense) {
        Haptics.warning()
        context.delete(expense)
        try? context.save()
    }

    private static func currentMonthPredicate() -> NSPredicate {
        let start = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return NSPredicate(format: "date >= %@", start as NSDate)
    }
}

private struct CategoryFilterRow: View {
    let categories: [Category]
    @Binding var selectedCategoryID: UUID?

    private func select(_ id: UUID?) {
        Haptics.tap()
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedCategoryID = id
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Все", isSelected: selectedCategoryID == nil) {
                    select(nil)
                }
                ForEach(categories, id: \.id) { category in
                    FilterChip(title: category.name ?? "", isSelected: selectedCategoryID == category.id) {
                        select(category.id)
                    }
                }
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? AppTheme.accent : Color.secondary.opacity(0.15)))
                .foregroundStyle(isSelected ? .black : .primary)
        }
        .pressScale()
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
