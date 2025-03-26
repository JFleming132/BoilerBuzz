//
//  ProfileViewModel.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/15/25.
//


import Foundation
import Combine
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var username: String = "Loading..."
    @Published var bio: String = "Loading..."
    @Published var userId: String = ""
    @Published var profilePicture: UIImage = UIImage(systemName: "person.crop.circle.fill")!
    @Published var isAdmin: Bool = false
    @Published var rating: Float = 0.0

    // Function to fetch user data from the backend.


    @Published var isBanned: Bool = false

    
    // Function to fetch user data from the backend.
    func fetchUserProfile(userId: String? = nil) {
        var idToFetch: String
        if let provided = userId {
            idToFetch = provided
        } else {
            guard let storedUserId = UserDefaults.standard.string(forKey: "userId") else {
                print("No userId stored, user may not be logged in")
                return
            }
            idToFetch = storedUserId

        }
        
        self.userId = idToFetch
        
        guard let url = URL(string: "http://localhost:3000/api/profile/\(idToFetch)") else {
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
                print("got data \(data)")
                DispatchQueue.main.async {
                    self.username = decodedResponse.username
                    self.bio = decodedResponse.bio

                    self.profilePicture = decodedResponse.profilePicture.imageFromBase64 ?? UIImage(systemName: "person.crop.circle.fill")!

                    self.isAdmin = decodedResponse.isAdmin ?? false

                    self.isBanned = decodedResponse.isBanned ?? false

                    self.rating = decodedResponse.rating ?? 0.0

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
    let isAdmin: Bool?
    let isBanned: Bool?
    let rating: Float?
}

