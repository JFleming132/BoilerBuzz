//
//  MapView.swift
//  BoilerBuzz
//
//  Created by user269394 on 2/7/25.
//

import SwiftUI

struct AccountView: View {
    @State private var profileName: String = "Loading..."
    @State private var profileBio: String = "Loading..."
    @State private var userId: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Settings
                HStack {
                    Spacer()
                    NavigationLink(destination: SettingsView(username: profileName, bio: profileBio, userId: userId)) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.primary)
                            .padding(14)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
                
                // Profile Picture
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .padding(.top, -30)
                
                // User Rating
                HStack(spacing: 2) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 5)
                
                // Profile Name & Bio
            VStack {
                Text(profileName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(profileBio)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .onAppear {
                fetchUserProfile()
            }
                
                // Buttons Row
                HStack {
                    Button(action: {
                        // Should show your favorited drinks
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
                        // Own profile should show list of friends
                    }) {
                        Image(systemName: "person.badge.plus.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 30)
                
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
                .padding()
            }
            .padding()
            .navigationTitle("Account")
        }
    }
    
    // Function to fetch user data from backend
    func fetchUserProfile() {
        guard let StoreduserId = UserDefaults.standard.string(forKey: "userId") else {
                print("No userId stored, user may not be logged in")
                return
            }

            self.userId = StoreduserId
            
        guard let url = URL(string: "http://localhost:3000/api/profile/\(self.userId)") else {
                print("Invalid URL")
                return
            }
            
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching profile data: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let decodedResponse = try JSONDecoder().decode(Profile.self, from: data)
                DispatchQueue.main.async {
                    self.profileName = decodedResponse.username
                    self.profileBio = decodedResponse.bio
                }
            } catch {
                print("Error decoding profile data: \(error)")
            }
        }.resume()
    }
}
    struct AccountView_Previews: PreviewProvider {
        static var previews: some View {
            AccountView()
        }
    }

struct Profile: Codable {
    let username: String
    let bio: String
}
