//
//  BoilerBuzzApp.swift
//  BoilerBuzz
//
//  Created by user269394 on 2/5/25.
//

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
        GMSServices.provideAPIKey("AIzaSyD9fysUB7FOQTQILo0TEdTOo59cL-4weVM")
        GMSPlacesClient.provideAPIKey("AIzaSyD9fysUB7FOQTQILo0TEdTOo59cL-4weVM")
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
