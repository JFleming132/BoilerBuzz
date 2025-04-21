//
//  SettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//

import SwiftUI

struct SettingsView: View {

    @ObservedObject var profileData: ProfileViewModel
    
    @AppStorage("eventRadius") private var radiusMiles: Double = 10.0

    
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
            
            // ───── Default Radius Slider ─────
                       Section(header: Text("Default Search Radius")) {
                           VStack(alignment: .leading) {
                               // show the live value
                               Text("Radius: \(Int(radiusMiles)) miles")
                                   .font(.subheadline)
                                   .foregroundColor(.secondary)

                               Slider(
                                   value: $radiusMiles,
                                   in: 1...50,
                                   step: 1
                               )
                               .accessibility(value: Text("\(Int(radiusMiles)) miles"))
                           }
                           .padding(.vertical, 4)
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
