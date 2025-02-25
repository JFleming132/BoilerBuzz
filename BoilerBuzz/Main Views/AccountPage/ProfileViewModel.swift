//
//  ProfileViewModel.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/15/25.
//


import Foundation
import Combine
import SwiftUI
import UIKit

class ProfileViewModel: ObservableObject {
    @Published var username: String = "Loading..."
    @Published var bio: String = "Loading..."
    @Published var userId: String = ""
    @Published var profilePicture: UIImage = UIImage(systemName: "person.circle")!
    
    // Function to fetch user data from the backend.
    func fetchUserProfile() {
        print("here")
        guard let storedUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("No userId stored, user may not be logged in")
            return
        }
        
        self.userId = storedUserId
        
        guard let url = URL(string: "http://localhost:3000/api/profile/\(storedUserId)") else {
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
                    self.username = decodedResponse.username
                    self.bio = decodedResponse.bio
                    /* retrieve base64 encoded string from user doc and decode the profile photo */
                    /* profile photos have an inherent 16kb max limit imposed by mongoDB */
                    guard let stringData = Data(base64Encoded: decodedResponse.profilePicture),
                          let uiImage = UIImage(data: stringData) else {
                              print("Error: couldn't create UIImage")
                              return
                          }
                    /* set current profile pic to be the one we decoded */
                    self.profilePicture = uiImage
                }
            } catch {
                print("Error decoding profile data: \(error)")
            }
        }.resume()
    }
}

// Struct will need profilepic eventually
struct Profile: Codable {
    let username: String
    let bio: String
    let profilePicture: String
}
