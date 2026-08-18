import SwiftUI
import CoreData

struct QuickAddView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)])
    private var categories: FetchedResults<Category>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Template.label, ascending: true)])
    private var templates: FetchedResults<Template>

    @FetchRequest(sortDescriptors: [])
    private var settingsResults: FetchedResults<Settings>

    @StateObject private var viewModel: QuickAddViewModel
    @FocusState private var isAmountFocused: Bool

    private let editingExpense: Expense?

    init(editingExpense: Expense? = nil) {
        self.editingExpense = editingExpense
        _viewModel = StateObject(wrappedValue: QuickAddViewModel(editing: editingExpense))
    }

    private var currencyCode: String { settingsResults.first?.defaultCurrency ?? "UZS" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if editingExpense == nil, !templates.isEmpty {
                    TemplateRow(templates: Array(templates)) { template in
                        if viewModel.saveInstantly(template: template, in: context, currencyCode: currencyCode) {
                            Haptics.success()
                            dismiss()
                        }
                    }
                }

                TextField("0", text: $viewModel.amountText)
                    .keyboardType(.decimalPad)
                    .focused($isAmountFocused)
                    .font(.sum(56))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                CategoryPickerRow(
                    categories: Array(categories),
                    selectedCategoryID: $viewModel.selectedCategoryID
                )

                TextField("Комментарий (необязательно)", text: $viewModel.note)
                    .textFieldStyle(.roundedBorder)

                Spacer()
            }
            .padding()
            .navigationTitle(editingExpense == nil ? "Добавить трату" : "Редактировать трату")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        guard let categoryID = viewModel.selectedCategoryID,
                              let category = categories.first(where: { $0.id == categoryID }) else { return }
                        if viewModel.save(in: context, category: category, currencyCode: currencyCode) {
                            Haptics.success()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onAppear { isAmountFocused = true }
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
