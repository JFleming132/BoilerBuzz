//
//  MapView.swift
//  BoilerBuzz
//
//  Created by user269394 on 2/7/25.
//

import SwiftUI

//UI Image extension with method (function? field?) for base64 encoding
extension UIImage {
    var base64: String? {
        self.jpegData(compressionQuality: 1)?.base64EncodedString() //encoding function
    }
}

//String extension with method (?) for base64 decoding into a UIImage
extension String {
    var imageFromBase64: UIImage? {
        guard let imageData = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}

struct AccountView: View {
    @StateObject var profileData = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Settings
                HStack {
                    Spacer()
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
                }
                .padding(.horizontal)
                
                
                // Profile Picture
                Image(uiImage: profileData.profilePicture)
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
                    Text(profileData.username)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(profileData.bio)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .onAppear {
                    profileData.fetchUserProfile()
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

}
    struct AccountView_Previews: PreviewProvider {
        static var previews: some View {
            AccountView()
        }
    }
