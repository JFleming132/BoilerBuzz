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
    @Published var isPromoted: Bool = false

    @Published var rating: Float = 0.0
    @Published var ratingCount: Int = 0
    @Published var userEvents: [Event] = []
    @Published var userPhotos: [Photo] = []
    @Published var isOnCampus: Bool = false
    @Published var campusStatusLastChecked: Date? = nil
    @Published var isBanned: Bool = false

    // MARK: - Fetch Profile Data

    func fetchUserProfile(userId: String? = nil) {
        // Use provided userId, else self.userId, else fallback to logged-in user
        let idToFetch: String
        if let provided = userId {
            idToFetch = provided
        } else if !self.userId.isEmpty {
            idToFetch = self.userId
        } else if let storedUserId = UserDefaults.standard.string(forKey: "userId") {
            idToFetch = storedUserId
        } else {
            print("No userId stored, user may not be logged in")
            return
        }

        self.userId = idToFetch
        guard let url = URL(string: "\(backendURL)api/profile/\(idToFetch)") else {

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
                    self.profilePicture = decodedResponse.profilePicture.imageFromBase64 ?? UIImage(systemName: "person.crop.circle.fill")!
                    self.isAdmin = decodedResponse.isAdmin ?? false
                    self.isBanned = decodedResponse.isBanned ?? false
                    self.isPromoted = decodedResponse.isPromoted ?? false
                    self.rating = decodedResponse.rating ?? 0.0
                    self.ratingCount = decodedResponse.ratingCount ?? 0
                }
            } catch {
                print("Error decoding profile data: \(error)")
            }
        }.resume()
    }

    // MARK: - Fetch User Events

    func fetchUserEvents(userId: String? = nil) {
        // Always use the correct userId (profile being viewed)
        let idToFetch: String
        if let provided = userId {
            idToFetch = provided
        } else if !self.userId.isEmpty {
            idToFetch = self.userId
        } else if let storedUserId = UserDefaults.standard.string(forKey: "userId") {
            idToFetch = storedUserId
        } else {
            print("User ID not found")
            return
        }

        let urlString = "\(backendURL)api/home/events/byUser/\(idToFetch)"
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
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970
                let events = try decoder.decode([Event].self, from: data)
                DispatchQueue.main.async {
                    self.userEvents = events
                }
            } catch {
                print("Error decoding events: \(error.localizedDescription)")
            }
        }.resume()
    }


    func fetchUserPhotos(userId: String? = nil) {
        let idToFetch: String
        if let provided = userId {
            idToFetch = provided
        } else if !self.userId.isEmpty {
            idToFetch = self.userId
        } else if let storedUserId = UserDefaults.standard.string(forKey: "userId") {
            idToFetch = storedUserId
        } else {
            print("User ID not found")
            return
        }

        let urlString = "\(backendURL)api/photo/byUser/\(idToFetch)"

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
                DispatchQueue.main.async {
                    self.userPhotos = photos
                }
            } catch {
                print("Error decoding photos: \(error.localizedDescription)")
            }
        }.resume()
    }

    // MARK: - Fetch Campus Status

    func fetchCampusStatus(userId: String? = nil) {
        let idToFetch: String
        if let provided = userId {
            idToFetch = provided
        } else if !self.userId.isEmpty {
            idToFetch = self.userId
        } else if let storedUserId = UserDefaults.standard.string(forKey: "userId") {
            idToFetch = storedUserId
        } else {
            print("User ID not found")
            return
        }

        guard let url = URL(string: "http://localhost:3000/api/users/\(idToFetch)/campus-status") else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch campus status")
                return
            }
            if let rawJSON = String(data: data, encoding: .utf8) {
                print("Raw API Response:", rawJSON)
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decoded = try decoder.decode(CampusStatusResponse.self, from: data)
                DispatchQueue.main.async {
                    self.isOnCampus = decoded.isOnCampus
                    self.campusStatusLastChecked = decoded.lastChecked
                }
            } catch {
                print("Decoding error:", error)
            }
        }
        task.resume()
    }
}

// MARK: - Supporting Models

struct Profile: Codable {
    let username: String
    let bio: String
    let profilePicture: String
    let isAdmin: Bool?
    let isBanned: Bool?
    let isPromoted: Bool?
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

struct CampusStatusResponse: Codable {
    let isOnCampus: Bool
    let lastChecked: Date?
    let lastLocation: LocationData?

    enum CodingKeys: String, CodingKey {
        case isOnCampus, lastChecked, lastLocation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isOnCampus = try container.decode(Bool.self, forKey: .isOnCampus)

        // Manually decode the date
        let dateString = try container.decode(String.self, forKey: .lastChecked)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        lastChecked = formatter.date(from: dateString)

        lastLocation = try container.decodeIfPresent(LocationData.self, forKey: .lastLocation)
    }
}

struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
}

// MARK: - UIImage Extension for Base64 Decoding


