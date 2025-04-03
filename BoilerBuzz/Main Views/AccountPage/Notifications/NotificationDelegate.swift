//
//  NotificationDelegate.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 4/1/25.
//


import SwiftUI
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private var handledNotificationIDs = Set<String>()

    // This method will be called when a notification is delivered while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let id = notification.request.identifier

        if !handledNotificationIDs.contains(id) {
            NotificationCenter.default.post(name: .init("NewNotification"), object: notification)
            handledNotificationIDs.insert(id)
        }

        completionHandler([.banner, .sound])
    }

    // This method will be called when the user interacts with the notification (e.g., taps it)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = response.notification.request.identifier

        if !handledNotificationIDs.contains(id) {
            NotificationCenter.default.post(name: .init("NewNotification"), object: response.notification)
            handledNotificationIDs.insert(id)
        }

        completionHandler()
    }
}