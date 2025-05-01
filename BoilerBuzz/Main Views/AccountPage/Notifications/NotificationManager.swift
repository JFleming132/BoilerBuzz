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

    /// Schedule a local notification 30 minutes before the event date.
    func scheduleEventReminder(eventID: String, eventDate: Date) {
        // Compute reminder date
        guard let reminderDate = Calendar.current.date(byAdding: .minute, value: -30, to: eventDate),
              reminderDate > Date() else {
            print("Reminder date is in the past or invalid for event \(eventID)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Event Reminder (30 Minutes)"
        content.body = "Your event starts at " +
                       DateFormatter.localizedString(from: eventDate, dateStyle: .short, timeStyle: .short)
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let identifier = "reminder_\(eventID)"
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error.localizedDescription)")
            } else {
                print("Scheduled reminder (ID: \(identifier)) at \(reminderDate)")

                DispatchQueue.main.async {
                    self.addNotification(title: content.title,
                                         message: content.body)
                }
            }
        }
    }

    /// Cancel any pending reminder for the given event.
    func cancelEventReminder(eventID: String) {
        let identifier = "reminder_\(eventID)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled reminder (ID: \(identifier))")
    }

}

struct NotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let date: Date
    var isRead: Bool = false
}
