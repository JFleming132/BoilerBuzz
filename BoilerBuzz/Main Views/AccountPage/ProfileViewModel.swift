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
    @Published var ratingCount: Int = 0
    @Published var userEvents: [Event] = []
    @Published var userPhotos: [Photo] = []
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
        
        guard let url = URL(string: "http://10.1.54.171:3000/api/profile/\(idToFetch)") else {
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

                    self.ratingCount = decodedResponse.ratingCount ?? 0

                }
            } catch {
                print("Error decoding profile data: \(error)")
            }
        }.resume()
    }

    func fetchUserEvents() {
        // Should be able to fetch events by any user id
        let idToFetch: String
        if self.userId.isEmpty {
            guard let storedUserId = UserDefaults.standard.string(forKey: "userId") else {
                print("User ID not found")
                return
            }
            idToFetch = storedUserId
        } else {
            idToFetch = self.userId
        }

        let urlString = "http://localhost:3000/api/home/events/byUser/\(idToFetch)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching events: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received from events endpoint.")
                return
            }
            
            // // Print the raw response string for debugging
            // if let responseString = String(data: data, encoding: .utf8) {
            //     print("Raw response from events endpoint: \(responseString)")
            // }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970
                let events = try decoder.decode([Event].self, from: data)
                print("Decoded events: \(events)")
                DispatchQueue.main.async {
                    self.userEvents = events
                }
            } catch {
                print("Error decoding events: \(error.localizedDescription)")
            }
        }.resume()
    }

    func fetchUserPhotos() {
        // Use the current profile's userId if available, else fallback to logged-in user's id.
        let idToFetch: String = self.userId.isEmpty ? (UserDefaults.standard.string(forKey: "userId") ?? "") : self.userId
        
        let urlString = "http://localhost:3000/api/photo/byUser/\(idToFetch)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching photos: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received from photos endpoint.")
                return
            }
            do {
                let photos = try JSONDecoder().decode([Photo].self, from: data)
                // print("Decoded photos: \(photos)")
                DispatchQueue.main.async {
                    self.userPhotos = photos
                }
            } catch {
                print("Error decoding photos: \(error.localizedDescription)")
            }
        }.resume()
    }


}

struct Profile: Codable {
    let username: String
    let bio: String
    let profilePicture: String
    let isAdmin: Bool?
    let isBanned: Bool?
    let rating: Float?
    let ratingCount: Int?
}

struct Photo: Identifiable, Codable {
    let id: String
    let url: String
    let optimizedUrl: String?
    let autoCropUrl: String?
    let creator: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case url
        case optimizedUrl
        case autoCropUrl
        case creator
        case createdAt
    }
}