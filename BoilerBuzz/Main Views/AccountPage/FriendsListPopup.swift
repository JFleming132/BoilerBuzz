//
//  FriendsListPopup.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/24/25.
//

import SwiftUI

// A simple Friend model for preview/testing.
struct Friend: Identifiable, Codable {
    let id: String
    let name: String
    let profilePicture: String

    enum CodingKeys: String, CodingKey {
        case id = "_id" // Map the _id field from JSON to the id property
        case name = "username"
        case profilePicture
    }
}

struct FriendsListPopup: View {
    var isMyProfile: Bool      // True if viewing your own profile
    var userId: String         // The user id whose friends list to fetch
    var adminStatus: Bool? = nil
    
    @State private var friends: [Friend] = []
    @State private var errorMessage: String? = nil
    @State private var showAddFriend = false  // For later use if needed
    @State private var selectedFriend: Friend? = nil 
    
    var body: some View {
        NavigationView {
            Group {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    if friends.isEmpty {
                        Text("This is your friends list.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List {
                            ForEach(friends) { friend in
                                HStack {
                                    // Button to show friend's profile modally
                                    Button(action: {
                                        selectedFriend = friend
                                    }) {
                                        HStack {
                                            // Profile picture (using AsyncImage if URL available)
                                            // if let url = URL(string: friend.profilePicture) {
                                            //     AsyncImage(url: url) { phase in
                                            //         if let image = phase.image {
                                            //             image
                                            //                 .resizable()
                                            //                 .scaledToFill()
                                            //                 .frame(width: 50, height: 50)
                                            //                 .clipShape(Circle())
                                            //         } else if phase.error != nil {
                                            //             Image(systemName: "person.crop.circle.fill")
                                            //                 .resizable()
                                            //                 .frame(width: 50, height: 50)
                                            //         } else {
                                            //             Image(systemName: "person.crop.circle.fill")
                                            //                 .resizable()
                                            //                 .frame(width: 50, height: 50)
                                            //         }
                                            //     }
                                            // } else {
                                                Image(systemName: "person.crop.circle.fill")
                                                    .resizable()
                                                    .frame(width: 50, height: 50)
                                            // }
                                            
                                            // Friend's name
                                            Text(friend.name)
                                                .font(.headline)
                                                .padding(.leading, 8)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Spacer()
                                    
                                    // 'X' button to remove friend
                                    Button(action: {
                                        removeFriend(friend: friend)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isMyProfile {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showAddFriend = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchFriendsList()
        }
        .presentationDetents([.medium, .large])
        // Present the friend's profile as a separate modal with .large detent.
        .sheet(item: $selectedFriend) { friend in
            AccountView(viewedUserId: friend.id, adminStatus: adminStatus)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showAddFriend) {
            FriendSearchView()
        }
    }
    
    func fetchFriendsList() {
        guard let url = URL(string: "http://localhost:3000/api/friends/\(userId)") else {
            errorMessage = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Error fetching friends: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received from server."
                }
                return
            }
            // print out data
            // Decode the JSON data into an array of Friend objects
            do {
                let fetchedFriends = try JSONDecoder().decode([Friend].self, from: data)
                DispatchQueue.main.async {
                    self.friends = fetchedFriends
                    errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to decode friends: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    func removeFriend(friend: Friend) {
        guard let myUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("My user ID not found")
            return
        }
        
        guard let url = URL(string: "http://localhost:3000/api/friends/removeFriend") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build the JSON body with the current user's ID and the friend's ID.
        let body: [String: Any] = ["userId": myUserId, "friendId": friend.id]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error removing friend: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response removing friend: \(response ?? "No response" as Any)")
                return
            }
            
            DispatchQueue.main.async {
                // Remove the friend from the local friends array.
                if let index = self.friends.firstIndex(where: { $0.id == friend.id }) {
                    self.friends.remove(at: index)
                }
            }
        }.resume()
    }

}

struct FriendsListPopup_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FriendsListPopup(isMyProfile: true, userId: "12345")
        }
    }
}
