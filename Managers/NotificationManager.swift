//
//  NotificationManager.swift
//  TaskFlow
//
//  Created by Pavlo on 22.04.2025.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let instance = NotificationManager()

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Уведомления разрешены")
            } else {
                print("❌ Уведомления отклонены")
            }
        }
    }

    func scheduleNotification(title: String, subtitle: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func removeAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

