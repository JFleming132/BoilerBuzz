//
//  SignUpView.swift
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/10/25.
//
import SwiftUI

struct SignUpView: View {
    @State private var newUsername = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var isSignupSuccess = false

    var body: some View {
        VStack {
            Text("Sign Up")
                .font(.largeTitle)
                .padding()

            TextField("Username", text: $newUsername)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)

            SecureField("Password", text: $newPassword)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                if !newUsername.isEmpty && newPassword == confirmPassword {
                    // Make a sign-up request to the backend
                    signupRequest(username: newUsername, password: newPassword)
                } else {
                    showError = true
                }
            }) {
                Text("Create Account")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            if showError {
                Text("Passwords do not match or fields are empty.")
                    .foregroundColor(.red)
            }

            if isSignupSuccess {
                Text("Sign-up successful!")
                    .foregroundColor(.green)
            }
        }
        .padding()
    }

    // Function to handle sign-up request
    func signupRequest(username: String, password: String) {
        guard let url = URL(string: "http://localhost:3000/api/auth/signup") else { return }
        
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during request: \(error)")
                return
            }
            guard let data = data else { return }
            
            do {
                let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
                print("Response: \(responseJSON)")
                DispatchQueue.main.async {
                    isSignupSuccess = true  // Update the success message
                }
            } catch {
                print("Error parsing response: \(error)")
            }
        }
        
        task.resume()
    }
}
