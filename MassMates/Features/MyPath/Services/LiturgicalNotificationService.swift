import Foundation
import UserNotifications

@MainActor
protocol LiturgicalNotificationScheduling: Sendable {
    func requestAuthorization() async -> Bool
    func syncReminderSchedule(_ reminder: LiturgicalReminderItem) async
    func cancelReminder(id: String)
}

@MainActor
final class LocalLiturgicalNotificationService: LiturgicalNotificationScheduling {
    // MARK: - Dependencies & State
    private let center: UNUserNotificationCenter

    // MARK: - Init
    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    // MARK: - Body / Public API
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func syncReminderSchedule(_ reminder: LiturgicalReminderItem) async {
        if reminder.isEnabled {
            let granted = await requestAuthorization()
            guard granted else { return }
            await scheduleNotification(for: reminder)
        } else {
            cancelReminder(id: reminder.id)
        }
    }

    func cancelReminder(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Subviews / Private Helpers
    private func scheduleNotification(for reminder: LiturgicalReminderItem) async {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.subtitle
        content.sound = .default

        let components = timeComponents(from: reminder.timeLabel)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func timeComponents(from timeLabel: String) -> DateComponents {
        let parts = timeLabel.split(separator: ":").compactMap { Int($0) }
        var components = DateComponents()
        components.hour = parts.first ?? 8
        components.minute = parts.count > 1 ? parts[1] : 0
        return components
    }
}
