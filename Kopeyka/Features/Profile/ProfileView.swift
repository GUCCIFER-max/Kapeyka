import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(sortDescriptors: [])
    private var settingsResults: FetchedResults<Settings>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "time", ascending: true)])
    private var reminderTimes: FetchedResults<ReminderTime>

    private var settings: Settings? { settingsResults.first }

    var body: some View {
        NavigationStack {
            Form {
                if let settings {
                    Section("Уведомления") {
                        Toggle("Ежедневные напоминания", isOn: notificationsBinding(for: settings))

                        if settings.notificationsEnabled {
                            ForEach(reminderTimes, id: \.id) { reminder in
                                DatePicker(
                                    "Время",
                                    selection: timeBinding(for: reminder),
                                    displayedComponents: .hourAndMinute
                                )
                            }
                            .onDelete(perform: deleteReminders)

                            Button {
                                addReminder()
                            } label: {
                                Label("Добавить время", systemImage: "plus")
                            }
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

    private func notificationsBinding(for settings: Settings) -> Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled },
            set: { newValue in
                settings.notificationsEnabled = newValue
                try? context.save()

                if newValue {
                    NotificationManager.requestAuthorization { granted in
                        guard granted else { return }
                        ensureAtLeastOneReminder()
                        rescheduleAll()
                    }
                } else {
                    NotificationManager.cancelAll()
                }
            }
        )
    }

    private func timeBinding(for reminder: ReminderTime) -> Binding<Date> {
        Binding(
            get: { reminder.time ?? Self.defaultReminderTime },
            set: { newValue in
                reminder.time = newValue
                try? context.save()
                rescheduleAll()
            }
        )
    }

    private func addReminder() {
        let reminder = ReminderTime(context: context)
        reminder.id = UUID()
        reminder.time = Self.defaultReminderTime
        try? context.save()
        rescheduleAll()
    }

    private func deleteReminders(at offsets: IndexSet) {
        for index in offsets {
            context.delete(reminderTimes[index])
        }
        try? context.save()
        rescheduleAll()
    }

    private func ensureAtLeastOneReminder() {
        guard reminderTimes.isEmpty else { return }
        addReminder()
    }

    private func rescheduleAll() {
        NotificationManager.rescheduleAll(times: reminderTimes.compactMap(\.time))
    }

    private static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

#Preview {
    ProfileView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
