import SwiftUI
import GoogleMaps
import GooglePlaces
let primaryColor = Color.black
let secondaryColor = Color.gray
let tertiaryColor = Color.yellow
let bgColor = Color.black.opacity(0.7)
@main
struct BoilerBuzzApp: App {
    @State var isLoggedIn: Bool = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var initialTab: Tab = .home
    @State private var deepLinkUserId: String? = nil
    @State private var deepLinkEventId: String? = nil
    
    init() {
        GMSServices.provideAPIKey(APIKeys.googleMapsAPIKey)
        GMSPlacesClient.provideAPIKey(APIKeys.googleMapsAPIKey)

        if CommandLine.arguments.contains("-UITestSkipLogin") {
            UserDefaults.standard.set("67bfc14a59159fbf803fc3bf", forKey: "userId")
            UserDefaults.standard.set(false, forKey: "isAdmin")
            self._isLoggedIn = State(initialValue: true)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    if let userId = deepLinkUserId {
                        ContentView(initialTab: .account, accountToView: userId, eventToView: nil)
                            .onAppear {
                                DispatchQueue.main.async {
                                    deepLinkUserId = nil
                                }
                            }
                    }
                    else if let eventId = deepLinkEventId {
                        ContentView(initialTab: .home, accountToView: nil, eventToView: eventId)
                            /*.onAppear {
                                DispatchQueue.main.async {
                                    deepLinkEventId = nil
                                }
                            }*/
                    }
                    else {
                        ContentView(initialTab: .home, accountToView: nil, eventToView: nil)
                    }
                } else {
                    LoginView(isLoggedIn: $isLoggedIn)
                }
            }
            .onOpenURL { url in
                print("Received deep link: \(url)")
                isLoggedIn = false
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let host = components.host,
                   let queryItems = components.queryItems {
                    
                    if host.lowercased() == "account",
                       let idItem = queryItems.first(where: { $0.name.lowercased() == "id" }),
                       let userId = idItem.value {
                        deepLinkUserId = userId
                        initialTab = .account
                        print("Deep link userId: \(userId)")
                    } else if host.lowercased() == "event",
                              let idItem = queryItems.first(where: { $0.name.lowercased() == "id" }),
                              let eventId = idItem.value {
                        deepLinkEventId = eventId
                        initialTab = .home
                        print("Deep link eventId: \(eventId)")
                    }
                }
            }
        }
        .onChange(of: isDarkMode) { oldValue, newValue in
            setColorScheme(newValue)
        }
    }
    
    private func setColorScheme(_ isDark: Bool) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }
}
