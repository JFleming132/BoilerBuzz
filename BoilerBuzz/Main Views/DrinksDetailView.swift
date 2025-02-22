//
//  DrinksDetailView.swift
//  BoilerBuzz
//
//  Created by user272845 on 2/11/25.
//

import SwiftUI
import ConfettiSwiftUI

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
    @State private var drinks: [Drink] = [] // List of drinks fetched
    @State private var selectedDrink: Drink? = nil // Currently selected drink for the popup
    @State private var randomDrink: Drink? = nil // Random drink to display
    @State private var showRandomDrink: Bool = false // Show random drink popup
    @State private var confettiTrigger: Int = 0 // Confetti trigger
    @State private var errorMessage: String? = nil // Error message for API failures
    @State private var triedDrinks: Set<String> = [] // Track selected drinks by objectID

    var body: some View {
            ZStack {
                VStack {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        drinksGrid
                    }
                }
                .onAppear {
                    fetchDrinks()
                    fetchTriedDrinks()
                }
                .sheet(item: $selectedDrink) { drink in
                    DrinkDetailsPopup(drink: drink)
                }

                if showRandomDrink, let randomDrink = randomDrink {
                    randomDrinkPopup(drink: randomDrink)
                }
            }
            .background(ShakeDetector { showRandomDrinkAnimation() })
        }

    private var drinksGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                ForEach(drinks) { drink in
                    drinkButton(drink: drink) // Each button contains the checkmark
                }
            }
            .padding()
        }
    }


    private func drinkButton(drink: Drink) -> some View {
        ZStack(alignment: .topTrailing) { // Ensures checkmark is inside the button
            Button(action: { selectedDrink = drink }) {
                VStack(spacing: 8) {
                    Image(systemName: getCategoryIcon(for: drink.category.first ?? "default"))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .shadow(color: .yellow, radius: 10, x: 0, y: 0)
                    Text(drink.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .yellow, radius: 10, x: 0, y: 0)
                }
                .padding()
                .frame(width: 160, height: 160)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                   startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            // Embed the checkmark inside the drink button
            checkmarkButton(drink: drink)
                .offset(x: -8, y: 8) // Positioning inside the top-right corner
        }
    }

    private func checkmarkButton(drink: Drink) -> some View {
        Button(action: { toggleDrinkSelection(objectID: drink.objectID) }) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(triedDrinks.contains(drink.objectID) ? .green : .gray) // Toggles color
                .background(Circle().fill(Color.white)) // Adds contrast to be visible
                .padding(6) // Space from the edges
        }
    }


        private func randomDrinkPopup(drink: Drink) -> some View {
            VStack(spacing: 16) {
                Text("Drink!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.yellow)
                Image(systemName: getCategoryIcon(for: drink.category.first ?? "default"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(UIColor.darkGray))
                Text(drink.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.darkGray))
                Text(drink.description)
                    .font(.body)
                    .foregroundColor(Color(UIColor.darkGray))
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
            )
            .onTapGesture { withAnimation { showRandomDrink = false } }
            .confettiCannon(
                trigger: $confettiTrigger,
                num: 50,
                confettis: [.text("🍹"), .text("🍸"), .text("🍺"), .text("🥂")],
                confettiSize: 35,
                radius: 300.0
            )
            .transition(.scale)
            .onAppear {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    confettiTrigger += 1
                }
            }
        }

    private func showRandomDrinkAnimation() {
        guard !drinks.isEmpty else { return }

        randomDrink = drinks.randomElement()
        withAnimation {
            showRandomDrink = true
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
                        // Filter out drinks with image_id
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
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.gray.opacity(0.7)
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: getCategoryIcon(for: drink.category.first ?? "default"))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(Color.black)

                    Text(drink.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.black)

                    Divider()

                    Text("Description:")
                        .font(.headline)
                        .foregroundColor(Color.black)
                    Text(drink.description)
                        .font(.body)
                        .foregroundColor(Color.black)

                    Text("Calories: \(drink.calories)")
                        .font(.subheadline)
                        .foregroundColor(Color.black)
                    Text("Average Rating: \(drink.averageRating)")
                        .font(.subheadline)
                        .foregroundColor(Color.black)

                    Text("Ingredients:")
                        .font(.headline)
                        .foregroundColor(Color.black)
                    ForEach(drink.ingredients, id: \.self) { ingredient in
                        Text("- \(ingredient)")
                            .font(.body)
                            .foregroundColor(Color.black)
                    }

                    Spacer()

                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.yellow)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemGray6))
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
                )
                .padding()
            }
            .padding(.horizontal, 16)
        }
    }

    func getCategoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "vodka-based": return "drop.fill"
        case "cocktail": return "wineglass"
        case "scotch-based": return "flame"
        case "tequila-based": return "leaf"
        case "gin-based": return "leaf.arrow.circlepath"
        case "rum-based": return "sailboat.fill"
        case "shot": return "cup.and.saucer.fill"
        case "whiskey": return "flame.fill"
        case "beer": return "mug.fill"
        case "harrys": return "sparkles"
        case "nine irish brothers": return "globe.americas.fill"
        case "cider": return "leaf.fill"
        default: return "questionmark.circle"
        }
    }
}
