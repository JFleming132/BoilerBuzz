//
//  AccountSettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//

import SwiftUI

struct AccountSettingsView: View {
    @State var username: String
    @State var bio: String
    @State var userId: String

    var body: some View {
        Text("Test Username \(username)!")
        Text("Test Bio \(bio)")
        Text("This should be the Account page of the Settings menu.")
            .navigationTitle("Account Settings")
    }
}

struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountSettingsView(username: "Patrick", bio: "I am a student at Purdue University.", userId: "12345")
        }
    }
}
