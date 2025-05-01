//
//  FriendSearchView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 3/30/25.
//

import SwiftUI

struct FriendSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery: String = ""
    @State private var searchResults: [Friend] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var friendAdded: Bool = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {

                Text("Click to add friend")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                TextField("Search by username", text: $searchQuery, onCommit: {
                    performSearch()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never) // Prevents autocapitalization for usernames.
                .autocorrectionDisabled(true) // Disables autocorrection for usernames.
                .padding()

                if isLoading {
                    ProgressView()
                        .padding()
                    Spacer()
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else if searchResults.isEmpty {
                    Text("No users found.")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    List(searchResults) { friend in
                        Button(action: {
                            // Trigger add friend action here.
                            addFriend(friend)
                        }) {
                            HStack {
                                // Optionally load profile picture.
                                // Maybe a TODO, but then well have to fetch that
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                Text(friend.name)
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .overlay(
                Group {
                    if friendAdded {
                        Text("Friend added!")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut, value: friendAdded)
            )
        }
    }

    func performSearch() {
        // Reset state
        isLoading = true
        errorMessage = nil
        searchResults = []
        guard !searchQuery.isEmpty else {
            errorMessage = "Search query cannot be empty."
            isLoading = false
            return
        }
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            errorMessage = "Current user ID not found."
            isLoading = false
            return
        }
        
        guard let url = URL(string: "\(backendURL)api/friends/search?username=\(searchQuery)&exclude=\(currentUserId)") else {
            errorMessage = "Invalid URL."
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false }
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received."
                }
                return
            }
            print("Data received: \(data)")
            if let responseString = String(data: data, encoding: .utf8) {
                // print("Raw response from search endpoint: \(responseString)")
            }

            
            do {
                let users = try JSONDecoder().decode([Friend].self, from: data)
                DispatchQueue.main.async {
                    self.searchResults = users
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
            }
        }.resume()
    }
    
    func addFriend(_ friend: Friend) {
        guard let myUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("My user ID not found")
            return
        }
        let friendId = friend.id  // Use the id from the Friend object
        guard let url = URL(string: "\(backendURL)api/friends/addFriend") else {
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
                friendAdded = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    friendAdded = false  
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }.resume()
    }

}
