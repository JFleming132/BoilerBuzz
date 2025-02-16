//
//  DrinksDetailView.swift
//  BoilerBuzz
//
//  Created by user272845 on 2/11/25.
//

import SwiftUI

struct Drink: Identifiable, Codable {
    let id = UUID() // Unique ID for SwiftUI
    let drinkID: Int
    let name: String
    let description: String
    let ingredients: [String]
    let averageRating: Int
    let barServed: String
    let category: [String]
    let calories: Int
}

struct DrinksDetailView: View {
    @State private var drinks: [Drink] = []       // List of drinks
    @State private var selectedDrink: Drink? = nil // Currently selected drink for the popup
    @State private var errorMessage: String? = nil // Error message for API failures

    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                // Show error message if API fails
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                ScrollView {
                    // Grid layout for drinks
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(drinks) { drink in
                            Button(action: {
                                selectedDrink = drink // Show popup for selected drink
                            }) {
                                VStack(spacing: 8) {
                                    // Display category icon
                                    Image(systemName: getCategoryIcon(for: drink.category.first ?? "default"))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.white)

                                    // Display drink name
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
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            fetchDrinks() // Fetch drinks from the API when the view appears
        }
        // Popup for drink details
        .sheet(item: $selectedDrink) { drink in
            DrinkDetailsPopup(drink: drink)
        }
    }

    // Fetch drinks from your Node.js API and randomize the order
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

                    // Randomize the drinks order
                    decodedDrinks.shuffle()

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
    @State private var isChecked: Bool = false // Track the checked state

    var body: some View {
        ScrollView { // Make the entire popup scrollable
            VStack(alignment: .center, spacing: 16) {
                HStack {
                    Spacer()
                    // Checkmark button in the top-right corner
                    Button(action: {
                        isChecked.toggle() // Toggle the checked state
                    }) {
                        Image(systemName: isChecked ? "checkmark.circle.fill" : "checkmark.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(isChecked ? .green : .gray)
                    }
                }
                .padding(.top, 10)
                
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
