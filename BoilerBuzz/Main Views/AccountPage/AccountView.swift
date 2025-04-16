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

struct BlockedStatusResponse: Codable {
    let isBlocked: Bool
}


struct AccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var notificationManager: NotificationManager
    
    @StateObject var profileData = ProfileViewModel()

    @State private var showFavoritedDrinks = false
    @State private var showFriendsList = false
    
    @State private var isFriend: Bool = false
    @State private var isBlocked: Bool = false
    
    @State private var showDeleteConfirmation = false
    @State private var showBanConfirmation = false
    @State private var showPromotionConfirmation = false
    
    @State private var showRatingPopup: Bool = false
    
    @State private var selectedTab: String = "Events"
    @State private var showPostPhotoAction: Bool = false
    @State private var showSourceChoice: Bool = false
    
    @State private var showCreateEvent: Bool = false  // New state variable for CreateEventView

    
    @State private var showImagePicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var uploadMode: UploadMode = .none  
    @State private var selectedSourceType: UIImagePickerController.SourceType = .photoLibrary

    enum UploadMode {
        case none, event, photo
    }
    
    /* TESTING */
    @State private var randomProfileId: String? = nil
    @State private var showRandomProfile: Bool = false
    @State private var showingShareSheet = false
    /* TESTING */


    // Optional parameter: if nil, show self-profile; if non-nil, show another user's profile.
    var viewedUserId: String? = nil
    var deeplinkUserId: String? = nil
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

    var ratingDisplay: some View {
        HStack(spacing: 5) {
            StarRatingView(rating: profileData.rating)
            Text("(\(profileData.ratingCount))")
                .font(.caption)
            
                .foregroundColor(.gray)
        }
    }
    

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    actionButtonsRow
                    contentTabs
                }
                .padding()
                .overlay(actionSheetOverlay)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingShareSheet) {
                // Create a deep link URL using your custom scheme.
                let shareURL = URL(string: "boilerbuzz://account?id=\(profileData.userId)")!
                let shareText = "Check out this profile: \(shareURL.absoluteString)"
                ShareSheet(activityItems: [shareText])
            }
            .sheet(isPresented: $showFavoritedDrinks) {
                FavoritedDrinksPopup(isMyProfile: viewedUserId == nil, userId: profileData.userId)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showFriendsList) {
                FriendsListPopup(isMyProfile: isOwnProfile, userId: profileData.userId, adminStatus: adminStatus)
                    .presentationDetents([.medium, .large])
            }
            // New sheet for creating an event
                        .sheet(isPresented: $showCreateEvent) {
                            CreateEventView(onEventCreated: { newEvent in
                                // Optionally update profileData or your events list here.
                                // For example, you could insert newEvent into profileData.userEvents.
                                // Then, dismiss the sheet.
                                showCreateEvent = false
                            })
                        }
            // Present image picker for photo uploads.
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: selectedSourceType)
                    .onDisappear {
                        if let image = selectedImage {
                            uploadPhoto(image: image)
                        }
                    }
            }
        }
    }

    // MARK: - Subviews / Computed Properties
    
    // Header View: settings row, profile picture, rating, name, bio.
    var headerView: some View {
        VStack(spacing: 10) {
            settingsRow
            profilePictureView
            ratingDisplay.padding(.top, 5)
            profileInfoView
                .onAppear {
                    if let uid = viewedUserId {
                        profileData.fetchUserProfile(userId: uid)
                        profileData.fetchUserEvents()
                        profileData.fetchUserPhotos()  
                        fetchFriendStatus()
                        fetchBlockedStatus()
                    } else {
                        profileData.fetchUserProfile()
                        profileData.fetchUserEvents()
                        profileData.fetchUserPhotos()
                    }
                    
                    if let deeplinkId = deeplinkUserId {
                        self.randomProfileId = deeplinkId
                        self.showRandomProfile = true
                    }
                }
        }
    }

    // Settings row: Delete, Ban, Notifications, Settings buttons.
    var settingsRow: some View {
        HStack {
            if !isOwnProfile && isAdmin {
                HStack(spacing: 12) {
                    Button(action: { showDeleteConfirmation = true }) {
                        Text("Delete User")
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    Button(action: { showBanConfirmation = true }) {
                        Text(profileData.isBanned ? "Unban User" : "Ban User")
                            .foregroundColor(.orange)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    Button(action: {
                                //Done: Verify user as promoted with function call
                                showPromotionConfirmation = true //causes the alert that asks the user to confirm promotion to appear
                            }) {
                                Text(profileData.isPromoted ? "Demote User" : "Promote User")
                                    .foregroundColor(.blue)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                }
            }
            Spacer()
            if isOwnProfile {
                ZStack(alignment: .topTrailing) {
                    NavigationLink(destination: NotificationCenterView()) {
                        Image(systemName: "bell.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.primary)
                            .padding(14)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }

                    if notificationManager.notifications.contains(where: { !$0.isRead }) {
                        Text("\(notificationManager.notifications.filter { !$0.isRead }.count)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Circle().fill(Color.red))
                            .offset(x: -4, y: 4)
                    }
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
            } else {
                Button(action: { showRatingPopup = true }) {
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
            Button("Confirm", role: .destructive) { deleteUser() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this user?")
        }
        .alert(profileData.isBanned ? "Unban User" : "Ban User", isPresented: $showBanConfirmation) {
            Button("Confirm", role: .destructive) { toggleBanUser() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(profileData.isBanned ?
                 "Are you sure you want to unban this user?" :
                 "Are you sure you want to ban this user from posting events?")
        }
        .alert(profileData.isPromoted ? "Demote User" : "Promote User", isPresented: $showPromotionConfirmation) {
            Button("Confirm", role: .destructive) {
                togglePromotion()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(profileData.isPromoted ?
                "Are you sure you want to demote this user?" :
                    "Are you sure you want to promote this user?")
        }
    }
    
    // Profile Picture View.
    var profilePictureView: some View {
        Image(uiImage: profileData.profilePicture)
            .resizable()
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(radius: 5)
    }
    
    // Profile info: username, bio, admin tag.
    var profileInfoView: some View {
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
                if profileData.isPromoted {
                    Text("Promoted")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.blue)
                        .cornerRadius(4)
                }
            }
            Text(profileData.bio)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // Action Buttons Row: Favorited drinks, Plus button, Friend action.
    var actionButtonsRow: some View {
        HStack {
            Button(action: { showFavoritedDrinks = true }) {
                Image(systemName: "wineglass.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding()
            }
            Spacer()
            Button(action: { showPostPhotoAction = true }) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding()
            }
            .confirmationDialog("Create New", isPresented: $showPostPhotoAction, titleVisibility: .visible) {
                            Button("New Event") {
                                uploadMode = .event
                                showCreateEvent = true
                                // TODO: Implement the post creation logic.
                                // This is the View, but cannot find events, maybe dont need it?
                                // CreateEventView(onEventCreated: { newEvent in
                                //     events.append(newEvent)
                                // })
                            }
                            Button("New Photo") {
                                uploadMode = .photo
                                // Present an action sheet to choose source type
                                showSourceChoice = true
                            }
                            Button("Cancel", role: .cancel) {
                                uploadMode = .none
                            }
                        }
                        // Present the source type choice sheet
                        .confirmationDialog("Choose Photo Source", isPresented: $showSourceChoice, titleVisibility: .visible) {
                            Button("Camera") {
                                selectedSourceType = .camera
                                showImagePicker = true
                            }
                            Button("Photo Library") {
                                selectedSourceType = .photoLibrary
                                showImagePicker = true
                            }
                            Button("Cancel", role: .cancel) { }
                    }
            Spacer()
            Button(action: {
                if isOwnProfile {
                    showFriendsList = true
                } else {
                    if !isFriend { addFriend() }
                }
            }) {
                Image(systemName: isOwnProfile ? "person.2.fill" : (isFriend ? "checkmark" : "person.badge.plus.fill"))
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding()
            }

            if !isOwnProfile {
                Spacer()
                Button(action: {
                    blockUser()
                }) {
                    Image(systemName: isBlocked ? "xmark.circle.fill" : "xmark.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .padding()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
    }
    
    // Tabs for Posts and Photos.
    var contentTabs: some View {
        VStack {
            Picker("Select Content", selection: $selectedTab) {
                Text("Events").tag("Events")
                Text("Photos").tag("Photos")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if selectedTab == "Events" {
                postsGrid
            } else {
                photosGrid
            }
        }
    }
    
    // Overlay for rating popup.
    var actionSheetOverlay: some View {
        Group {
            if showRatingPopup {
                UserRatingPopup(isPresented: $showRatingPopup, submitAction: { rating, feedback in
                    submitUserRating(rating: rating, feedback: feedback)
                })
                .transition(.opacity)
                .animation(.easeInOut, value: showRatingPopup)
            }
        }
    }
    
    // Toolbar content.
    var toolbarContent: some ToolbarContent {
      Group {
          ToolbarItem(placement: .navigationBarLeading) {
              Text(viewedUserId == nil ? "Account" : "Profile")
                  .font(.system(size: 18, weight: .semibold))
          }
          if !isOwnProfile {
              ToolbarItem(placement: .navigationBarTrailing) {
                  Button {
                      showingShareSheet = true
                  } label: {
                      Image(systemName: "square.and.arrow.up")
                  }
                }
            }
        }
    }
    
    // Computed property for the posts grid.
    private var postsGrid: some View {
        if profileData.userEvents.isEmpty {
            return AnyView(
                Text(isOwnProfile ? "You haven't posted any events yet." : "This user hasn't posted any events yet.")
                    .foregroundColor(.gray)
                    .padding()
            )
        } else {
            return AnyView(
                ForEach(profileData.userEvents) { event in
                    PostCardView(event: event)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
            )
        }
    }
    
    // Computed property for the photos grid.
    private var photosGrid: some View {
        if profileData.userPhotos.isEmpty {
            return AnyView(
                Text(isOwnProfile ? "You haven't uploaded any photos yet." : "This user hasn't uploaded any photos yet.")
                    .foregroundColor(.gray)
                    .padding()
            )
        } else {
            return AnyView(
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 2), spacing: 5) {
                    ForEach(profileData.userPhotos) { photo in
                        NavigationLink(destination: PhotoDetailView(photo: photo, isOwnProfile: isOwnProfile, isAdmin: isAdmin)) {
                            if let url = URL(string: photo.url) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Color.gray.opacity(0.3)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    case .failure(let error):

                                        Color.red
                                    @unknown default:
                                        Color.gray.opacity(0.3)
                                    }
                                }
                                .frame(height: 100)
                                // .clipped()
                            } else {
                                Color.red // URL is missing or invalid.
                            }
                        }
                    }
                }
                .padding()
            )
        }
    }

    

    
    // MARK: - Functions
    func uploadPhoto(image: UIImage) {
        guard let url = URL(string: "http://localhost:3000/api/photo/uploadPhoto") else {
            print("Invalid URL for photo upload")
            return
        }
        
        // Convert image to JPEG data (adjust compression quality as needed)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error converting image to JPEG data")
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        let publicId = UUID().uuidString
        
        // Get the current user's ID to set as the creator.
        guard let creator = UserDefaults.standard.string(forKey: "userId") else {
            print("User ID not found for photo upload")
            return
        }
        
        // Build the JSON body.
        let body: [String: Any] = [
            "imageData": base64String,
            "publicId": publicId,
            "creator": creator
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON for photo upload: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error uploading photo: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received from photo upload")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // print("Upload response: \(json)")
                    DispatchQueue.main.async {
                        profileData.fetchUserPhotos()
                    }
                }
            } catch {
                print("Error decoding upload response: \(error.localizedDescription)")
            }
        }.resume()
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

    func fetchBlockedStatus() {
        // Only fetch status if we're viewing someone else's profile.
        guard let myUserId = UserDefaults.standard.string(forKey: "userId"),
              let friendId = viewedUserId,
              !isOwnProfile else { return }
        
        //Done: Edit this string to correspond with the a new backend function
        guard let url = URL(string: "http://localhost:3000/api/blocked/status?userId=\(myUserId)&friendId=\(friendId)") else {
            print("Invalid URL for Blocked status")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching Block status: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data for Block status")
                return
            }
            
            do {
                let statusResponse = try JSONDecoder().decode(BlockedStatusResponse.self, from: data)
                DispatchQueue.main.async {
                    self.isBlocked = statusResponse.isBlocked
                    print("Block status: \(self.isBlocked)")
                }
            } catch {
                print("Error decoding Block status: \(error.localizedDescription)")
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

    func blockUser() { //this function is a copied and modified version of addFriend, hence the variable names
        guard let myUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("My user ID not found")
            return
        }
        guard let friendId = viewedUserId else {
            print("Friend ID is missing")
            return
        }
        guard let url = URL(string: "http://localhost:3000/api/blocked/block") else {
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
                print("Error blocking user: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response blocking user: \(response ?? "No response" as Any)")
                return
            }
            
            DispatchQueue.main.async {
                print("Blocked user successfully!")
                // Optionally, show a confirmation message or update local state
                isBlocked = true
            }
        }.resume()
    }
    
    func togglePromotion() {
        // copied version of toggle ban
        guard let adminId = UserDefaults.standard.string(forKey: "userId"),
              let friendId = viewedUserId else {
            print("Missing admin or friend id")
            return
        }
        
        guard let url = URL(string: "http://localhost:3000/api/profile/promote") else {
            print("Invalid URL for promote")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["adminId": adminId, "friendId": friendId]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON for promote: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error toggling promotion status: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response toggling promotion status: \(response ?? "No response" as Any)")
                return
            }
            
            DispatchQueue.main.async {
                print("promotion status toggled successfully!")
                // Update the profileData ban status.
                profileData.isPromoted.toggle()
            }
        }.resume()
    }

}
    struct AccountView_Previews: PreviewProvider {
        static var previews: some View {
            AccountView()
        }
    }
