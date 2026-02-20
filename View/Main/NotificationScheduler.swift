import Foundation
import UserNotifications

enum TaskNotificationLead: String, CaseIterable {
    case min30 = "m30"
    case min5  = "m5"
    case start = "start"

    var minutesBefore: Int {
        switch self {
        case .min30: return 30
        case .min5:  return 5
        case .start: return 0
        }
    }
}

@MainActor
final class NotificationScheduler {

    static let shared = NotificationScheduler()
    private init() {}

    // MARK: - Permission

    func ensurePermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true

        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                print("❌ requestAuthorization error:", error)
                return false
            }

        case .denied:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - IDs

    func notificationId(userId: String, taskId: UUID, lead: TaskNotificationLead) -> String {
        "u_\(userId)_task_\(taskId.uuidString)_\(lead.rawValue)"
    }

    func cancelAll(for taskId: UUID, userId: String) {
        let ids = TaskNotificationLead.allCases.map { notificationId(userId: userId, taskId: taskId, lead: $0) }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    // MARK: - Schedule ONE notification (за N минут)

    func scheduleOne(
        userId: String,
        taskId: UUID,
        taskTitle: String,
        startDate: Date,
        leadMinutes: Int
    ) async {
        let hasPermission = await ensurePermission()
        guard hasPermission else {
            print("❌ Notifications: NO PERMISSION")
            return
        }

        let center = UNUserNotificationCenter.current()

        // Удаляем старые уведомления этой задачи
        cancelAll(for: taskId, userId: userId)

        let fireDate = Calendar.current.date(byAdding: .minute, value: -leadMinutes, to: startDate) ?? startDate
        let delta = fireDate.timeIntervalSinceNow
        guard delta > 2 else { return }

        let content = UNMutableNotificationContent()
        content.title = leadMinutes == 0 ? "It's time" : "In \(leadMinutes) minutes"
        content.body = taskTitle
        content.sound = .default

        // Если скоро — TimeInterval стабильнее
        let trigger: UNNotificationTrigger
        if delta < 3600 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delta, repeats: false)
        } else {
            var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            comps.second = 0
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: notificationId(userId: userId, taskId: taskId, lead: .start),
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("✅ scheduled:", request.identifier)
        } catch {
            print("❌ schedule error:", error.localizedDescription)
        }
    }

    // MARK: - HARD TEST (можешь потом удалить)

    func hardTestIn15Seconds() async {
        print("🧪 HARD TEST START")
        let hasPermission = await ensurePermission()
        print("🧪 permission:", hasPermission)
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "HARD TEST"
        content.body = "If you see this — notifications WORK"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)

        do {
            try await UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: "hard_test_15s", content: content, trigger: trigger)
            )
            print("✅ HARD TEST SCHEDULED")
        } catch {
            print("❌ HARD TEST ERROR:", error.localizedDescription)
        }
    }
}
