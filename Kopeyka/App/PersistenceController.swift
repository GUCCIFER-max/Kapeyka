import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        PersistenceController(inMemory: true)
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Kopeyka")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        seedDefaultsIfNeeded()
    }

    /// Creates the default categories and the single `Settings` row on first
    /// launch only — every subsequent launch finds them already there.
    private func seedDefaultsIfNeeded() {
        let context = container.viewContext

        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.fetchLimit = 1

        let settingsRequest: NSFetchRequest<Settings> = Settings.fetchRequest()
        settingsRequest.fetchLimit = 1

        do {
            if try context.count(for: categoryRequest) == 0 {
                for seed in CategoryPalette.defaultCategories {
                    let category = Category(context: context)
                    category.id = UUID()
                    category.name = seed.name
                    category.letter = seed.letter
                    category.hue = seed.hue
                }
            }

            if try context.count(for: settingsRequest) == 0 {
                let settings = Settings(context: context)
                settings.defaultCurrency = "UZS"
                settings.monthlyBudget = 0
            }

            if context.hasChanges {
                try context.save()
            }
        } catch {
            fatalError("Failed to seed defaults: \(error)")
        }
    }
}
