//
//  SettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var username: String = ""
    @State private var bio: String = ""
    
    //Need something to change the profile pic
    // Password fields
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    // A message to show update status
    @State private var updateStatus: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Profile Information")) {
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                TextField("Bio", text: $bio)
            }
            
            Section(header: Text("Change Password")) {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
            }
            
            Button(action: {
                // Call your update function here
                updateProfile()
            }) {
                Text("Save Changes")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            if !updateStatus.isEmpty {
                Text(updateStatus)
                    .foregroundColor(.green)
                    .font(.footnote)
            }
        }
        .navigationTitle("Settings")
    }
    
    func updateProfile() {
        // Need to update profile
        updateStatus = "Profile updated successfully!"
        
        // Should also check to make sure newPassword = confirmPassword
        // newUsername does not equal any other username
        // newPassword != oldPassword
        // Etc
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
