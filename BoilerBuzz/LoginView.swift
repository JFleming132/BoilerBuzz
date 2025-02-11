//
//  LoginView.swift
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/10/25.
//

import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var showFailedLogin = false
    @Binding var isLoggedIn: Bool

    var body: some View {
        VStack {
            Text("BoilerBuzz Login")
                .font(.largeTitle)
                .padding()

            TextField("Username", text: $username)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onTapGesture {
                    showFailedLogin = false
                }

            SecureField("Password", text: $password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onTapGesture {
                    showFailedLogin = false
                }

            Button(action: {
                // (replace with real authentication logic)
                if username == "User" && password == "Password" {
                    isLoggedIn = true
                }
                else {
                    showFailedLogin = true
                }
            }) {
                Text("Login")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            if !isLoggedIn && showFailedLogin {
                Text("Incorrect username or password.")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

