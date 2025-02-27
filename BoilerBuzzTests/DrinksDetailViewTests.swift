//
//  DrinksDetailViewTests.swift
//  BoilerBuzzTests
//
//  Created by Matt Zlatniski on 2/27/25.
//

import XCTest
@testable import BoilerBuzz


final class DrinksDetailViewTests: XCTestCase {
    
    func testDrinkFiltering() throws {
        let testDrinks = [
            Drink(objectID: "1", drinkID: 101, name: "Mojito",
                  description: "Minty and refreshing",
                  ingredients: ["Rum", "Mint", "Sugar", "Lime", "Soda"],
                  averageRating: 4, barServed: "Tiki Bar",
                  category: ["Cocktail", "Rum-Based"],
                  calories: 150),
            
            Drink(objectID: "2", drinkID: 102, name: "IPA Beer",
                  description: "Hoppy and bitter",
                  ingredients: ["Hops", "Barley"],
                  averageRating: 5, barServed: "BrewPub",
                  category: ["Beer", "Stout"],
                  calories: 200),
            
            // Whiskey Sour doesn't contain "Cocktail" in its categories.
            Drink(objectID: "3", drinkID: 103, name: "Whiskey Sour",
                  description: "Citrusy whiskey delight",
                  ingredients: ["Whiskey", "Lemon", "Sugar"],
                  averageRating: 3, barServed: "Speakeasy",
                  category: ["Cocktail", "Whiskey-Based"],
                  calories: 180)
        ]
        
        // Test 1: Filter by category "Cocktail" (should return only Mojito).
        let filteredByCategory = filterDrinks(
            from: testDrinks,
            selectedCategory: "Cocktail",
            selectedBase: nil,
            minCalories: nil,
            maxCalories: nil,
            minRating: nil
        )
        XCTAssertEqual(filteredByCategory.count, 2)
        XCTAssertTrue(filteredByCategory.contains { $0.name == "Mojito" })
        XCTAssertTrue(filteredByCategory.contains { $0.name == "Whiskey Sour" })
        
        // Test 2: Filter by minimum rating of 4 (should return Mojito and IPA Beer).
        let filteredByRating = filterDrinks(
            from: testDrinks,
            selectedCategory: nil,
            selectedBase: nil,
            minCalories: nil,
            maxCalories: nil,
            minRating: 4
        )
        XCTAssertEqual(filteredByRating.count, 2)
        XCTAssertTrue(filteredByRating.contains { $0.name == "Mojito" })
        XCTAssertTrue(filteredByRating.contains { $0.name == "IPA Beer" })
        
        // Test 3: Filter by calorie range (160 to 220).
        // This should return IPA Beer (200 calories) and Whiskey Sour (180 calories).
        let filteredByCalories = filterDrinks(
            from: testDrinks,
            selectedCategory: nil,
            selectedBase: nil,
            minCalories: 160,
            maxCalories: 220,
            minRating: nil
        )
        XCTAssertEqual(filteredByCalories.count, 2)
        XCTAssertTrue(filteredByCalories.contains { $0.name == "IPA Beer" })
        XCTAssertTrue(filteredByCalories.contains { $0.name == "Whiskey Sour" })
        
        // Test 4: Combine filters—only beers with a minimum rating of 5.
        let filteredCombined = filterDrinks(
            from: testDrinks,
            selectedCategory: "Beer",
            selectedBase: nil,
            minCalories: nil,
            maxCalories: nil,
            minRating: 5
        )
        XCTAssertEqual(filteredCombined.count, 1)
        XCTAssertEqual(filteredCombined.first?.name, "IPA Beer")
        
        // Test 5: Filter by Base
        let filteredBase = filterDrinks(
            from: testDrinks,
            selectedCategory: "Cocktail",
            selectedBase: "Rum-Based",
            minCalories: nil,
            maxCalories: nil,
            minRating: 0
        )
        XCTAssertEqual(filteredBase.count, 1)
        XCTAssertEqual(filteredBase.first?.name, "Mojito")
    }
    
