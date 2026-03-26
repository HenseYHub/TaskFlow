import Foundation
import UserNotifications

enum TaskNotificationLead: String, CaseIterable {
    case min30 = "m30"
    case min5 = "m5"
    case start = "start"

    var minutesBefore: Int {
        switch self {
        case .min30: return 30
        case .min5: return 5
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
                #if DEBUG
                print("requestAuthorization error:", error)
                #endif
                return false
            }

        case .denied:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Identifiers

    func notificationId(userId: String, taskId: UUID, lead: TaskNotificationLead) -> String {
        "u_\(userId)_task_\(taskId.uuidString)_\(lead.rawValue)"
    }

    func cancelAll(for taskId: UUID, userId: String) {
        let ids = TaskNotificationLead.allCases.map {
            notificationId(userId: userId, taskId: taskId, lead: $0)
        }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    // MARK: - Schedule one notification

    func scheduleOne(
        userId: String,
        taskId: UUID,
        taskTitle: String,
        startDate: Date,
        leadMinutes: Int
    ) async {
        let hasPermission = await ensurePermission()
        guard hasPermission else {
            #if DEBUG
            print("Notifications: no permission")
            #endif
            return
        }

        let center = UNUserNotificationCenter.current()

        cancelAll(for: taskId, userId: userId)

        let fireDate = Calendar.current.date(byAdding: .minute, value: -leadMinutes, to: startDate) ?? startDate
        let delta = fireDate.timeIntervalSinceNow
        guard delta > 2 else { return }

        let content = UNMutableNotificationContent()
        content.title = leadMinutes == 0 ? "It's time" : "In \(leadMinutes) minutes"
        content.body = taskTitle
        content.sound = .default

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
            #if DEBUG
            print("Scheduled notification:", request.identifier)
            #endif
        } catch {
            #if DEBUG
            print("Schedule error:", error.localizedDescription)
            #endif
        }
    }
}
