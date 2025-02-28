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
    
    init() {
            GMSServices.provideAPIKey(APIKeys.googleMapsAPIKey)
            GMSPlacesClient.provideAPIKey(APIKeys.googleMapsAPIKey)


            // Check for the UITestSkipLogin launch argument.
        if CommandLine.arguments.contains("-UITestSkipLogin") {
            // Set test defaults so that the app bypasses the login screen.
            UserDefaults.standard.set("67bfc14a59159fbf803fc3bf", forKey: "userId")
            UserDefaults.standard.set(false, forKey: "isAdmin")
            // Update our state to indicate the user is logged in.
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
    }
}