    func testDrinkSorting() throws {
        // Create some test drinks.
        let testDrinks = [
            Drink(objectID: "1", drinkID: 101, name: "Mojito",
                  description: "Minty and refreshing",
                  ingredients: ["Rum", "Mint", "Sugar", "Lime", "Soda"],
                  averageRating: 4, barServed: "Tiki Bar",
                  category: ["Cocktail", "Rum-Based"],
                  calories: 150),
            
            Drink(objectID: "2", drinkID: 102, name: "IPA Beer",
                  description: "Hoppy and bitter",
                  ingredients: ["Hops", "Barley"],
                  averageRating: 5, barServed: "BrewPub",
                  category: ["Beer", "Stout"],
                  calories: 200),
            
            Drink(objectID: "3", drinkID: 103, name: "Whiskey Sour",
                  description: "Citrusy whiskey delight",
                  ingredients: ["Whiskey", "Lemon", "Sugar"],
                  averageRating: 3, barServed: "Speakeasy",
                  category: ["Cocktail", "Whiskey-Based"],
                  calories: 180)
        ]
        
        // Assume that the tried drinks set contains the objectID "1" (Mojito is tried).
        let triedDrinks: Set<String> = ["1"]
        
        // Test sorting A to Z (alphabetical order).
        var sorted = sortDrinks(from: testDrinks, withSortOption: "A to Z", triedDrinks: triedDrinks)
        XCTAssertEqual(sorted[0].name, "IPA Beer")
        XCTAssertEqual(sorted[1].name, "Mojito")
        XCTAssertEqual(sorted[2].name, "Whiskey Sour")
        
        // Test sorting Z to A.
        sorted = sortDrinks(from: testDrinks, withSortOption: "Z to A", triedDrinks: triedDrinks)
        XCTAssertEqual(sorted[0].name, "Whiskey Sour")
        XCTAssertEqual(sorted[1].name, "Mojito")
        XCTAssertEqual(sorted[2].name, "IPA Beer")
        
        // Test sorting by Lowest Calorie First.
        sorted = sortDrinks(from: testDrinks, withSortOption: "Lowest Calorie First", triedDrinks: triedDrinks)
        XCTAssertEqual(sorted[0].name, "Mojito")          // 150 calories
        XCTAssertEqual(sorted[1].name, "Whiskey Sour")     // 180 calories
        XCTAssertEqual(sorted[2].name, "IPA Beer")           // 200 calories
        
        // Test sorting by Highest Calorie First.
        sorted = sortDrinks(from: testDrinks, withSortOption: "Highest Calorie First", triedDrinks: triedDrinks)
        XCTAssertEqual(sorted[0].name, "IPA Beer")
        XCTAssertEqual(sorted[1].name, "Whiskey Sour")
        XCTAssertEqual(sorted[2].name, "Mojito")
        
        // Test sorting by Lowest Average Rating First.
        sorted = sortDrinks(from: testDrinks, withSortOption: "Lowest Average Rating First", triedDrinks: triedDrinks)
        XCTAssertEqual(sorted[0].name, "Whiskey Sour")  // rating 3
        XCTAssertEqual(sorted[1].name, "Mojito")          // rating 4
        XCTAssertEqual(sorted[2].name, "IPA Beer")          // rating 5
        
        // Test sorting by Highest Average Rating First.
        sorted = sortDrinks(from: testDrinks, withSortOption: "Highest Average Rating First", triedDrinks: triedDrinks)
        XCTAssertEqual(sorted[0].name, "IPA Beer")
        XCTAssertEqual(sorted[1].name, "Mojito")
        XCTAssertEqual(sorted[2].name, "Whiskey Sour")
        
        // Test sorting with "Tried Drinks First".
        // Mojito (objectID "1") should come first, then the rest in alphabetical order.
        sorted = sortDrinks(from: testDrinks, withSortOption: "Tried Drinks First", triedDrinks: triedDrinks)
        XCTAssertEqual(sorted[0].name, "Mojito")
        XCTAssertEqual(sorted[1].name, "IPA Beer")
        XCTAssertEqual(sorted[2].name, "Whiskey Sour")
        
        // Test sorting with "Tried Drinks Last".
        // Non-tried drinks come first in alphabetical order, then Mojito last.
        sorted = sortDrinks(from: testDrinks, withSortOption: "Tried Drinks Last", triedDrinks: triedDrinks)
        XCTAssertEqual(sorted[0].name, "IPA Beer")
        XCTAssertEqual(sorted[1].name, "Whiskey Sour")
        XCTAssertEqual(sorted[2].name, "Mojito")
    }

}

