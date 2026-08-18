import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(sortDescriptors: [])
    private var settingsResults: FetchedResults<Settings>

    @State private var budgetText: String = ""

    private var settings: Settings? { settingsResults.first }

    var body: some View {
        NavigationStack {
            Form {
                if let settings {
                    Section("Валюта") {
                        Picker("Валюта", selection: currencyBinding(for: settings)) {
                            Text("UZS").tag("UZS")
                            Text("USD").tag("USD")
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Месячный бюджет") {
                        TextField("0", text: $budgetText)
                            .keyboardType(.decimalPad)
                            .onChange(of: budgetText) { newValue in
                                updateBudget(newValue, on: settings)
                            }
                    }

                    Section("Уведомления") {
                        Toggle("Напоминания о бюджете", isOn: notificationsBinding(for: settings))
                    }

                    Section("Данные") {
                        HStack {
                            Text("Экспорт в CSV")
                            Spacer()
                            Text("v2")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Профиль")
            .onAppear {
                if let settings {
                    budgetText = NSDecimalNumber(decimal: settings.monthlyBudget).stringValue
                }
            }
        }
    }

    private func currencyBinding(for settings: Settings) -> Binding<String> {
        Binding(
            get: { settings.defaultCurrency ?? "UZS" },
            set: { newValue in
                settings.defaultCurrency = newValue
                try? context.save()
            }
        )
    }

    private func notificationsBinding(for settings: Settings) -> Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled },
            set: { newValue in
                settings.notificationsEnabled = newValue
                try? context.save()
            }
        )
    }

    private func updateBudget(_ text: String, on settings: Settings) {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: normalized, locale: Locale(identifier: "en_US")) else { return }
        settings.monthlyBudget = amount
        try? context.save()
    }
}

#Preview {
    ProfileView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
