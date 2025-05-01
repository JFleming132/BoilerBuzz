//
//  NotificationsSettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//


import SwiftUI

struct NotificationPreferences: Codable {
    var drinkSpecials: Bool
    var eventUpdates: Bool
    var eventReminders: Bool
    var announcements: Bool
    var locationBasedOffers: Bool
    var friendPosting: [String: Bool]
}

struct NotificationsSettingsView: View {
    @State private var friendList: [FriendNotification] = []
    @State private var errorMessage: String? = nil
    // This dictionary tracks which friends have notifications enabled.
    @State private var friendNotificationPreferences: [String: Bool] = [:]
    
    // Toggles for additional notification types.
    @State private var drinkSpecialsEnabled: Bool = false
    @State private var eventUpdatesEnabled: Bool = false
    @State private var eventRemindersEnabled: Bool = false
    @State private var announcementsEnabled: Bool = false
    @State private var locationBasedOffersEnabled: Bool = false
    @State private var isLoadingPreferences: Bool = true


    var body: some View {
        NavigationView {
            Form {
                if isLoadingPreferences {
                    ProgressView("Loading Preferences...")
                } else {
                    Section(header: Text("Post Notifications")) {
                        DisclosureGroup("Event Postings") {
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                            } else if friendList.isEmpty {
                                Text("No friends found.")
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(friendList) { friend in
                                    Toggle(friend.name, isOn: Binding(
                                        get: { friendNotificationPreferences[friend.id] ?? false },
                                        set: { newValue in
                                            friendNotificationPreferences[friend.id] = newValue
                                            updateNotificationPreferences()
                                        }
                                    ))
                                }
                            }
                        }

                        // Other notification toggles
                        Toggle("Drink Specials", isOn: $drinkSpecialsEnabled.onChange(updateNotificationPreferences))
                        Toggle("Event Updates", isOn: $eventUpdatesEnabled.onChange(updateNotificationPreferences))
                        Toggle("Event Reminders", isOn: $eventRemindersEnabled.onChange(updateNotificationPreferences))
                        Toggle("Administrative Announcements", isOn: $announcementsEnabled.onChange(updateNotificationPreferences))
                        Toggle("Location Based Offers", isOn: $locationBasedOffersEnabled.onChange(updateNotificationPreferences))
                    }
                }
            }
            .navigationTitle("Notifications Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationCenterView()) {
                        Image(systemName: "bell.fill")
                            .imageScale(.large)
                            .padding(6)
                    }
                }
            }
            .onAppear {
                requestNotificationPermission()
                loadData()
            }
        }
    }

    func loadData() {
        isLoadingPreferences = true
        fetchFriendList {
            fetchNotificationPreferences()
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Permission request failed: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }

    // func scheduleLocalNotification(for friendName: String) {
    //     let content = UNMutableNotificationContent()
    //     content.title = "New Event!"
    //     content.body = "\(friendName) just posted a new event. Check it out!"
    //     content.sound = .default

    //     // Trigger notification after 5 seconds for testing purposes.
    //     let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

    //     let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    //     UNUserNotificationCenter.current().add(request) { error in
    //         if let error = error {
    //             print("Error scheduling notification: \(error.localizedDescription)")
    //         } else {
    //             print("Notification scheduled for friend: \(friendName)")
    //         }
    //     }
    // }


    
    // Fetch friend list similar to the FriendsListPopup.

    func fetchFriendList(completion: @escaping () -> Void) {
        guard let userId = UserDefaults.standard.string(forKey: "userId"),
            let url = URL(string: "\(backendURL)api/notification/friends/\(userId)") else {
            self.errorMessage = "Invalid URL or User ID."
            completion()
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error fetching friends: \(error.localizedDescription)"
                    completion()
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received from server."
                    completion()
                    return
                }
                
                do {
                    let decodedFriends = try JSONDecoder().decode([FriendNotification].self, from: data)
                    self.friendList = decodedFriends
                    
                    
                    // Initialize toggles safely
                    for friend in decodedFriends {
                        if self.friendNotificationPreferences[friend.id] == nil {
                            self.friendNotificationPreferences[friend.id] = false
                        }
                    }
                    
                    self.errorMessage = nil
                } catch {
                    self.errorMessage = "Failed to decode friends: \(error.localizedDescription)"
                    print("JSON response:", String(data: data, encoding: .utf8) ?? "No JSON")
                }
                
                completion()
            }
        }.resume()
    }
    // Fetch the current notification preferences from the backend.
    func fetchNotificationPreferences() {

        guard let userId = UserDefaults.standard.string(forKey: "userId"),
            let url = URL(string: "\(backendURL)api/notification/\(userId)") else {
            self.errorMessage = "Invalid URL or User ID."
            self.isLoadingPreferences = false

            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                defer { self.isLoadingPreferences = false }

                if let error = error {
                    self.errorMessage = "Error fetching preferences: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received from server."
                    return
                }
                
                do {
                    let prefs = try JSONDecoder().decode(NotificationPreferences.self, from: data)
                    self.drinkSpecialsEnabled = prefs.drinkSpecials
                    self.eventUpdatesEnabled = prefs.eventUpdates
                    self.eventRemindersEnabled = prefs.eventReminders
                    self.announcementsEnabled = prefs.announcements
                    self.locationBasedOffersEnabled = prefs.locationBasedOffers
                    
                    // Important: Sync friend preferences safely
                    for friend in self.friendList {
                        self.friendNotificationPreferences[friend.id] = prefs.friendPosting[friend.id] ?? false
                    }
                    
                    self.errorMessage = nil
                } catch {
                    self.errorMessage = "Failed to decode preferences: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // Update the notification preferences on the backend.
    func updateNotificationPreferences() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("User ID not found")
            return
        }
        guard let url = URL(string: "\(backendURL)api/notification/\(userId)") else {
            print("Invalid URL")
            return
        }
        
        let preferences: [String: Any] = [
            "drinkSpecials": drinkSpecialsEnabled,
            "eventUpdates": eventUpdatesEnabled,
            "eventReminders": eventRemindersEnabled,
            "announcements": announcementsEnabled,
            "locationBasedOffers": locationBasedOffersEnabled,
            "friendPosting": friendNotificationPreferences
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: preferences, options: [])
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    print("Error updating preferences: \(error.localizedDescription)")
                    return
                }
                guard let data = data else {
                    print("No data received after updating preferences")
                    return
                }
                do {
                    let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
                    // print("Update response: \(responseJSON)")

                    UserDefaults.standard.set(preferences, forKey: "notificationPreferences")
                } catch {
                    print("Failed to parse update response: \(error.localizedDescription)")
                }
            }.resume()
        } catch {
            print("Error serializing preferences: \(error.localizedDescription)")
        }
    }
}

struct NotificationsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsSettingsView()
    }
}

extension Binding {
    func onChange(_ handler: @escaping () -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: {
                self.wrappedValue = $0
                handler()
            }
        )
    }
}

struct FriendNotification: Codable, Identifiable {
    let id: String
    let name: String
}

