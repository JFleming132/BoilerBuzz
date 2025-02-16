//
//  SocialPreferencesSettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//


import SwiftUI

struct SocialPreferencesSettingsView: View {
    var body: some View {
        Text("This should be the Social & Preferences page of the Settings menu.")
            .navigationTitle("Social & Preferences")
    }
}

struct SocialPreferencesSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SocialPreferencesSettingsView()
        }
    }
}
