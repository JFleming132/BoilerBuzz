//
//  DrinksDetailView.swift
//  BoilerBuzz
//
//  Created by user272845 on 2/11/25.
//

import SwiftUI
import ConfettiSwiftUI

struct Drink: Identifiable, Codable {
    let id = UUID()
    let objectID: String
    let drinkID: Int
    let name: String
    let description: String
    let ingredients: [String]
    var averageRating: Int
    let barServed: String
    let category: [String]
    let calories: Int
    
    enum CodingKeys: String, CodingKey {
        case objectID = "_id"
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

struct TriedDrink: Codable {
    let objectId: String
    let rating: Int
}

//test filter logic
func filterDrinks(
    from drinks: [Drink],
    selectedCategory: String?,
    selectedBase: String?,
    minCalories: Int?,
    maxCalories: Int?,
    minRating: Int?,
    selectedBar: String?) -> [Drink] {
    return drinks.filter { drink in
        let categoryMatches = selectedCategory == nil ||
            selectedCategory == "All" ||
            drink.category.contains(selectedCategory!)
        
        let baseMatches = selectedBase == nil ||
            selectedBase == "All" ||
            drink.category.contains(selectedBase!)
        
        let minCaloriesMatches = minCalories.map { drink.calories >= $0 } ?? true
        let maxCaloriesMatches = maxCalories.map { drink.calories <= $0 } ?? true
        let ratingMatches = minRating.map { drink.averageRating >= $0 } ?? true
        let barMatches = selectedBar == nil ||
                    selectedBar == "All" ||
                    drink.barServed == selectedBar
        return categoryMatches && baseMatches && minCaloriesMatches && maxCaloriesMatches && ratingMatches && barMatches
    }
}

//test sort logic
func sortDrinks(
    from drinks: [Drink],
    withSortOption sortOption: String?,
    triedDrinks: Set<String>
) -> [Drink] {
    switch sortOption {
    case "A to Z":
        return drinks.sorted { $0.name < $1.name }
    case "Z to A":
        return drinks.sorted { $0.name > $1.name }
    case "Lowest Calorie First":
        return drinks.sorted { $0.calories < $1.calories }
    case "Highest Calorie First":
        return drinks.sorted { $0.calories > $1.calories }
    case "Lowest Average Rating First":
        return drinks.sorted { $0.averageRating < $1.averageRating }
    case "Highest Average Rating First":
        return drinks.sorted { $0.averageRating > $1.averageRating }
    case "Tried Drinks First":
        // Drinks that are tried should appear before those that are not tried.
        return drinks.sorted {
            let firstTried = triedDrinks.contains($0.objectID)
            let secondTried = triedDrinks.contains($1.objectID)
            // If one is tried and the other isn't, the tried one comes first.
            if firstTried != secondTried {
                return firstTried && !secondTried
            }
            // Otherwise, keep the original order or sort by name.
            return $0.name < $1.name
        }
    case "Tried Drinks Last":
        // Drinks that are tried should appear after those that are not tried.
        return drinks.sorted {
            let firstTried = triedDrinks.contains($0.objectID)
            let secondTried = triedDrinks.contains($1.objectID)
            if firstTried != secondTried {
                return !firstTried && secondTried
            }
            return $0.name < $1.name
        }
    default:
        return drinks
    }
}



struct DrinksDetailView: View {
    @State private var drinks: [Drink] = []
    @State private var selectedDrink: Drink? = nil
    @State private var randomDrink: Drink? = nil
    @State private var showRandomDrink: Bool = false
    @State private var confettiTrigger: Int = 0
    @State private var errorMessage: String? = nil
    @State private var triedDrinks: Set<String> = []
    @State private var showRatingPopup = false
    @State private var drinkToRate: Drink? = nil
    @State private var tempRating: Int = 0
    

    // Filter states
    @State private var selectedCategory: String? = nil
    @State private var selectedBase: String? = nil
    @State private var minCalories: Int? = nil
    @State private var maxCalories: Int? = nil
    @State private var minRating: Int? = nil
    @State private var showFilterSidebar: Bool = false

