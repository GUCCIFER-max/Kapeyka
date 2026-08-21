import SwiftUI
import CoreData

struct TemplateFormView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let category: Category
    let template: Template?

    @State private var label: String
    @State private var amountText: String

    init(category: Category, template: Template?) {
        self.category = category
        self.template = template
        _label = State(initialValue: template?.label ?? "")
        _amountText = State(initialValue: template.map { NSDecimalNumber(decimal: $0.amount).stringValue } ?? "")
    }

    private var parsedAmount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US"))
    }

    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty && (parsedAmount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название", text: $label)
                TextField("Сумма", text: $amountText)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle(template == nil ? "Новый шаблон" : "Шаблон")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        Haptics.success()
                        save()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        let target = template ?? Template(context: context)
        if template == nil {
            target.id = UUID()
            target.category = category
        }
        target.label = label.trimmingCharacters(in: .whitespaces)
        target.amount = amount
        try? context.save()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let category = Category(context: context)
    category.id = UUID()
    category.name = "Кофе"
    category.letter = "Ко"
    category.hue = 50

    return TemplateFormView(category: category, template: nil)
        .environment(\.managedObjectContext, context)
}
