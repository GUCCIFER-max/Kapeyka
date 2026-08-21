import UserNotifications

/// Daily "how much did you spend today?" reminders — local notifications,
/// so they work fully offline like the rest of the app (ТЗ §7). The app
/// never schedules anything else, so it's safe to fully replace the pending
/// set on every change rather than tracking individual identifiers.
enum NotificationManager {
    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    static func rescheduleAll(times: [Date]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for time in times {
            let content = UNMutableNotificationContent()
            content.title = "Копейка"
            content.body = "Сколько потратили сегодня?"
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let identifier = "daily-spending-reminder-\(components.hour ?? 0)-\(components.minute ?? 0)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
