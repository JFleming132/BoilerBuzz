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
    @State private var drinks: [Drink] = [] // List of drinks fetched
    @State private var selectedDrink: Drink? = nil // Currently selected drink for the popup
    @State private var randomDrink: Drink? = nil // Random drink to display
    @State private var showRandomDrink: Bool = false // Show random drink popup
    @State private var confettiTrigger: Int = 0 // Confetti trigger
    @State private var errorMessage: String? = nil // Error message for API failures

    var body: some View {
        ZStack {
            VStack {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 160))], // Dynamic columns
                            spacing: 16
                        ) {
                            ForEach(drinks) { drink in
                                Button(action: {
                                    selectedDrink = drink // Show drink details popup
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: getCategoryIcon(for: drink.category.first ?? "default"))
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.white)
                                            .shadow(color: .yellow, radius: 10, x: 0, y: 0) // Glow effect

                                        Text(drink.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .shadow(color: .yellow, radius: 10, x: 0, y: 0) // Glow effect
                                    }
                                    .padding()
                                    .frame(width: 160, height: 160) // Fixed size for buttons
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
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
            .sheet(item: $selectedDrink) { drink in
                DrinkDetailsPopup(drink: drink)
            }

            // Overlay for the random drink popup
            if showRandomDrink, let randomDrink = randomDrink {
                VStack(spacing: 16) {
                    Text("Random Drink!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.yellow)
                    
                    Image(systemName: getCategoryIcon(for: randomDrink.category.first ?? "default"))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(Color(UIColor.darkGray))

                    Text(randomDrink.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.darkGray))

                    Text(randomDrink.description)
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
                .onTapGesture {
                    withAnimation {
                        showRandomDrink = false
                    }
                }
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
        }
        .background(ShakeDetector {
            showRandomDrinkAnimation() // Handle the shake gesture
        })
    }

    private func showRandomDrinkAnimation() {
        guard !drinks.isEmpty else { return }

        randomDrink = drinks.randomElement()
        withAnimation {
            showRandomDrink = true
        }
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
                let decodedDrinks = try JSONDecoder().decode([Drink].self, from: data)
                DispatchQueue.main.async {
                    self.drinks = decodedDrinks.shuffled()
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to decode drinks: \(error.localizedDescription)"
                }
            }
        }.resume()
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