    // Temporary filter states
    @State private var tempSelectedCategory: String? = nil
    @State private var tempSelectedBase: String? = nil
    @State private var tempMinCalories: Int? = nil
    @State private var tempMaxCalories: Int? = nil
    @State private var tempMinRating: Int? = nil

    
    @State private var triedDrinksRatings: [String: Int] = [:]
    
    @State private var showSortingSidebar: Bool = false
    @State private var selectedSortOption: String? = nil


    @State private var selectedBar: Int = 0
    let barOptions = ["All Bars", "The Tap", "Neon Cactus", "Where Else", "Brothers", "9irish", "Harry's"]
    

    let drinkCategories: [String: [String]] = [
        "Cocktail": ["Vodka-Based", "Gin-Based", "Rum-Based", "Whiskey-Based", "Scotch-Based", "Tequila-Based", "Brandy-Based", "Champagne-Based", "Other"],
        "Beer": ["IPA", "Stout", "Porter", "Lager", "Pilsner", "Pale Ale", "Brown Ale", "Belgian", "Sour", "Light", "Fruit"],
        "Cider": ["Fruity", "Dry", "Berry Cider"],
        "Shot": ["High-Energy", "Citrus", "Layered", "Whiskey", "Fruity", "Herbal"]
    ]
    
    var filteredDrinks: [Drink] {
        drinks.filter { drink in
            (selectedCategory == nil || drink.category.contains(selectedCategory!)) &&
            (selectedBase == nil || drink.category.contains(selectedBase!)) &&
            (minCalories == nil || drink.calories >= minCalories!) &&
            (maxCalories == nil || drink.calories <= maxCalories!) &&
            (minRating == nil || drink.averageRating >= minRating!) &&
            //new filter logic
            (selectedBar == 0 || (drink.barServed.count >= selectedBar && drink.barServed[drink.barServed.index(drink.barServed.startIndex, offsetBy: selectedBar - 1)] == "1"))
        }
    }

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: { showFilterSidebar.toggle() }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                    }
                    
                    Spacer()
                    Picker("Select Bar", selection: $selectedBar) {
                        ForEach(barOptions.indices, id: \.self) { index in
                            Text(barOptions[index]).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                    Spacer()
                    Button(action: { showSortingSidebar.toggle() }) {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                    }
                }


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
            
            // Sidebar Filter Menu
            if showFilterSidebar {
                filterSidebar
            }
            
            if showRatingPopup {
                drinkRatingPopup
            }
            
            if showSortingSidebar {
                sortingSidebar
            }
            
            if showRandomDrink, let randomDrink = randomDrink {
                randomDrinkPopup(drink: randomDrink)
            }
        }
        .animation(.easeInOut, value: showFilterSidebar)
        .animation(.easeInOut, value: showSortingSidebar)
        .background(ShakeDetector{ showRandomDrinkAnimation() })
    }
    
    private var filterSidebar: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Filters")
                        .font(.headline)
                    Spacer()
                    Button(action: { showFilterSidebar = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .imageScale(.large)
                    }
                }
                .padding()
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Drink Type")
                        .font(.subheadline)
                        .bold()
                    Picker("Drink Type", selection: $tempSelectedCategory) {
                        Text("All").tag(nil as String?)
                        ForEach(drinkCategories.keys.sorted(), id: \.self) { category in
                            Text(category).tag(category as String?)
                                .lineLimit(1)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                    .frame(maxWidth: .infinity)
                    
                    if let category = tempSelectedCategory, let bases = drinkCategories[category] {
                        Text("Base")
                            .font(.subheadline)
                            .bold()
                        Picker("Base", selection: $tempSelectedBase) {
                            Text("All").tag(nil as String?)
                            ForEach(bases, id: \.self) { base in
                                Text(base).tag(base as String?)
                                    .lineLimit(1)  // Prevent wrapping in the options
                            }
                        }
                        .pickerStyle(DefaultPickerStyle())  // Use DefaultPickerStyle here
                        .frame(maxWidth: .infinity)  // Make Picker fill available space
                    }
                    
                    Text("Calories")
                        .font(.subheadline)
                        .bold()
                    HStack {
                        TextField("Min", value: $tempMinCalories, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Max", value: $tempMaxCalories, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Text("Minimum Rating")
                        .font(.subheadline)
                        .bold()
                    TextField("Min Rating", value: $tempMinRating, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        // Save the temporary filter values to the actual filter state
                        selectedCategory = tempSelectedCategory
                        selectedBase = tempSelectedBase
                        minCalories = tempMinCalories
                        maxCalories = tempMaxCalories
                        minRating = tempMinRating
                        
                        print(selectedCategory)
                        showFilterSidebar = false
                    }) {
                        Text("Save Filters")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.black)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(tertiaryColor, lineWidth: 2)
                            )
                        }
                    }
                .padding()
                
