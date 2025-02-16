import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var resetCode: String = ""  // To hold the code entered by the user
    @State private var newPassword: String = ""  // To hold the new password entered by the user
    @State private var isEmailEmpty: Bool = false
    @State private var isRequestInProgress: Bool = false
    @State private var isCodeSent: Bool = false  // Flag to show the reset code input fields
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    var body: some View {
        VStack {
            Text("Forgot Password")
                .font(.largeTitle)
                .padding()

            // Step 1: Email input view
            if !isCodeSent {
                TextField("Enter your email", text: $email)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                if isEmailEmpty {
                    Text("Email is required")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    handleForgotPasswordRequest()
                }) {
                    Text("Send Reset Code")
                        .fontWeight(.bold)
                        .padding()
                        .background(primaryColor)
                        .foregroundColor(tertiaryColor)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(email.isEmpty || isRequestInProgress)

                if isRequestInProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            // Step 2: Reset Code and New Password input
            if isCodeSent {
                TextField("Enter Reset Code", text: $resetCode)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Enter New Password", text: $newPassword)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: {
                    handleResetPassword()
                }) {
                    Text("Reset Password")
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(resetCode.isEmpty || newPassword.isEmpty || isRequestInProgress)

                if isRequestInProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .padding()
    }

    // Function to handle the "Forgot Password" request (Step 1)
    func handleForgotPasswordRequest() {
        guard !email.isEmpty else {
            isEmailEmpty = true
            return
        }
        
        isRequestInProgress = true
        errorMessage = nil
        successMessage = nil

        // API Call to backend for sending reset code
        let url = URL(string: "http://localhost:3000/api/auth/forgotPasswordCode")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["email": email]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isRequestInProgress = false
                if let error = error {
                    self.errorMessage = "Failed to send reset code: \(error.localizedDescription)"
                } else {
                    // If the request was successful, show the code input
                    self.isCodeSent = true
                    self.successMessage = "A reset code has been sent to your email."
                }
            }
        }.resume()
    }

    // Function to handle resetting the password (Step 2)
    func handleResetPassword() {
        guard !resetCode.isEmpty, !newPassword.isEmpty else {
            errorMessage = "Please fill in both fields."
            return
        }

        isRequestInProgress = true
        errorMessage = nil
        successMessage = nil

        // Ensure the email field is non-empty
        guard !email.isEmpty else {
            errorMessage = "Email is required."
            return
        }

        // API Call to backend for resetting the password with the code
        let url = URL(string: "http://localhost:3000/api/auth/changePassword")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "forgotPasswordCode": resetCode,
            "newPassword": newPassword
        ]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isRequestInProgress = false
                if let error = error {
                    self.errorMessage = "Failed to reset password: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        self.successMessage = "Password reset successfully."
                    case 400:
                        self.errorMessage = "Invalid reset code or email."
                    case 404:
                        self.errorMessage = "User not found."
                    default:
                        self.errorMessage = "An unexpected error occurred. Please try again."
                    }
                } else {
                    self.errorMessage = "No response from server."
                }
            }
        }.resume()
    }
}

