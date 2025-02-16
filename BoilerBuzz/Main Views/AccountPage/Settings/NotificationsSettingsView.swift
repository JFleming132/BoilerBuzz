//
//  NotificationsSettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//


import SwiftUI

struct NotificationsSettingsView: View {
    var body: some View {
        Text("This should be the Notifications page of the Settings menu.")
            .navigationTitle("Notifications Settings")
    }
}

struct NotificationsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationsSettingsView()
        }
    }
}