                Spacer()
            }
            .frame(width: 300, height: 500)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 10)
        }
    }
    
    var sortedDrinks: [Drink] {
        let sorted = filteredDrinks
        switch selectedSortOption {
        case "A to Z":
            return sorted.sorted { $0.name < $1.name }
        case "Z to A":
            return sorted.sorted { $0.name > $1.name }
        case "Lowest Calorie First":
            return sorted.sorted { $0.calories < $1.calories }
        case "Highest Calorie First":
            return sorted.sorted { $0.calories > $1.calories }
        case "Lowest Average Rating First":
            return sorted.sorted { $0.averageRating < $1.averageRating }
        case "Highest Average Rating First":
            return sorted.sorted { $0.averageRating > $1.averageRating }
        case "Tried Drinks First":
            return sorted.sorted { triedDrinks.contains($0.objectID) && !triedDrinks.contains($1.objectID) }
        case "Tried Drinks Last":
            return sorted.sorted { !triedDrinks.contains($0.objectID) && triedDrinks.contains($1.objectID) }
        default:
            return sorted
        }
    }
    
    private var sortingSidebar: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showSortingSidebar = false
                }

            VStack(alignment: .leading) {
                HStack {
                    Text("Sort Drinks")
                        .font(.headline)
                        .foregroundColor(Color.primary)
                    Spacer()
                }
                .padding()

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    ForEach([
                        "A to Z",
                        "Z to A",
                        "Lowest Calorie First",
                        "Highest Calorie First",
                        "Lowest Average Rating First",
                        "Highest Average Rating First",
                        "Tried Drinks First",
                        "Tried Drinks Last"
                    ], id: \.self) { option in
                        Button(action: {
                            selectedSortOption = option
                            drinks = sortedDrinks
                            showSortingSidebar = false
                        }) {
                            HStack {
                                Text(option)
                                    .font(.body)
                                    .foregroundColor(Color.primary)
                                Spacer()
                                if selectedSortOption == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()

                Spacer()
            }
            .frame(width: 300, height: 450)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 10)
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.height > 100 {
                            showSortingSidebar = false
                        }
                    }
            )
        }
    }



    private var drinksGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                ForEach(filteredDrinks) { drink in
                    drinkButton(drink: drink)
                }
            }
            .padding()
        }
    }



    private func drinkButton(drink: Drink) -> some View {
        ZStack(alignment: .topTrailing) { // Ensures checkmark is inside the button
            VStack(spacing: 6) { // Reduced spacing to prevent expansion
                Button(action: { selectedDrink = drink }) {
                    VStack(spacing: 4) { // Minimized spacing to maintain box size
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

                        // Display stars only if the drink has been rated
                        if let rating = triedDrinksRatings[drink.objectID] {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= rating ? "star.fill" : "star")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12) // Smaller stars
                                        .foregroundColor(.green) // Green stars
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4) // Keep padding minimal to avoid expansion
                    .frame(width: 160, height: 160)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }

            // Embed the checkmark inside the drink button
            checkmarkButton(drink: drink)
                .offset(x: -8, y: 8) // Positioning inside the top-right corner
        }
    }

    func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: "userId")
    }

    private func checkmarkButton(drink: Drink) -> some View {
        Button(action: {

            // Show the rating popup when toggled to green
            if !triedDrinks.contains(drink.objectID) {
                drinkToRate = drink
                showRatingPopup = true
            }
            else {
                guard let userId = getUserId() else {
                    print("User ID not found")
                    return
                }
                toggleDrinkSelection(objectID: drink.objectID, userId: userId)
            }
        }) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(triedDrinks.contains(drink.objectID) ? .green : .gray)
                .background(Circle().fill(Color.white))
                .padding(6)
        }
    }
    
    private var drinkRatingPopup: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                // Drink name with appropriate font size
                Text("Please rate the")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Text("\"\(drinkToRate?.name ?? "this drink")\"")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Star rating input (5 stars max)
                HStack {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= tempRating ? "star.fill" : "star")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                            .foregroundColor(i <= tempRating ? tertiaryColor : .gray)
                            .onTapGesture {
                                tempRating = i
                            }
                    }
                }
                .padding(.vertical, 8)

                // Submit and Close button
                Button(action: {
                    showRatingPopup = false
                    
                    
                    if let drink = drinkToRate {
                        guard let userId = getUserId() else {
                            print("User ID not found")
                            return
                        }
                        toggleDrinkSelection(objectID: drink.objectID, userId: userId)
                    }
                }) {
                    Text("Submit")
                        .font(.headline)
                        .foregroundColor(tertiaryColor)
                        .padding()
                        .background(.black)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(tertiaryColor, lineWidth: 2)
                        )
                }
                .padding()
            }
            .frame(width: 280, height: 310)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 8)
        }
    }

    private func randomDrinkPopup(drink: Drink) -> some View {
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark // Manually detect Dark Mode
        
        return VStack(spacing: 16) {
            Text("Drink!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.yellow)
            
            Image(systemName: getCategoryIcon(for: drink.category.first ?? "default"))
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(isDarkMode ? Color.white : Color(UIColor.darkGray)) // Adaptive icon color
            
            Text(drink.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(isDarkMode ? Color.white : Color(UIColor.darkGray)) // Adaptive text color
            
            Text(drink.description)
                .font(.body)
                .foregroundColor(isDarkMode ? Color.gray : Color(UIColor.darkGray))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color.black : Color.white) // Adaptive background
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
        let availableDrinks = filteredDrinks.isEmpty ? drinks : filteredDrinks // Use filtered drinks if available, otherwise use all drinks
        
        guard !availableDrinks.isEmpty else { return } // Ensure there are drinks to choose from

        randomDrink = availableDrinks.randomElement() // Pick a random drink from the available list
        withAnimation {
            showRandomDrink = true
        }
    }


    
    struct ToggleDrinkResponse: Codable {
        let success: Bool
        let averageRating: Int
    }

    
    func toggleDrinkSelection(objectID: String, userId: String) {
        let url = URL(string: "http://localhost:3000/api/drinks/toggleTriedDrink")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["userId": userId, "objectId": objectID, "rating": tempRating]

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
            
            guard let data = data else {
                print("No data received from the server.")
                return
            }

            do {
                let response = try JSONDecoder().decode(ToggleDrinkResponse.self, from: data)
                DispatchQueue.main.async {
                    print("update the drinks")
                    if self.triedDrinks.contains(objectID) {
                        self.triedDrinks.remove(objectID)
                        self.triedDrinksRatings.removeValue(forKey: objectID)
                    } else {
                        self.triedDrinks.insert(objectID)
                        self.triedDrinksRatings[objectID] = tempRating
                    }

                    // Update the drink in drinksList with the new averageRating
                    if let index = self.drinks.firstIndex(where: { $0.objectID == objectID }) {
                        self.drinks[index].averageRating = response.averageRating
                    }

                }
            } catch {
                print("Failed to decode response:", error)
            }
        }

        task.resume()
    }

    func fetchTriedDrinks() {
        guard let userId = getUserId() else {
            print("User ID not found")
            return
        }

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
                // Decode the response as a dictionary containing an array of TriedDrink objects
                let response = try JSONDecoder().decode([String: [TriedDrink]].self, from: data)
                
                if let responseDrinks = response["triedDrinks"] {
                    DispatchQueue.main.async {
                        // Extract only the names and update the set
                        self.triedDrinks = Set(responseDrinks.map { $0.objectId })
                        self.triedDrinksRatings = Dictionary(uniqueKeysWithValues: responseDrinks.map { ($0.objectId, $0.rating) })
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
                    self.errorMessage = "Failed to fetch drinks: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received from the server."
                }
                return
            }

            do {
                // Print raw JSON response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🚀 API Response:\n\(jsonString)")
                }

                // Decode as a general JSON object first
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    var decodedDrinks: [Drink] = []

                    for (index, drinkJSON) in jsonArray.enumerated() {
                        do {
                            let drinkData = try JSONSerialization.data(withJSONObject: drinkJSON, options: [])
                            let decodedDrink = try JSONDecoder().decode(Drink.self, from: drinkData)
                            decodedDrinks.append(decodedDrink)
                        } catch {
                            print("❌ Failed to decode drink at index \(index): \(drinkJSON)")
                            print("🔴 Decoding error: \(error)\n")
                        }
                    }

                    // If some drinks were decoded successfully, update the state
                    DispatchQueue.main.async {
                        self.drinks = decodedDrinks
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to parse API response: \(error.localizedDescription)"
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
    @State private var isFavorited: Bool = false

    var body: some View {
        ZStack {
            Color.gray.opacity(0.7)
                .edgesIgnoringSafeArea(.all)

            ScrollView { // Make the entire popup scrollable
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Add a hero category icon
                        Image(systemName: getCategoryIcon(for: drink.category.first ?? "default"))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)

                        Text(drink.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Divider()

                        Text("Description:")
                            .font(.headline)
                        Text(drink.description)
                            .font(.body)

                        Text("Calories: \(drink.calories)")
                            .font(.subheadline)
                        Text("Average Rating: \(drink.averageRating)")
                            .font(.subheadline)

                        Text("Ingredients:")
                            .font(.headline)
                        ForEach(drink.ingredients, id: \.self) { ingredient in
                            Text("- \(ingredient)")
                                .font(.body)
                        }

                            Spacer()

                        Button(action: {
                            dismiss() // Close the popup
                        }) {
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

                    Button(action: {
                        toggleFavorite()
                    }) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(isFavorited ? .red : .gray)
                            .padding(8)
                            .background(Color(UIColor.systemBackground).opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding([.top, .leading], 24)
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            fetchFavoriteStatus()
        }
    }

    func fetchFavoriteStatus() {
        guard let userId = getUserId() else {
            print("User ID not found")
            return
        }
        
        guard let url = URL(string: "http://localhost:3000/api/drinks/favoriteDrinks/\(userId)") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching favorite drinks: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received from server.")
                return
            }
            
            do {
                let favoriteDrinks = try JSONDecoder().decode([Drink].self, from: data)
                DispatchQueue.main.async {
                    // Check if the current drink's drinkID is in the fetched favorites
                    self.isFavorited = favoriteDrinks.contains(where: { $0.drinkID == drink.drinkID })
                }
            } catch {
                print("Error decoding favorite drinks: \(error.localizedDescription)")
            }
        }.resume()
    }

        
    func toggleFavorite() {
        guard let userId = getUserId() else {
            print("User ID not found")
            return
        }
        
        guard let url = URL(string: "http://localhost:3000/api/drinks/toggleFavoriteDrink") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build the JSON body with the userId and the current drink's drinkID
        let body: [String: Any] = ["userId": userId, "drinkId": drink.drinkID]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error toggling favorite: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response toggling favorite: \(response ?? "No response" as Any)")
                return
            }
            
            DispatchQueue.main.async {
                self.isFavorited.toggle()
                NotificationCenter.default.post(name: Notification.Name("FavoriteDrinksUpdated"), object: nil)
            }
        }.resume()
    }

    func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: "userId")
    }

    // Get an appropriate SF Symbol for the drink's category
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
