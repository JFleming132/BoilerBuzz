//
//  DrinksDetailViewTests.swift
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/27/25.
//

import Testing
@testable import BoilerBuzz

struct DrinksDetailViewTests {

    @Test func testDrinkFiltering() async throws {
        var view = DrinksDetailView()

        let testDrinks = [
            Drink(objectID: "1", drinkID: 101, name: "Mojito", description: "Minty and refreshing", ingredients: ["Rum", "Mint", "Sugar", "Lime", "Soda"], averageRating: 4, barServed: "Tiki Bar", category: ["Cocktail"], calories: 150),
            Drink(objectID: "2", drinkID: 102, name: "IPA Beer", description: "Hoppy and bitter", ingredients: ["Hops", "Barley"], averageRating: 5, barServed: "BrewPub", category: ["Beer"], calories: 200),
            Drink(objectID: "3", drinkID: 103, name: "Whiskey Sour", description: "Citrusy whiskey delight", ingredients: ["Whiskey", "Lemon", "Sugar"], averageRating: 3, barServed: "Speakeasy", category: ["Whiskey-Based"], calories: 180)
        ]

        view.setDrinksForTesting(testDrinks)

        // Test filtering by category
        view.setCategoryForTesting("Cocktail")
        #expect(view.filteredDrinks.count == 1)
        #expect(view.filteredDrinks.first?.name == "Mojito")

        // Test filtering by calories
        view.setMinCaloriesForTesting(160)
        #expect(view.filteredDrinks.count == 1)
        #expect(view.filteredDrinks.first?.name == "Whiskey Sour")

        view.setMaxCaloriesForTesting(180)
        #expect(view.filteredDrinks.count == 1)
    }

    @Test func testSorting() async throws {
        var view = DrinksDetailView()

        let testDrinks = [
            Drink(objectID: "1", drinkID: 101, name: "Mojito", description: "Minty and refreshing", ingredients: ["Rum", "Mint", "Sugar", "Lime", "Soda"], averageRating: 4, barServed: "Tiki Bar", category: ["Cocktail"], calories: 150),
            Drink(objectID: "2", drinkID: 102, name: "IPA Beer", description: "Hoppy and bitter", ingredients: ["Hops", "Barley"], averageRating: 5, barServed: "BrewPub", category: ["Beer"], calories: 200),
            Drink(objectID: "3", drinkID: 103, name: "Whiskey Sour", description: "Citrusy whiskey delight", ingredients: ["Whiskey", "Lemon", "Sugar"], averageRating: 3, barServed: "Speakeasy", category: ["Whiskey-Based"], calories: 180)
        ]

        view.setDrinksForTesting(testDrinks)

        // Test sorting A to Z
        view.setSortOptionForTesting("A to Z")
        #expect(view.sortedDrinks.first?.name == "IPA Beer")

        // Test sorting Z to A
        view.setSortOptionForTesting("Z to A")
        #expect(view.sortedDrinks.first?.name == "Whiskey Sour")

        // Test sorting by rating (Lowest first)
        view.setSortOptionForTesting("Lowest Average Rating First")
        #expect(view.sortedDrinks.first?.name == "Whiskey Sour")

        // Test sorting by rating (Highest first)
        view.setSortOptionForTesting("Highest Average Rating First")
        #expect(view.sortedDrinks.first?.name == "IPA Beer")
    }

    @Test func testRatingUpdates() async throws {
        var view = DrinksDetailView()

        let testDrinks = [
            Drink(objectID: "1", drinkID: 101, name: "Mojito", description: "Minty and refreshing", ingredients: ["Rum", "Mint", "Sugar", "Lime", "Soda"], averageRating: 4, barServed: "Tiki Bar", category: ["Cocktail"], calories: 150),
            Drink(objectID: "2", drinkID: 102, name: "IPA Beer", description: "Hoppy and bitter", ingredients: ["Hops", "Barley"], averageRating: 5, barServed: "BrewPub", category: ["Beer"], calories: 200)
        ]

        view.setDrinksForTesting(testDrinks)

        // Simulate rating a drink
        view.triedDrinks.insert("1")
        view.triedDrinksRatings["1"] = 5

        #expect(view.triedDrinks.contains("1"))
        #expect(view.triedDrinksRatings["1"] == 5)
    }
}
