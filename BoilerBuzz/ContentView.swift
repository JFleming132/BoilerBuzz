//
//  ContentView.swift
//  BoilerBuzz
//
//  Created by user269394 on 2/5/25.
//

import SwiftUI

struct ContentView: View {
    init() {
        UITabBar.appearance().backgroundColor = UIColor(primaryColor)
        UITabBar.appearance().unselectedItemTintColor = UIColor(secondaryColor)

    }
    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()
            VStack {
                TabView {
                    Tab("Map", systemImage: "map") {
                        MapView()}
                    Tab("Calendar", systemImage: "calendar") {
                        CalendarView()
                    }
                    Tab("Home", systemImage: "house") {
                        HomeView()
                    }
                    Tab("Drinks", systemImage: "wineglass") {
                        DrinksView()
                    }
                    Tab("Account", systemImage: "person") {
                        AccountView();
                    }
                }
                .accentColor(tertiaryColor)
            }
            
        }
    }
}

#Preview {
    ContentView()
}
