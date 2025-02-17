//
//  PrivacySecuritySettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//


import SwiftUI

struct PrivacySecuritySettingsView: View {
    var body: some View {
        Text("This should be the Privacy & Security page of the Settings menu.")
            .navigationTitle("Privacy & Security")
    }
}

struct PrivacySecuritySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacySecuritySettingsView()
        }
    }
}
