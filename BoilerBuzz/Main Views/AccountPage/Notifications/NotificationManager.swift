//
//  NotificationManager.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 4/1/25.
//

import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var notifications: [NotificationItem] = []

    func addNotification(title: String, message: String) {
        let newNotification = NotificationItem(title: title, message: message, date: Date(), isRead: false)
        notifications.insert(newNotification, at: 0) // Newest at top
    }
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
    }

    func clearNotifications() {
        notifications.removeAll()
    }

    func removeNotification(_ notification: NotificationItem) {
        notifications.removeAll { $0.id == notification.id }
    }

    func markAsRead(_ notification: NotificationItem) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }

}

struct NotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let date: Date
    var isRead: Bool = false
}
