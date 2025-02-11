//
//  BoilerBuzzApp.swift
//  BoilerBuzz
//
//  Created by user269394 on 2/5/25.
//

import SwiftUI

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
