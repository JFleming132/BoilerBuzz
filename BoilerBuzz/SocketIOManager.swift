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
    
    // Change the URL as needed; for development, we use localhost.
    private init() {
        guard let url = URL(string: "http://localhost:3000") else {
            fatalError("Invalid URL for Socket.IO server")
        }
        // Configure the SocketManager with options such as logging and compression.
        manager = SocketManager(socketURL: url, config: [.log(false), .compress])
        socket = manager.defaultSocket
    }
    
    /// Establishes the connection and sets up event listeners.
    func establishConnection() {
        socket.on(clientEvent: .connect) { data, ack in
            print("Socket connected: \(data)")
        }
        
        // Listen for the "newEvent" event from the backend.
        socket.on("newEvent") { data, ack in
            print("Received newEvent: \(data)")
            
            // Process event data
            if let eventData = data.first as? [String: Any] {
                // Extract the author ID from the event.
                guard let authorId = eventData["author"] as? String else {
                    print("No author ID found in event data.")
                    return
                }
                // If the author ID is the same as the UserId
                guard let userId = UserDefaults.standard.string(forKey: "userId"), userId != authorId else {
                    print("Ignoring event from the same user (authorId: \(authorId)).")
                    return
                }
                
                // Retrieve the user's friend notification preferences from UserDefaults.
                if let storedPrefs = UserDefaults.standard.dictionary(forKey: "notificationPreferences") as? [String: Any],
                   let friendPostingPrefs = storedPrefs["friendPosting"] as? [String: Bool] {
                    print("Friend posting preferences found: \(friendPostingPrefs)")
                    
                    // Check if notifications are enabled for this author.
                    if friendPostingPrefs[authorId] == true {
                        let title = eventData["title"] as? String ?? "New Event"
                        let authorUsername = eventData["authorUsername"] as? String ?? "Unknown"
                        let message = "\(authorUsername) posted a new event!"
                        
                        DispatchQueue.main.async {
                            // Only if you want the notification to populate the center
                            // NotificationManager.shared.addNotification(title: title, message: message)

                            // if you want the banner and the notification
                            self.scheduleLocalNotification(title: title, message: message)
                        }
                    } else {
                        print("Notifications for events from author \(authorId) are disabled by preferences.")
                    }
                } else {
                    print("No notification preferences found in UserDefaults.")
                }
            }
        }
        
        socket.on(clientEvent: .error) { data, ack in
            print("Socket encountered an error: \(data)")
        }
        
        // Connect the socket.
        socket.connect()
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
