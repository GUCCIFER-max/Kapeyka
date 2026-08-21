import SwiftUI
import CoreData

private struct LedgerEntry: Identifiable {
    enum Kind {
        case expense(Expense)
        case income(Income)
    }

    let kind: Kind
    let id: UUID
    let date: Date
}

/// Also doubles as the "История" screen from ТЗ 3.1 #4 — search, category
/// filter, edit and delete all live in this feed since the ТЗ's own screen
/// list (§4.2) has no separate History screen. Now a unified ledger: every
/// expense and every income entry, since the balance is running, not a
/// monthly reset.
struct DashboardView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var categories: FetchedResults<Category>

    @FetchRequest(sortDescriptors: [])
    private var settingsResults: FetchedResults<Settings>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)])
    private var allExpenses: FetchedResults<Expense>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)])
    private var allIncomes: FetchedResults<Income>

    @State private var selectedCategoryID: UUID?
    @State private var searchText = ""
    @State private var isEditingEntry = false
    @State private var expenseBeingEdited: Expense?
    @State private var incomeBeingEdited: Income?

    private var settings: Settings? { settingsResults.first }
    private var currencyCode: String { settings?.defaultCurrency ?? "UZS" }

    private var incomeTotal: Decimal {
        allIncomes.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var expenseTotal: Decimal {
        allExpenses.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var debtTotal: Decimal {
        allIncomes.filter(\.isDebt).reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var ledgerEntries: [LedgerEntry] {
        let expenseEntries: [LedgerEntry] = allExpenses.compactMap { expense in
            guard let id = expense.id, let date = expense.date else { return nil }
            guard selectedCategoryID == nil || expense.category?.id == selectedCategoryID else { return nil }
            let matchesSearch = searchText.isEmpty
                || (expense.note ?? "").localizedCaseInsensitiveContains(searchText)
                || (expense.category?.name ?? "").localizedCaseInsensitiveContains(searchText)
            guard matchesSearch else { return nil }
            return LedgerEntry(kind: .expense(expense), id: id, date: date)
        }

        let incomeEntries: [LedgerEntry] = allIncomes.compactMap { income in
            guard let id = income.id, let date = income.date else { return nil }
            guard selectedCategoryID == nil else { return nil }
            let matchesSearch = searchText.isEmpty || (income.source ?? "").localizedCaseInsensitiveContains(searchText)
            guard matchesSearch else { return nil }
            return LedgerEntry(kind: .income(income), id: id, date: date)
        }

        return (expenseEntries + incomeEntries).sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BalanceCardView(
                        balance: incomeTotal - expenseTotal,
                        income: incomeTotal,
                        expenses: expenseTotal,
                        debt: debtTotal,
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
                    if ledgerEntries.isEmpty {
                        EmptyStateView(systemImage: "tray", title: "Ничего не найдено")
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(ledgerEntries) { entry in
                            row(for: entry)
                                .contentShape(Rectangle())
                                .onTapGesture { edit(entry) }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(entry)
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
            .sheet(isPresented: $isEditingEntry) {
                if let expenseBeingEdited {
                    QuickAddView(editingExpense: expenseBeingEdited)
                } else if let incomeBeingEdited {
                    QuickAddView(editingIncome: incomeBeingEdited)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for entry: LedgerEntry) -> some View {
        switch entry.kind {
        case .expense(let expense):
            ExpenseRowView(expense: expense)
        case .income(let income):
            IncomeRowView(income: income, currencyCode: currencyCode)
        }
    }

    private func edit(_ entry: LedgerEntry) {
        switch entry.kind {
        case .expense(let expense):
            expenseBeingEdited = expense
            incomeBeingEdited = nil
        case .income(let income):
            incomeBeingEdited = income
            expenseBeingEdited = nil
        }
        isEditingEntry = true
    }

    private func delete(_ entry: LedgerEntry) {
        Haptics.warning()
        switch entry.kind {
        case .expense(let expense):
            context.delete(expense)
        case .income(let income):
            context.delete(income)
        }
        try? context.save()
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
