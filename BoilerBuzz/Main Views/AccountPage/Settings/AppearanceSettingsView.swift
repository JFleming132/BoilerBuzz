//
//  AppearanceSettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//


import SwiftUI

struct AppearanceSettingsView: View {
    var body: some View {
        Text("This should be the Appearance page of the Settings menu.")
            .navigationTitle("Appearance Settings")
    }
}

struct AppearanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppearanceSettingsView()
        }
    }
}
