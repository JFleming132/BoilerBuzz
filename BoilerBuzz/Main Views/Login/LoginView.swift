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
    
    // Function to perform the login request
    func loginRequest() {
        print("trying login request")
        guard let url = URL(string: "http://localhost:3000/api/auth/login") else {
            print("Invalid URL")
            return
        }
        
        let parameters = [
            "username": username,
            "password": password
        ]
        
        // Serialize parameters to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            print("Failed to encode parameters")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Send the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    showFailedLogin = true
                }
                return
            }
            
            // Check if the response contains the expected message
            if let data = data, let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = jsonResponse["message"] as? String, message == "Got user login request!" {
                    print("Login successful: \(message)")
                    DispatchQueue.main.async {
                        isLoggedIn = true
                    }
                } else {
                    DispatchQueue.main.async {
                        showFailedLogin = true
                    }
                }
            }
        }.resume()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("BoilerBuzz Login")
                    .font(.largeTitle)
                    .padding()
                
                TextField("Username", text: $username)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
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
                    if !username.isEmpty && !password.isEmpty {
                        loginRequest()  // Call loginRequest function
                    } else {
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
                
                if showFailedLogin {
                    Text("Login failed. Please check your username and password.")
                        .foregroundColor(.red)
                }
                
                NavigationLink(destination: SignUpView()) {
                    Text("New to BoilerBuzz? Sign Up!")
                        .foregroundColor(.blue)
                        .padding()
                }
                
                NavigationLink(destination: ForgotPasswordView()) {
                    Text("Forgot password?")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
            .padding()
        }
    }
}
