import SwiftUI
import CoreData

struct QuickAddView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var categories: FetchedResults<Category>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "label", ascending: true)])
    private var templates: FetchedResults<Template>

    @FetchRequest(sortDescriptors: [])
    private var settingsResults: FetchedResults<Settings>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)],
        predicate: NSPredicate(format: "isDebt == YES")
    )
    private var allDebts: FetchedResults<Income>

    @StateObject private var viewModel: QuickAddViewModel
    @FocusState private var isAmountFocused: Bool

    private let editingExpense: Expense?
    private let editingIncome: Income?

    init(editingExpense: Expense? = nil, editingIncome: Income? = nil) {
        self.editingExpense = editingExpense
        self.editingIncome = editingIncome
        _viewModel = StateObject(wrappedValue: QuickAddViewModel(editingExpense: editingExpense, editingIncome: editingIncome))
    }

    private var isEditing: Bool { editingExpense != nil || editingIncome != nil }

    private var title: String {
        if editingExpense != nil { return "Редактировать трату" }
        if editingIncome != nil { return "Редактировать доход" }
        return viewModel.mode == .expense ? "Добавить трату" : "Добавить доход"
    }

    private var currencyCode: String { settingsResults.first?.defaultCurrency ?? "UZS" }

    private var unsettledDebts: [Income] {
        allDebts.filter { !$0.isSettled || $0.id == viewModel.repaidDebtID }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if !isEditing {
                    Picker("", selection: $viewModel.mode) {
                        ForEach(EntryMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if viewModel.mode == .expense, !isEditing, !templates.isEmpty {
                    TemplateRow(templates: Array(templates)) { template in
                        if viewModel.saveInstantly(template: template, in: context, currencyCode: currencyCode) {
                            Haptics.success()
                            dismiss()
                        }
                    }
                }

                AmountField(rawValue: $viewModel.amountText)
                    .focused($isAmountFocused)

                if viewModel.mode == .expense {
                    CategoryPickerRow(
                        categories: Array(categories),
                        selectedCategoryID: $viewModel.selectedCategoryID
                    )

                    if !unsettledDebts.isEmpty {
                        Toggle("Это погашение долга", isOn: $viewModel.isRepayingDebt.animation())
                            .onChange(of: viewModel.isRepayingDebt) { isOn in
                                if !isOn { viewModel.repaidDebtID = nil }
                            }

                        if viewModel.isRepayingDebt {
                            Picker("Долг", selection: $viewModel.repaidDebtID) {
                                Text("Выберите долг").tag(UUID?.none)
                                ForEach(unsettledDebts, id: \.id) { debt in
                                    Text("\(debt.source ?? "Долг") — осталось \(CurrencyFormatter.string(debt.remainingDebt, currencyCode: debt.currency ?? "UZS"))")
                                        .tag(debt.id)
                                }
                            }
                        }
                    }

                    TextField("Комментарий (необязательно)", text: $viewModel.note)
                        .textFieldStyle(.roundedBorder)
                } else {
                    TextField(
                        viewModel.isDebt ? "Откуда долг (Uzum, Tez, у Азиза...)" : "Источник (зарплата, перевод...)",
                        text: $viewModel.source
                    )
                    .textFieldStyle(.roundedBorder)

                    Toggle("Это долг (нужно будет вернуть)", isOn: $viewModel.isDebt)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        save()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onAppear { isAmountFocused = true }
        }
    }

    private func save() {
        switch viewModel.mode {
        case .expense:
            let category = viewModel.selectedCategoryID.flatMap { id in
                categories.first(where: { $0.id == id })
            }
            let repaidDebt = viewModel.isRepayingDebt
                ? viewModel.repaidDebtID.flatMap { id in unsettledDebts.first(where: { $0.id == id }) }
                : nil
            if viewModel.saveExpense(in: context, category: category, repaidDebt: repaidDebt, currencyCode: currencyCode) {
                Haptics.success()
                dismiss()
            }
        case .income:
            if viewModel.saveIncome(in: context, currencyCode: currencyCode) {
                Haptics.success()
                dismiss()
            }
        }
    }
}

private struct TemplateRow: View {
    let templates: [Template]
    let onTap: (Template) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(templates, id: \.id) { template in
                    Button {
                        onTap(template)
                    } label: {
                        VStack(spacing: 4) {
                            CategoryAvatarView(
                                letter: template.category?.letter ?? "?",
                                hue: template.category?.hue ?? 0,
                                size: 44
                            )
                            Text(template.label ?? "")
                                .font(.caption)
                        }
                    }
                    .pressScale()
                }
            }
        }
    }
}

private struct CategoryPickerRow: View {
    let categories: [Category]
    @Binding var selectedCategoryID: UUID?

    private let columns = [GridItem(.adaptive(minimum: 64))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(categories, id: \.id) { category in
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategoryID = category.id
                    }
                } label: {
                    VStack(spacing: 4) {
                        CategoryAvatarView(letter: category.letter ?? "?", hue: category.hue, size: 52)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.accent, lineWidth: selectedCategoryID == category.id ? 3 : 0)
                            )
                            .scaleEffect(selectedCategoryID == category.id ? 1.08 : 1)
                        Text(category.name ?? "")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
                .pressScale()
            }
        }
    }
}

#Preview {
    QuickAddView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
