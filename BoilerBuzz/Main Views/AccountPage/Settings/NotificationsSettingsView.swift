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
    @State private var friendList: [Friend] = []
    @State private var errorMessage: String? = nil
    // This dictionary tracks which friends have notifications enabled.
    @State private var friendNotificationPreferences: [String: Bool] = [:]
    
    // Toggles for additional notification types.
    @State private var drinkSpecialsEnabled: Bool = false
    @State private var eventUpdatesEnabled: Bool = false
    @State private var eventRemindersEnabled: Bool = false
    @State private var announcementsEnabled: Bool = false
    @State private var locationBasedOffersEnabled: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Post Notifications")) {
                    DisclosureGroup("Events") {
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
                    
                    Toggle("Drink Specials", isOn: $drinkSpecialsEnabled)
                        .onChange(of: drinkSpecialsEnabled) { oldValue, newValue in
                            updateNotificationPreferences()
                        }
                    Toggle("Event Updates", isOn: $eventUpdatesEnabled)
                        .onChange(of: eventUpdatesEnabled) { oldValue, newValue in
                            updateNotificationPreferences()
                        }
                    Toggle("Event Reminders", isOn: $eventRemindersEnabled)
                        .onChange(of: eventRemindersEnabled) { oldValue, newValue in
                            updateNotificationPreferences()
                        }
                    Toggle("Administrative Announcements", isOn: $announcementsEnabled)
                        .onChange(of: announcementsEnabled) { oldValue, newValue in
                            updateNotificationPreferences()
                        }
                    Toggle("Location Based Offers", isOn: $locationBasedOffersEnabled)
                        .onChange(of: locationBasedOffersEnabled) { oldValue, newValue in
                            updateNotificationPreferences()
                        }
                }
            }
            .navigationTitle("Notifications Settings")
            .onAppear {
                fetchFriendList()
                fetchNotificationPreferences()
            }
        }
    }
    
    // Fetch friend list similar to the FriendsListPopup.
    func fetchFriendList() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            self.errorMessage = "User ID not found."
            return
        }
        guard let url = URL(string: "\(backendURL)api/friends/\(userId)") else {
            self.errorMessage = "Invalid URL."
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error fetching friends: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received from server."
                }
                return
            }
            
            do {
                let decodedFriends = try JSONDecoder().decode([Friend].self, from: data)
                DispatchQueue.main.async {
                    self.friendList = decodedFriends
                    // Initialize toggle states for each friend if not already set.
                    for friend in decodedFriends {
                        if self.friendNotificationPreferences[friend.id] == nil {
                            self.friendNotificationPreferences[friend.id] = false
                        }
                    }
                    self.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode friends: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    // Fetch the current notification preferences from the backend.
    func fetchNotificationPreferences() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            self.errorMessage = "User ID not found."
            return
        }
        guard let url = URL(string: "\(backendURL)api/notifications/\(userId)") else {
            self.errorMessage = "Invalid URL."
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error fetching preferences: \(error.localizedDescription)"
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received from server."
                }
                return
            }
            do {
                let prefs = try JSONDecoder().decode(NotificationPreferences.self, from: data)
                DispatchQueue.main.async {
                    self.drinkSpecialsEnabled = prefs.drinkSpecials
                    self.eventUpdatesEnabled = prefs.eventUpdates
                    self.eventRemindersEnabled = prefs.eventReminders
                    self.announcementsEnabled = prefs.announcements
                    self.locationBasedOffersEnabled = prefs.locationBasedOffers
                    self.friendNotificationPreferences = prefs.friendPosting
                    self.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
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
