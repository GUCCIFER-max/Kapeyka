import SwiftUI
import CoreData

struct CategoryDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var category: Category

    @FetchRequest private var templates: FetchedResults<Template>
    @FetchRequest private var expenses: FetchedResults<Expense>

    @FetchRequest(sortDescriptors: [])
    private var settingsResults: FetchedResults<Settings>

    @State private var isAddingTemplate = false
    @State private var isEditingTemplate = false
    @State private var selectedTemplate: Template?

    init(category: Category) {
        self.category = category
        let categoryID = category.id ?? UUID()

        let templateRequest: NSFetchRequest<Template> = Template.fetchRequest()
        templateRequest.predicate = NSPredicate(format: "category.id == %@", categoryID as CVarArg)
        templateRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Template.label, ascending: true)]
        _templates = FetchRequest(fetchRequest: templateRequest)

        let expenseRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        expenseRequest.predicate = NSPredicate(format: "category.id == %@", categoryID as CVarArg)
        expenseRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.date, ascending: false)]
        _expenses = FetchRequest(fetchRequest: expenseRequest)
    }

    private var currencyCode: String { settingsResults.first?.defaultCurrency ?? "UZS" }

    private var totalSpent: Decimal {
        expenses.reduce(Decimal(0)) { $0 + $1.amount }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    CategoryAvatarView(letter: category.letter ?? "?", hue: category.hue, size: 64)
                    Text(CurrencyFormatter.string(totalSpent, currencyCode: currencyCode))
                        .font(.sum(28))
                    Text("всего потрачено")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }

            Section("Шаблоны") {
                ForEach(templates, id: \.id) { template in
                    Button {
                        selectedTemplate = template
                        isEditingTemplate = true
                    } label: {
                        HStack {
                            Text(template.label ?? "")
                            Spacer()
                            Text(CurrencyFormatter.string(template.amount, currencyCode: currencyCode))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .pressScale()
                }
                .onDelete(perform: deleteTemplates)

                Button {
                    isAddingTemplate = true
                } label: {
                    Label("Добавить шаблон", systemImage: "plus")
                }
            }

            Section {
                Button("Удалить категорию", role: .destructive) {
                    deleteCategory()
                }
            }
        }
        .navigationTitle(category.name ?? "Категория")
        .sheet(isPresented: $isAddingTemplate) {
            TemplateFormView(category: category, template: nil)
        }
        .sheet(isPresented: $isEditingTemplate) {
            if let selectedTemplate {
                TemplateFormView(category: category, template: selectedTemplate)
            }
        }
    }

    private func deleteTemplates(at offsets: IndexSet) {
        Haptics.warning()
        for index in offsets {
            context.delete(templates[index])
        }
        try? context.save()
    }

    private func deleteCategory() {
        Haptics.warning()
        context.delete(category)
        try? context.save()
        dismiss()
    }
}
