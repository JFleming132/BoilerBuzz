//
//  SignUpView.swift
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/10/25.
//
import SwiftUI

struct SignUpView: View {
    @State private var newEmail = ""
    @State private var newUsername = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage: String? = "Error during sign up"
    @State private var isSignupSuccess = false

    var body: some View {
        VStack {
            Text("Sign Up")
                .font(.largeTitle)
                .padding()
            
            TextField("Email", text: $newEmail)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)

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
                if !newEmail.isEmpty && !newUsername.isEmpty && newPassword == confirmPassword {
                    // Make a sign-up request to the backend
                    signupRequest(email: newEmail, username: newUsername, password: newPassword)
                } else {
                    if newUsername.isEmpty {
                        errorMessage = "Username is required."
                    }
                    else {
                        errorMessage = "Passwords do not match."
                    }
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
                Text("\(errorMessage ?? "Unknown error")")
                    .foregroundColor(.red)
            }

            if isSignupSuccess {
                Text("Signup successful! Check your email for a verification code.")
                    .foregroundColor(.green)
            }
        }
        .padding()
    }

    // Function to handle sign-up request
    func signupRequest(email: String, username: String, password: String) {
        guard let url = URL(string: "http://localhost:3000/api/auth/signup") else { return }

        let body: [String: Any] = [
            "email": email,
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

            // Check the response status code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 201 {
                    // Successful response, check the message
                    do {
                        let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
                        if let jsonResponse = responseJSON as? [String: Any], let message = jsonResponse["message"] as? String {
                            if message == "User registered successfully!" {
                                print("Signup successful: \(message)")
                                DispatchQueue.main.async {
                                    isSignupSuccess = true // Update success flag
                                }
                            }
                        }
                    } catch {
                        print("Error parsing response: \(error)")
                    }
                } else {
                    // Failed response, handle error message
                    do {
                        let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
                        if let jsonResponse = responseJSON as? [String: Any], let message = jsonResponse["message"] as? String {
                            print("Signup failed: \(message)")
                            DispatchQueue.main.async {
                                errorMessage = message
                                showError = true
                            }
                        }
                    } catch {
                        print("Error parsing failed response: \(error)")
                    }
                }
            }
        }

        task.resume()
    }
}
