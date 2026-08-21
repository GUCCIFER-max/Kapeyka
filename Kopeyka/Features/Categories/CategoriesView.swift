import SwiftUI
import CoreData

struct CategoriesView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var categories: FetchedResults<Category>

    @FetchRequest(sortDescriptors: [], predicate: CategoriesView.currentMonthPredicate())
    private var monthExpenses: FetchedResults<Expense>

    @FetchRequest(sortDescriptors: [])
    private var settingsResults: FetchedResults<Settings>

    @State private var isAddingCategory = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]

    private var currencyCode: String { settingsResults.first?.defaultCurrency ?? "UZS" }

    private func totalSpent(for category: Category) -> Decimal {
        monthExpenses
            .filter { $0.category?.id == category.id }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(categories, id: \.id) { category in
                        NavigationLink {
                            CategoryDetailView(category: category)
                        } label: {
                            CategoryTileView(
                                category: category,
                                spent: totalSpent(for: category),
                                currencyCode: currencyCode
                            )
                        }
                        .pressScale()
                    }

                    Button {
                        isAddingCategory = true
                    } label: {
                        AddCategoryTileView()
                    }
                    .pressScale()
                }
                .padding()
            }
            .navigationTitle("Категории")
            .sheet(isPresented: $isAddingCategory) {
                CategoryFormView(existingCount: categories.count)
            }
        }
    }

    private static func currentMonthPredicate() -> NSPredicate {
        let start = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return NSPredicate(format: "date >= %@", start as NSDate)
    }
}

private struct CategoryTileView: View {
    let category: Category
    let spent: Decimal
    let currencyCode: String

    var body: some View {
        VStack(spacing: 8) {
            CategoryAvatarView(letter: category.letter ?? "?", hue: category.hue, size: 56)
            Text(category.name ?? "")
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Text(CurrencyFormatter.string(spent, currencyCode: currencyCode))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct AddCategoryTileView: View {
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                .frame(width: 56, height: 56)
                .overlay(Image(systemName: "plus").foregroundStyle(.secondary))
            Text("Своя категория")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

#Preview {
    CategoriesView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
