//
//  AccountView.swift
//  BoilerBuzz
//
//  Created by Patrick on 2/7/25.
//

import SwiftUI

import UIKit

// UIImage extension for encoding
extension UIImage {
    var base64: String? {
        self.jpegData(compressionQuality: 1)?.base64EncodedString()
    }
}

// String extension for decoding base64 into UIImage
extension String {
    var imageFromBase64: UIImage? {
        guard let imageData = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}

struct StarRatingView: View {
    let rating: Float  // Assume values: 0.0, 0.5, 1.0, 1.5, ... up to 5.0
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                if rating >= Float(index) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                } else if rating + 0.5 >= Float(index) {
                    // SF Symbol for a half star may differ based on iOS version.
                    Image(systemName: "star.leadinghalf.filled")
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: "star")
                        .foregroundColor(.yellow)
                }
            }
        }
    }
}


struct FriendStatusResponse: Codable {
    let isFriend: Bool
}

struct AccountView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var profileData = ProfileViewModel()
    @State private var showFavoritedDrinks = false
    @State private var showFriendsList = false
    @State private var isFriend: Bool = false
    @State private var showDeleteConfirmation = false
    @State private var showBanConfirmation = false
    @State private var showRatingPopup: Bool = false
    
    /* TESTING */
    @State private var randomProfileId: String? = nil
    @State private var showRandomProfile: Bool = false
    /* TESTING */


    // Optional parameter: if nil, show self-profile; if non-nil, show another user's profile.
    var viewedUserId: String? = nil
    var adminStatus: Bool? = nil  // If passed, use this value for isAdmin
    
    var isOwnProfile: Bool {
        if let viewed = viewedUserId,
           let stored = UserDefaults.standard.string(forKey: "userId") {
            return viewed == stored
        }
        return true
    }

    var isAdmin: Bool {
        let stored = UserDefaults.standard.bool(forKey: "isAdmin")
        print("adminStatus = \(adminStatus ?? stored)")
        return adminStatus ?? stored
    }
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Settings
                HStack {
                    if !isOwnProfile && isAdmin {
                        HStack(spacing: 12) {
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                Text("Delete User")
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            Button(action: {
                                showBanConfirmation = true
                            }) {
                                Text(profileData.isBanned ? "Unban User" : "Ban User")
                                    .foregroundColor(.orange)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    Spacer()
                    if isOwnProfile {
                        NavigationLink(destination: NotificationCenterView()) {
                            Image(systemName: "bell.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.primary)
                                .padding(14)
                                .clipShape(Circle())
                                .contentShape(Circle())
                        }
                        NavigationLink(destination: SettingsView(profileData: profileData)) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.primary)
                                .padding(14)
                                .clipShape(Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier("settingsButton")
                    }
                    else {
                        Button(action: {
                            showRatingPopup = true
                        }) {
                            Image(systemName: "star.bubble.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                                .padding(14)
                                .clipShape(Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier("rateUserButton")
                    }
                }
                .padding(.horizontal)
                .alert("Delete User", isPresented: $showDeleteConfirmation) {
                    Button("Confirm", role: .destructive) {
                        deleteUser()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to delete this user?")
                }
                .alert(profileData.isBanned ? "Unban User" : "Ban User", isPresented: $showBanConfirmation) {
                    Button("Confirm", role: .destructive) {
                        toggleBanUser()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text(profileData.isBanned ?
                         "Are you sure you want to unban this user?" :
                         "Are you sure you want to ban this user from posting events?")
                }
                
                // Profile Picture
                Image(uiImage: profileData.profilePicture)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 5)

                
                // User Rating
                StarRatingView(rating: profileData.rating)
                    .padding(.top, 5)
                
                // Profile Name & Bio
                VStack {
                    HStack {
                        Text(profileData.username)
                            .font(.title2)
                            .fontWeight(.bold)
                        if profileData.isAdmin {
                            Text("Admin")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .cornerRadius(4)
                        }
                    }
                    Text(profileData.bio)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .onAppear {
                    // If a specific user is passed in, fetch that profile; otherwise, fetch your own.
                    if let uid = viewedUserId {
                        profileData.fetchUserProfile(userId: uid)
                        fetchFriendStatus()
                    } else {
                        profileData.fetchUserProfile()
                    }
                }
                
                // Buttons Row
                HStack {
                    Button(action: {
                        // Should show your favorited drinks
                        showFavoritedDrinks = true
                    }) {
                        Image(systemName: "wineglass.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // This was on the design doc, but idk if this is a new post or whatever
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Friend request action
                        if isOwnProfile {
                                // Action: Show your friends list
                            showFriendsList = true
                        } else {
                                // Action: Add friend
                            if !isFriend {
                                addFriend()
                            }
                        }
                    }) {
                        Image(systemName: isOwnProfile ? "person.2.fill" : (isFriend ? "checkmark" : "person.badge.plus.fill"))
                            .resizable()
                            .frame(width: 40, height: 40)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 30)
                
               //  For TESTING
                if isOwnProfile {
                    Button("View Random Profile") {
                        fetchRandomProfile { id in
                            if let id = id {
                                self.randomProfileId = id
                                self.showRandomProfile = true
                            }
                        }
                    }
                    .foregroundColor(.blue)
                    .padding()


                    NavigationLink(destination: AccountView(viewedUserId: randomProfileId, adminStatus: adminStatus), isActive: $showRandomProfile) {
                                            EmptyView()
                                        }


                }
                
                // Grid for posts/favorites
                // Right now just empty boxes. dont know what to have at the beginning
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(0..<6) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 100)
                    }
                }
                .padding()

            }
            .padding()
            .overlay(
                Group {
                    if showRatingPopup {
                        UserRatingPopup(isPresented: $showRatingPopup, submitAction: { rating, feedback in
                            submitUserRating(rating: rating, feedback: feedback)
                        })
                        .transition(.opacity)
                        .animation(.easeInOut, value: showRatingPopup)
                    }
                }
            )

            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(viewedUserId == nil ? "Account" : "Profile")
                    .font(.system(size: 18, weight: .semibold))
                }
            }
            .sheet(isPresented: $showFavoritedDrinks) {
                FavoritedDrinksPopup(isMyProfile: viewedUserId == nil, userId: profileData.userId)
                    .presentationDetents([.medium, .large])
            }
            // Present FriendsListPopup sheet when the friend button is tapped on own profile
            .sheet(isPresented: $showFriendsList) {
                FriendsListPopup(isMyProfile: isOwnProfile, userId: profileData.userId, adminStatus: adminStatus)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    func deleteUser() {
        guard let adminId = UserDefaults.standard.string(forKey: "userId"),
              let friendId = viewedUserId else {
            print("Missing admin or friend id")
            return
        }
        guard let url = URL(string: "http://localhost:3000/api/profile/deleteUser") else {
            print("Invalid URL for deleteUser")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "adminId": adminId,
            "friendId": friendId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON for deleteUser: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting user: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response deleting user: \(response ?? "No response" as Any)")
                return
            }
            DispatchQueue.main.async {
                print("User deleted successfully!")
                presentationMode.wrappedValue.dismiss()
            }
        }.resume()
    }

    func toggleBanUser() {
        // Admin action: Ban or unban the viewed user.
        guard let adminId = UserDefaults.standard.string(forKey: "userId"),
              let friendId = viewedUserId else {
            print("Missing admin or friend id")
            return
        }
        
        guard let url = URL(string: "http://localhost:3000/api/profile/banUser") else {
            print("Invalid URL for banUser")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["adminId": adminId, "friendId": friendId]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON for banUser: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error toggling ban status: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response toggling ban status: \(response ?? "No response" as Any)")
                return
            }
            
            DispatchQueue.main.async {
                print("Ban status toggled successfully!")
                // Update the profileData ban status.
                profileData.isBanned.toggle()
            }
        }.resume()
    }

    func addFriend() {
        guard let myUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("My user ID not found")
            return
        }
        guard let friendId = viewedUserId else {
            print("Friend ID is missing")
            return
        }
        guard let url = URL(string: "http://localhost:3000/api/friends/addFriend") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["userId": myUserId, "friendId": friendId]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error adding friend: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response adding friend: \(response ?? "No response" as Any)")
                return
            }
            
            DispatchQueue.main.async {
                print("Friend added successfully!")
                // Optionally, show a confirmation message or update local state
                isFriend = true
            }
        }.resume()
    }

    func fetchFriendStatus() {
        // Only fetch status if we're viewing someone else's profile.
        guard let myUserId = UserDefaults.standard.string(forKey: "userId"),
              let friendId = viewedUserId,
              !isOwnProfile else { return }
        
        guard let url = URL(string: "http://localhost:3000/api/friends/status?userId=\(myUserId)&friendId=\(friendId)") else {
            print("Invalid URL for friend status")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching friend status: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data for friend status")
                return
            }
            
            do {
                let statusResponse = try JSONDecoder().decode(FriendStatusResponse.self, from: data)
                DispatchQueue.main.async {
                    self.isFriend = statusResponse.isFriend
                    print("Friend status: \(self.isFriend)")
                }
            } catch {
                print("Error decoding friend status: \(error.localizedDescription)")
            }
        }.resume()
    }

    func fetchRandomProfile(completion: @escaping (String?) -> Void) {
        guard let myUserId = UserDefaults.standard.string(forKey: "userId"),
            let url = URL(string: "http://localhost:3000/api/profile/random?exclude=\(myUserId)") else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching random profile: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received for random profile")
                completion(nil)
                return
            }
            
            do {
                // Assume the endpoint returns { "_id": "...", "username": "..." }
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let randomId = json["_id"] as? String {
                    completion(randomId)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error decoding random profile: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    func submitUserRating(rating: Float, feedback: String) {
        guard let raterUserId = UserDefaults.standard.string(forKey: "userId"),
            let ratedUserId = viewedUserId else {
            print("Missing user IDs")
            return
        }
        
        guard let url = URL(string: "http://localhost:3000/api/ratings") else {
            print("Invalid URL for ratings endpoint")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "raterUserId": raterUserId,
            "ratedUserId": ratedUserId,
            "rating": rating,
            "feedback": feedback
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing rating JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error submitting rating: \(error)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response submitting rating: \(response ?? "No response" as Any)")
                return
            }
            print("Rating submitted successfully")
        }.resume()
    }




}
    struct AccountView_Previews: PreviewProvider {
        static var previews: some View {
            AccountView()
        }
    }
