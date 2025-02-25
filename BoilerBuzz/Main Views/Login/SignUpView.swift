//
//  SignUpView.swift
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 2/10/25.
//
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
    @State private var showOnboarding = false
    @State private var currentStepView: AnyView = AnyView(EmptyView())
    
    var body: some View {
            ZStack {
                VStack {
                    Text("Sign Up")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Rectangle()
                        .fill(tertiaryColor)
                        .frame(width: 150, height: 4)
                        .padding(.horizontal)
                        .cornerRadius(2)
                    
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
                            .background(primaryColor)
                            .foregroundColor(tertiaryColor)
                            .cornerRadius(10)
                    }
                    .background(.black)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(tertiaryColor, lineWidth: 2)
                    )
                    .padding()
                    
                    NavigationLink(destination: VerificationView()) {
                        Text("Click here to verify your account")
                            .foregroundColor(.blue)
                    }
                    
                    if showError {
                        Text("\(errorMessage ?? "Unknown error")")
                            .foregroundColor(.red)
                    }
                    
                    if isSignupSuccess {
                        Text("Signup successful! Check your email for a verification code.")
                            .foregroundColor(.green)
                            .fullScreenCover(isPresented: $showOnboarding) {
                                    OnboardingView(currentStepView: $currentStepView)
                                }
                    }
                }
                .padding()
            }
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
                                        showOnboarding = true
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

struct OnboardingView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentStepView: AnyView
    @State private var step = 0
    
    var body: some View {
        ZStack {
            currentStepView
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    Text(getTitle())
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(step == 0 ? Color.yellow.opacity(0.8) : Color.clear) // Yellow background for first step
                    
                    Text(getDescription())
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(step == 6 ? "Finish" : "Next") {
                        advanceStep()
                    }
                    .padding()
                    .background(primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10)
            }
        }
        .onAppear {
            updateStepView()
        }
    }
    
    func getTitle() -> String {
        switch step {
        case 0: return "Welcome to Boiler Buzz! Your go-to app for discovering Purdue’s nightlife."
        case 1: return "Map Feature - Never wait in long lines again!"
        case 2: return "Calendar Feature - Stay updated on the latest events!"
        case 3: return "Home (Posts) - Engage with your Purdue community!"
        case 4: return "Account Settings - Personalize your experience!"
        case 5: return "Drinks Feature - Find, rate, and discover new drinks!"
        case 6: return "Spending Tracker - Keep an eye on your budget!"
        default: return ""
        }
    }
    
    func getDescription() -> String {
        switch step {
        case 0: return "Boiler Buzz helps Purdue students connect over events, drinks, and social hangouts. Let's get started!"
        case 1: return "View bar wait times, find events, and explore West Lafayette nightlife in real-time."
        case 2: return "Never miss out! Our event calendar keeps track of bar promotions and social gatherings."
        case 3: return "Check out posts from other students, RSVP to events, and share your own experiences."
        case 4: return "Customize your profile, update preferences, and track your social activity."
        case 5: return "Browse drink menus, rate your favorite drinks, and shake your phone for a random drink suggestion!"
        case 6: return "Track your spending on drinks, set budgets, and see how much you've spent over time!"
        default: return ""
        }
    }
    
    func advanceStep() {
        if step < 6 {
            step += 1
            updateStepView()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func updateStepView() {
        switch step {
        case 1: currentStepView = AnyView(MapView())
        case 2: currentStepView = AnyView(CalendarView())
        case 3: currentStepView = AnyView(HomeView())
        case 4: currentStepView = AnyView(AccountView())
        case 5: currentStepView = AnyView(DrinksDetailView())
        case 6: currentStepView = AnyView(SpendingView())
        default: currentStepView = AnyView(EmptyView())
        }
    }
}

