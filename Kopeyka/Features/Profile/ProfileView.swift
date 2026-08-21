import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(sortDescriptors: [])
    private var settingsResults: FetchedResults<Settings>

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

                    Section("Уведомления") {
                        Toggle("Ежедневное напоминание", isOn: notificationsBinding(for: settings))

                        if settings.notificationsEnabled {
                            DatePicker(
                                "Время",
                                selection: reminderTimeBinding(for: settings),
                                displayedComponents: .hourAndMinute
                            )
                        }
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

                if newValue {
                    NotificationManager.requestAuthorization { granted in
                        if granted {
                            NotificationManager.scheduleDailyReminder(at: settings.reminderTime ?? Self.defaultReminderTime)
                        }
                    }
                } else {
                    NotificationManager.cancelDailyReminder()
                }
            }
        )
    }

    private func reminderTimeBinding(for settings: Settings) -> Binding<Date> {
        Binding(
            get: { settings.reminderTime ?? Self.defaultReminderTime },
            set: { newValue in
                settings.reminderTime = newValue
                try? context.save()
                NotificationManager.scheduleDailyReminder(at: newValue)
            }
        )
    }

    private static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

#Preview {
    ProfileView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
