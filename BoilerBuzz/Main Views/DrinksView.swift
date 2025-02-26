//
//  DrinksView.swift
//  BoilerBuzz
//

import SwiftUI

struct DrinksView: View {
    @State private var selectedTab: String = "Drinks" // Default to Drinks view

    var body: some View {
        VStack(spacing: 0) { // No spacing between elements
            // Tabs at the top, positioned below the clock
            HStack {
                Button(action: {
                    selectedTab = "Drinks"
                }) {
                    Text("Drinks")
                        .font(.headline)
                        .foregroundColor(selectedTab == "Drinks" ? tertiaryColor : secondaryColor)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity) // Make tabs fill space equally
                }
                Button(action: {
                    selectedTab = "Spending"
                }) {
                    Text("Spending")
                        .font(.headline)
                        .foregroundColor(selectedTab == "Spending" ? tertiaryColor : secondaryColor)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity) // Make tabs fill space equally
                }
            }
            .padding(.top, 44) // Add padding to push tabs below the clock
            .background(Color(.systemBackground))
            .shadow(color: secondaryColor.opacity(0.1), radius: 2, x: 0, y: 2) // Subtle shadow for tab separator

            // Dynamic content based on selected tab
            Spacer()
            if selectedTab == "Drinks" {
                DrinksDetailView()
            } else if selectedTab == "Spending" {
                SpendingView()
            }
            Spacer()
        }
        .edgesIgnoringSafeArea(.top) // Extend the view to the very top
        .frame(maxHeight: .infinity, alignment: .top) // Push everything to the top
        .background(Color(.systemBackground))
    }
}
