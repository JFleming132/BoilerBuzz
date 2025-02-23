import SwiftUI

struct PrivacySecuritySettingsView: View {
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Change Password")) {
                    SecureField("Current Password", text: $oldPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmNewPassword)
                }

                Button(action: updatePassword) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Update Password")
                    }
                }
                .disabled(isLoading)
            }
            .navigationTitle("Privacy & Security")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Password Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    func updatePassword() {
        guard newPassword == confirmNewPassword else {
            alertMessage = "New passwords do not match."
            showAlert = true
            return
        }

        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            alertMessage = "User ID not found. Please log in again."
            showAlert = true
            return
        }

        isLoading = true

        let url = URL(string: "http://localhost:3000/api/auth/update-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "oldPassword": oldPassword,
            "newPassword": newPassword
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                guard let data = data else {
                    alertMessage = "No data received from the server."
                    showAlert = true
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let message = json["message"] as? String {
                            alertMessage = message
                            showAlert = true
                            if message == "Password updated successfully!" {
                                // Clear the password fields
                                oldPassword = ""
                                newPassword = ""
                                confirmNewPassword = ""
                            }
                        }
                    }
                } catch {
                    alertMessage = "Error decoding response: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }.resume()
    }
}

struct PrivacySecuritySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacySecuritySettingsView()
    }
}

