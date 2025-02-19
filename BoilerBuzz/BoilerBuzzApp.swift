//
//  BoilerBuzzApp.swift
//  BoilerBuzz
//
//  Created by user269394 on 2/5/25.
//

import SwiftUI
let primaryColor = Color.black
let secondaryColor = Color.gray
let tertiaryColor = Color.yellow
let bgColor = Color.black.opacity(0.7)
@main
struct BoilerBuzzApp: App {
    @State var isLoggedIn: Bool = false
    
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
