import SwiftUI

enum Tab: Hashable {
    case map, calendar, home, drinks, account, game
}

let backendURL = "http://localhost:3000/"

struct ContentView: View {
    @State private var selectedTab: Tab
    @State private var accountToView: String?
    @State private var eventToView: String?

    // Initialize with an initial tab and an optional accountToView parameter.
    init(initialTab: Tab = .home, accountToView: String? = nil, eventToView: String? = nil) {
        self._selectedTab = State(initialValue: initialTab)
        self._accountToView = State(initialValue: accountToView)
        self._eventToView = State(initialValue: eventToView)
        
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = .black
        appearance.shadowColor = .clear
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(secondaryColor)
    }

    
    var body: some View {
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
            
            HomeView(eventToView: eventToView)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(Tab.home)
                .onAppear {
                    if eventToView != nil {
                        DispatchQueue.main.async {
                            eventToView = nil
                        }
                    }
                }
            
            DrinksView()
                .tabItem {
                    Label("Drinks", systemImage: "wineglass")
                }
                .tag(Tab.drinks)
            GamesView()
                .tabItem {
                    Label("Games", systemImage: "gamecontroller")
                }

            
            // Pass the accountToView to AccountView. If accountToView is nil,
            // AccountView will fetch your own profile as before.
            AccountView(deeplinkUserId: accountToView)
                .tabItem {
                    Label("Account", systemImage: "person")
                }
                .tag(Tab.account)
                .onAppear {
                    // Once the Account tab appears, clear the deep link value.
                    if accountToView != nil {
                        DispatchQueue.main.async {
                            accountToView = nil
                        }
                    }
                }
        }
        .accentColor(tertiaryColor)
    }
}
