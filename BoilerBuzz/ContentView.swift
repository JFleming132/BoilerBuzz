//
//  ContentView.swift
//  BoilerBuzz
//
//  Created by user269394 on 2/5/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Map", systemImage: "map") {
                MapView()
            }
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
    }
}

#Preview {
    ContentView()
}
