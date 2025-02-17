//
//  DrinksDetailView.swift
//  BoilerBuzz
//
//  Created by user272845 on 2/11/25.
//

import SwiftUI

struct Drink: Identifiable, Codable {
    let id = UUID() // Unique ID for SwiftUI
    let objectID: String
    let drinkID: Int
    let name: String
    let description: String
    let ingredients: [String]
    let averageRating: Int
    let barServed: String
    let category: [String]
    let calories: Int
    
    enum CodingKeys: String, CodingKey {
        case objectID = "_id" // Map the _id from JSON to objectID in the struct
        case drinkID
        case name
        case description
        case ingredients
        case averageRating
        case barServed
        case category
        case calories
    }
}

struct DrinksDetailView: View {
    @State private var drinks: [Drink] = []
    @State private var selectedDrink: Drink? = nil
    @State private var errorMessage: String? = nil
    @State private var triedDrinks: Set<String> = [] // Track selected drinks by objectID

    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(drinks) { drink in
                            ZStack(alignment: .topTrailing) {
                                Button(action: {
                                    selectedDrink = drink // Only this triggers the details popup
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: getCategoryIcon(for: drink.category.first ?? "default"))
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.white)

                                        Text(drink.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                                }

                                Button(action: {
                                    toggleDrinkSelection(objectID: drink.objectID)
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(triedDrinks.contains(drink.objectID) ? .green : .gray)
                                        .padding(5)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            fetchDrinks()
            fetchTriedDrinks()
        }
        .sheet(item: $selectedDrink) { drink in
            DrinkDetailsPopup(drink: drink)
        }
    }
    
    func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: "userId")
    }
    
    func toggleDrinkSelection(objectID: String) {
        guard let userId = getUserId() else {
            print("User ID not found")
            return
        }

        let url = URL(string: "http://localhost:3000/api/drinks/toggleTriedDrink")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["userId": userId, "objectID": objectID] // Use objectID

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Failed to serialize JSON:", error)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error toggling drink:", error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response:", response ?? "No response")
                return
            }

            DispatchQueue.main.async {
                if self.triedDrinks.contains(objectID) {
                    self.triedDrinks.remove(objectID)
                } else {
                    self.triedDrinks.insert(objectID)
                }
            }
        }

        task.resume()
    }
    
    func fetchTriedDrinks() {
        guard let userId = getUserId() else {
            print("User ID not found")
            return
        }

        // Define the URL for fetching tried drinks
        guard let url = URL(string: "http://localhost:3000/api/drinks/triedDrinks/\(userId)") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Failed to fetch tried drinks: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received from the server."
                }
                return
            }

            do {
                // Decode the response into a dictionary with a triedDrinks key
                let response = try JSONDecoder().decode([String: [String]].self, from: data)
                if let responseDrinks = response["triedDrinks"] {
                    DispatchQueue.main.async {
                        // Update the selectedDrinks set with the objectIDs from the triedDrinks
                        self.triedDrinks = Set(responseDrinks)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to decode tried drinks: \(error.localizedDescription)"
                }
            }
        }.resume()
    }


    func fetchDrinks() {
        guard let url = URL(string: "http://localhost:3000/api/auth/drinks") else {
            errorMessage = "Invalid URL"
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Failed to fetch drinks: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received from the server."
                }
                return
            }

            do {
                // Decode JSON into a general structure first
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    // Filter out drinks with `image_id`
                    let filteredJson = json.filter { $0["image_id"] == nil }
                    let filteredData = try JSONSerialization.data(withJSONObject: filteredJson, options: [])

                    // Decode filtered JSON into Drink objects
                    var decodedDrinks = try JSONDecoder().decode([Drink].self, from: filteredData)

                    // Sort the drinks array alphabetically by name
                    decodedDrinks.sort { $0.name.lowercased() < $1.name.lowercased() }

                    DispatchQueue.main.async {
                        self.drinks = decodedDrinks
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to decode drinks: \(error.localizedDescription)"
                }
            }
        }.resume()
    }


    // Get an appropriate SF Symbol for the drink's category
    func getCategoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "vodka-based":
            return "drop.fill"
        case "cocktail":
            return "wineglass"
        case "scotch-based":
            return "flame"
        case "tequila-based":
            return "leaf"
        case "gin-based":
            return "leaf.arrow.circlepath"
        case "rum-based":
            return "sailboat.fill"
        case "shot":
            return "cup.and.saucer.fill"
        case "whiskey":
            return "flame.fill"
        case "beer":
            return "mug.fill"
        case "harrys":
            return "sparkles"
        case "nine irish brothers":
            return "globe.americas.fill"
        case "cider":
            return "leaf.fill"
        default:
            return "questionmark.circle"
        }
    }
}


struct DrinkDetailsPopup: View {
    let drink: Drink
    @Environment(\.dismiss) var dismiss // Access the dismiss environment action

    var body: some View {
        ScrollView { // Make the entire popup scrollable
            VStack(alignment: .center, spacing: 16) {
                // Add a hero category icon
                Image(systemName: getCategoryIcon(for: drink.category.first ?? "default"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color.blue)

                Text(drink.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Description:")
                    .font(.headline)
                Text(drink.description)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true) // Ensures text wraps

                Text("Calories: \(drink.calories)")
                Text("Average Rating: \(drink.averageRating)")

                Text("Ingredients:")
                    .font(.headline)
                ForEach(drink.ingredients, id: \.self) { ingredient in
                    Text("- \(ingredient)")
                }

                Spacer()

                Button(action: {
                    dismiss() // Close the popup
                }) {
                    Text("Close")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
    }

    // Get an appropriate SF Symbol for the drink's category
    func getCategoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "vodka-based":
            return "drop.fill"
        case "cocktail":
            return "wineglass"
        case "scotch-based":
            return "flame"
        case "tequila-based":
            return "leaf"
        case "gin-based":
            return "leaf.arrow.circlepath"
        case "rum-based":
            return "sailboat.fill"
        case "shot":
            return "cup.and.saucer.fill"
        case "whiskey":
            return "flame.fill"
        case "beer":
            return "mug.fill"
        case "harrys":
            return "sparkles"
        case "nine irish brothers":
            return "globe.americas.fill"
        case "cider":
            return "leaf.fill"
        default:
            return "questionmark.circle"
        }
    }
}
