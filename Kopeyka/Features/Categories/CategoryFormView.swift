import SwiftUI

/// Adding a category only asks for a name — hue is auto-assigned (ТЗ 4.1:
/// colors are never picked by hand) and the letter avatar is derived from it.
struct CategoryFormView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let existingCount: Int

    @State private var name: String = ""

    private var previewLetter: String {
        String(name.prefix(2)).uppercased()
    }

    private var previewHue: Double {
        CategoryPalette.hue(forIndex: existingCount)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                CategoryAvatarView(
                    letter: previewLetter.isEmpty ? "?" : previewLetter,
                    hue: previewHue,
                    size: 64
                )

                TextField("Название категории", text: $name)
                    .textFieldStyle(.roundedBorder)

                Spacer()
            }
            .padding()
            .navigationTitle("Новая категория")
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let category = Category(context: context)
        category.id = UUID()
        category.name = name.trimmingCharacters(in: .whitespaces)
        category.letter = previewLetter
        category.hue = previewHue
        try? context.save()
    }
}

#Preview {
    CategoryFormView(existingCount: 6)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
