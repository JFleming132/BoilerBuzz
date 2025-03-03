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
            if isLoggedIn {
                ContentView()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
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
