//
//  FavoritedDrinksPopup.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/17/25.
//


import SwiftUI

struct FavoritedDrinksPopup: View {
    var isMyProfile: Bool      // True if viewing your own profile
    var userId: String         // The user id whose favorites to fetch
    
    @State private var drinks: [Drink] = []
    @State private var errorMessage: String? = nil
    @State private var error = true
    @State private var selectedDrink: Drink? = nil

    var body: some View {
        NavigationView {
            Group {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(error ? .red : .black)
                        .padding()
                } else {
                    List(drinks) { drink in
                        Button(action: {
                            selectedDrink = drink
                        }) {
                            HStack {
                                Image(systemName: getCategoryIcon(for: drink.category.first ?? "default"))
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(drink.name)
                                        .font(.headline)
                                    Text("\(drink.calories) cal")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Favorite Drinks")
                        .font(.system(size: 18, weight: .semibold))
                }
                if isMyProfile {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: DrinksDetailView()) {
                            Text("Add Drink")
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchFavoriteDrinks()
            print("Fetching favorite drinks")
        }
        // Refresh data when updated in popup
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FavoriteDrinksUpdated"))) { _ in
                    fetchFavoriteDrinks()
                    print("Received notification")
                }
        .sheet(item: $selectedDrink) { drink in
            DrinkDetailsPopup(drink: drink)
        }
    }
    
    func fetchFavoriteDrinks() { //TODO: This function fails if the retrieved JSON does not STRICTLY adhere to the type Drink,
        //Even if it only needs to display the name and icon.
        //Either fix it, or ensure all drinks in the database can be decoded
        guard let url = URL(string: "\(backendURL)api/drinks/favoriteDrinks/\(userId)") else {
            errorMessage = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Error fetching favorites: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received from server."
                }
                return
            }
            
            // Debug: print the raw JSON string
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Favorite Drinks JSON Response: \(jsonString)")
            }
            
            let fetchedDrinks = decodeDrinksSafely(from: data)
            
            DispatchQueue.main.async {
                if fetchedDrinks.isEmpty {
                    let message = isMyProfile ? "You do not have any favorite drinks." : "They do not have any favorite drinks."
                    errorMessage = message
                    self.drinks = []
                    self.error = false
                } else {
                    self.drinks = fetchedDrinks
                    errorMessage = nil
                }
            }
        }.resume()
    }

    
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

struct FavoritedDrinksPopup_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FavoritedDrinksPopup(isMyProfile: true, userId: "67b3905fd41f8758ccbe2714")
        }
    }
}


func decodeDrinksSafely(from data: Data) -> [Drink] {
    // First try to decode the raw JSON as an array of Any
    guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
        return []
    }
    
    let decoder = JSONDecoder()
    // If your backend uses snake_case keys, uncomment the next line:
    // decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    // Attempt to decode each object and return only those that decode successfully.
    return jsonArray.compactMap { object in
        if let objectData = try? JSONSerialization.data(withJSONObject: object) {
            return try? decoder.decode(Drink.self, from: objectData)
        }
        return nil
    }
}
