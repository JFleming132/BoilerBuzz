//
//  ContentView.swift
//  BoilerBuzz
//
//  Created by user269394 on 2/5/25.
//

import SwiftUI

enum Tab: Hashable {
    case map, calendar, home, drinks, account
}

struct ContentView: View {
    @State private var selectedTab: Tab = .account  // Set Account as the initial tab

    init() {
        UITabBar.appearance().backgroundColor = UIColor(primaryColor)
        UITabBar.appearance().unselectedItemTintColor = UIColor(secondaryColor)
    }
    
    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()
            TabView(selection: $selectedTab) {
                MapView()
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                    .tag(Tab.map)
                
                CalendarViewPage()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(Tab.calendar)
                
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(Tab.home)
                
                DrinksView()
                    .tabItem {
                        Label("Drinks", systemImage: "wineglass")
                    }
                    .tag(Tab.drinks)
                
                AccountView()
                    .tabItem {
                        Label("Account", systemImage: "person")
                    }
                    .tag(Tab.account)
            }
            .accentColor(tertiaryColor)
        }
    }
}

#Preview {
    ContentView()
}
