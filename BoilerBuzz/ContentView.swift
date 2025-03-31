import SwiftUI

enum Tab: Hashable {
    case map, calendar, home, drinks, account
}

struct ContentView: View {
    @State private var selectedTab: Tab
    @State private var accountToView: String?

    // Initialize with an initial tab and an optional accountToView parameter.
    init(initialTab: Tab = .home, accountToView: String? = nil) {
        self.accountToView = accountToView
        self._selectedTab = State(initialValue: initialTab)
        UITabBar.appearance().backgroundColor = UIColor(primaryColor)
        UITabBar.appearance().unselectedItemTintColor = UIColor(secondaryColor)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(Tab.map)
            
            CalendarView()
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


