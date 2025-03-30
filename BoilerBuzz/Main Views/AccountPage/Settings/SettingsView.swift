//
//  SettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//

import SwiftUI

struct SettingsView: View {

    @ObservedObject var profileData: ProfileViewModel
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: AccountSettingsView(profileData: profileData)) {
                    SettingsRow(icon: "person.fill", title: "Account")
                }
                .accessibilityIdentifier("accountSettingsRow")
                NavigationLink(destination: NotificationsSettingsView()) {
                    SettingsRow(icon: "bell.fill", title: "Notifications")
                }
                NavigationLink(destination: SocialPreferencesSettingsView()) {
                    SettingsRow(icon: "person.2.fill", title: "Social & Preferences")
                }
                NavigationLink(destination: AppearanceSettingsView()) {
                    SettingsRow(icon: "eye.fill", title: "Appearance")
                }
                NavigationLink(destination: PrivacySecuritySettingsView()) {
                    SettingsRow(icon: "lock.fill", title: "Privacy & Security")
                }
                NavigationLink(destination: HelpSupportSettingsView()) {
                    SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support")
                }
                NavigationLink(destination: IdentificationView()) {
                    SettingsRow(icon: "checkmark.seal.fill", title: "Identification")
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// Reusable row for settings options
struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            Text(title)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(profileData: ProfileViewModel())
    }
}
