//
//  SocketIOManager.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 4/3/2025.
//

import Foundation
import SocketIO
import UserNotifications

class SocketIOManager: ObservableObject {
    static let shared = SocketIOManager()
    
    private var manager: SocketManager
    private var socket: SocketIOClient
    
    private init() {
        guard let url = URL(string: "http://localhost:3000") else {
            fatalError("Invalid URL for Socket.IO server")
        }
        manager = SocketManager(socketURL: url, config: [.log(false), .compress])
        socket = manager.defaultSocket
    }
    
    /// Establishes the connection and sets up event listeners.
    func establishConnection() {
        socket.on(clientEvent: .connect) { data, ack in
            print("Socket connected: \(data)")
        }
        
        // New event posted by a friend
        socket.on("newEvent") { data, ack in
            self.handleNewEvent(data: data)
        }
        
        // Event fields updated
        socket.on("eventUpdated") { data, ack in
            self.handleEventUpdated(data: data)
        }
        
        // Event deleted/cancelled
        socket.on("eventDeleted") { data, ack in
            self.handleEventDeleted(data: data)
        }

        socket.on("drinkSpecialCreated") { data, ack in
            self.handleDrinkSpecial(data: data)
        }

        
        
        socket.on(clientEvent: .error) { data, ack in
            print("Socket encountered an error: \(data)")
        }
        
        socket.connect()
    }

    private func handleDrinkSpecial(data: [Any]) {
        // 1) unwrap payload
        guard let payload = data.first as? [String: Any],
              let title     = payload["title"]    as? String,
              let barName   = payload["barName"]  as? String else {
            return
        }
        
        // 2) check user preference
        let prefs = UserDefaults.standard
                       .dictionary(forKey: "notificationPreferences") as? [String: Any]
        let drinksOn = prefs?["drinkSpecials"] as? Bool ?? false
        guard drinksOn else { return }

        // 3) schedule the local notification
        let notifTitle = "New Drink Special!"
        let notifBody  = "\(barName) just posted “\(title)”"
        scheduleLocalNotification(title: notifTitle, message: notifBody)

    }
    
    /// Handles notifications for new events from friends.
    private func handleNewEvent(data: [Any]) {
        guard let eventData = data.first as? [String: Any],
              let authorId = eventData["author"] as? String,
              let userId = UserDefaults.standard.string(forKey: "userId"), userId != authorId,
              let prefs = UserDefaults.standard.dictionary(forKey: "notificationPreferences") as? [String: Any],
              let friendPrefs = prefs["friendPosting"] as? [String: Bool],
              friendPrefs[authorId] == true else {
            return
        }
        let title = eventData["title"] as? String ?? "New Event"
        let authorUsername = eventData["authorUsername"] as? String ?? "Someone"
        let body = "\(authorUsername) posted a new event!"
        scheduleLocalNotification(title: title, message: body)
    }
    
    /// Handles notifications when an event is updated.
    private func handleEventUpdated(data: [Any]) {
        print("Event updated data: \(data)")
        guard
        let updateData = data.first as? [String: Any],
        let eventId    = updateData["id"] as? String,
        let title      = updateData["title"] as? String,
        let summary    = updateData["summary"] as? String,

        // only if user has toggled on update notifications
        let prefs      = UserDefaults.standard.dictionary(forKey: "notificationPreferences") as? [String: Any],
        let updatesOn  = prefs["eventUpdates"] as? Bool, updatesOn,

        // and only if the user has RSVPd to this event
        let rsvpList   = UserDefaults.standard.stringArray(forKey: "rsvpEvents"),
        rsvpList.contains(eventId)
        else {
        return
        }

        // schedule it
        DispatchQueue.main.async {
        self.scheduleLocalNotification(title: title, message: summary)
        }
    }
    
    /// Handles notifications when an event is deleted/cancelled.
    private func handleEventDeleted(data: [Any]) {
        guard let deleteData = data.first as? [String: Any],
              let eventId = deleteData["id"] as? String,
              let titleText = deleteData["title"] as? String,
              let prefs = UserDefaults.standard.dictionary(forKey: "notificationPreferences") as? [String: Any],
              let updatesEnabled = prefs["eventUpdates"] as? Bool, updatesEnabled == true else {
            return
        }
        // Only notify if the user had RSVPd to this event
        let rsvpd = UserDefaults.standard.stringArray(forKey: "rsvpEvents")?.contains(eventId) ?? false
        guard rsvpd else { return }
        let title = "Event Cancelled"
        let body = "The event \"\(titleText)\" was cancelled."
        scheduleLocalNotification(title: title, message: body)
    }

    /// Schedules a local notification to show a banner.
    private func scheduleLocalNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        // Trigger the notification after a short delay.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error.localizedDescription)")
            } else {
                print("Local notification scheduled: \(title)")
            }
        }
    }
    
    /// Disconnects the socket.
    func closeConnection() {
        socket.disconnect()
    }
}
