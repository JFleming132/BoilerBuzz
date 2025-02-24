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
