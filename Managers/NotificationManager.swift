import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationManager: ObservableObject {

    enum AuthStatus {
        case notDetermined
        case denied
        case authorized
        case provisional
        case ephemeral

        var isEnabled: Bool {
            switch self {
            case .authorized, .provisional, .ephemeral:
                return true
            default:
                return false
            }
        }

        // optional: можно использовать в UI
        var statusTextKey: String {
            switch self {
            case .notDetermined: return "notif_status_not_determined"
            case .denied: return "notif_status_denied"
            case .authorized: return "notif_status_authorized"
            case .provisional: return "notif_status_provisional"
            case .ephemeral: return "notif_status_ephemeral"
            }
        }
    }

    @Published private(set) var status: AuthStatus = .notDetermined

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: status = .notDetermined
        case .denied: status = .denied
        case .authorized: status = .authorized
        case .provisional: status = .provisional
        case .ephemeral: status = .ephemeral
        @unknown default:
            status = .notDetermined
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await refreshStatus()
            return granted
        } catch {
            await refreshStatus()
            return false
        }
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
