import Foundation
import CoreData

final class QuickAddViewModel: ObservableObject {
    @Published var amountText: String
    @Published var selectedCategoryID: UUID?
    @Published var note: String

    private let editingExpense: Expense?

    init(editing expense: Expense? = nil) {
        editingExpense = expense
        amountText = expense.map { NSDecimalNumber(decimal: $0.amount).stringValue } ?? ""
        selectedCategoryID = expense?.category?.id
        note = expense?.note ?? ""
    }

    var canSave: Bool {
        selectedCategoryID != nil && parsedAmount != nil
    }

    private var parsedAmount: Decimal? {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: normalized, locale: Locale(identifier: "en_US")), amount > 0 else {
            return nil
        }
        return amount
    }

    @discardableResult
    func save(in context: NSManagedObjectContext, category: Category, currencyCode: String) -> Bool {
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
