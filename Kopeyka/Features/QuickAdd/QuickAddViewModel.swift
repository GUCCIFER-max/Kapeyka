import Foundation
import Combine
import CoreData

enum EntryMode: String, CaseIterable, Identifiable {
    case expense = "Трата"
    case income = "Доход"

    var id: String { rawValue }
}

final class QuickAddViewModel: ObservableObject {
    @Published var mode: EntryMode
    @Published var amountText: String
    @Published var selectedCategoryID: UUID?
    @Published var note: String
    @Published var source: String
    @Published var isDebt: Bool

    private let editingExpense: Expense?
    private let editingIncome: Income?

    init(editingExpense: Expense? = nil, editingIncome: Income? = nil) {
        self.editingExpense = editingExpense
        self.editingIncome = editingIncome

        if let editingIncome {
            mode = .income
            amountText = NSDecimalNumber(decimal: editingIncome.amount).stringValue
            source = editingIncome.source ?? ""
            isDebt = editingIncome.isDebt
            selectedCategoryID = nil
            note = ""
        } else if let editingExpense {
            mode = .expense
            amountText = NSDecimalNumber(decimal: editingExpense.amount).stringValue
            selectedCategoryID = editingExpense.category?.id
            note = editingExpense.note ?? ""
            source = ""
            isDebt = false
        } else {
            mode = .expense
            amountText = ""
            selectedCategoryID = nil
            note = ""
            source = ""
            isDebt = false
        }
    }

    var canSave: Bool {
        guard parsedAmount != nil else { return false }
        switch mode {
        case .expense:
            return selectedCategoryID != nil
        case .income:
            return !source.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private var parsedAmount: Decimal? {
        guard let amount = Decimal(string: amountText, locale: Locale(identifier: "en_US")), amount > 0 else {
            return nil
        }
        return amount
    }

    @discardableResult
    func saveExpense(in context: NSManagedObjectContext, category: Category, currencyCode: String) -> Bool {
        guard let amount = parsedAmount else { return false }

        let expense = editingExpense ?? Expense(context: context)
        if editingExpense == nil {
            expense.id = UUID()
            expense.date = Date()
            expense.currency = currencyCode
        }
        expense.amount = amount
        expense.category = category
        expense.note = note.isEmpty ? nil : note

        return (try? context.save()) != nil
    }

    @discardableResult
    func saveIncome(in context: NSManagedObjectContext, currencyCode: String) -> Bool {
        guard let amount = parsedAmount else { return false }

        let income = editingIncome ?? Income(context: context)
        if editingIncome == nil {
            income.id = UUID()
            income.date = Date()
            income.currency = currencyCode
        }
        income.amount = amount
        income.source = source.trimmingCharacters(in: .whitespaces)
        income.isDebt = isDebt

        return (try? context.save()) != nil
    }

    /// Records an expense straight from a template — no keyboard involved.
    @discardableResult
    func saveInstantly(template: Template, in context: NSManagedObjectContext, currencyCode: String) -> Bool {
        guard let category = template.category else { return false }

        let expense = Expense(context: context)
        expense.id = UUID()
        expense.amount = template.amount
        expense.currency = currencyCode
        expense.date = Date()
        expense.category = category
        expense.note = (template.label?.isEmpty ?? true) ? nil : template.label

        return (try? context.save()) != nil
    }
}
