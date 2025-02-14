//
//  AccountSettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//

import SwiftUI

struct AccountSettingsView: View {
    var body: some View {
        Text("This should be the Account page of the Settings menu.")
            .navigationTitle("Account Settings")
    }
}

struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountSettingsView()
        }
    }
}
