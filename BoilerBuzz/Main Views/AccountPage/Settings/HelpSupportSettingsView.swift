//
//  HelpSupportSettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//


import SwiftUI

struct HelpSupportSettingsView: View {
    var body: some View {
        Text("This should be the Help & Support page of the Settings menu.")
            .navigationTitle("Help & Support")
    }
}

struct HelpSupportSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HelpSupportSettingsView()
        }
    }
}
