import Foundation
import UserNotifications

@Observable
final class NotificationService {
    static let shared = NotificationService()

    var isAuthorized: Bool = false

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    /// Schedules a recurring weekday workout reminder at a given hour/minute.
    /// `weekdays` follows DateComponents convention: 1 = Sunday, 2 = Monday, ..., 7 = Saturday.
    func scheduleWorkoutReminders(weekdays: Set<Int>, hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        // Clear previous workout reminders
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending.filter { $0.identifier.hasPrefix("workoutReminder.") }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: toRemove)

        guard !weekdays.isEmpty else { return }

        for day in weekdays {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.weekday = day

            let content = UNMutableNotificationContent()
            content.title = "Prêt à soulever ?"
            content.body = "C'est l'heure de ta séance — go go go 💪"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "workoutReminder.\(day)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancelAllWorkoutReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending.filter { $0.identifier.hasPrefix("workoutReminder.") }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: toRemove)
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }
}
