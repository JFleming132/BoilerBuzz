import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var showFailedLogin = false
    @State private var errorMessage: String = "Invalid Credentials"
    @Binding var isLoggedIn: Bool
    
    // MARK: - Login Request Function
    func loginRequest() {
        print("Attempting login request...")
        guard let url = URL(string: "http://localhost:3000/api/auth/login") else {
            print("Invalid URL")
            return
        }
        
        let parameters = [
            "username": username,
            "password": password,
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            print("Failed to encode parameters")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    showFailedLogin = true
                }
                return
            }
            
            guard let data = data else { return }
                    
            do {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                if loginResponse.message == "Login successful" {
                    // Store the userId locally.
                    UserDefaults.standard.set(loginResponse.userId, forKey: "userId")
                    print("UserID stored: \(loginResponse.userId)")
                    
                    UserDefaults.standard.set(loginResponse.isAdmin, forKey: "isAdmin")
                    print("isAdmin stored: \(loginResponse.isAdmin)")
                    
                    print("Login successful: \(loginResponse.message)")
                    DispatchQueue.main.async {
                        isLoggedIn = true
                    }
                } else {
                    print("Failed login: \(loginResponse.message)")
                    DispatchQueue.main.async {
                        errorMessage = loginResponse.message
                        showFailedLogin = true
                    }
                }
            } catch {
                print("Error decoding login response: \(error)")
                DispatchQueue.main.async {
                    showFailedLogin = true
                }
            }
        }.resume()
    }
    
    // Define your LoginResponse model (without token)
    struct LoginResponse: Codable {
        let message: String
        let userId: String
        let isAdmin: Bool
    }
    
    // MARK: - Biometric Authentication Function
    func authenticateWithBiometrics() {
        print("Attempting biometric authentication...")
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            print("Biometric authentication is available.")
            let reason = "Authenticate with FaceID to access your account."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                print("Biometric evaluation completed. Success: \(success), error: \(authError?.localizedDescription ?? "nil")")
                DispatchQueue.main.async {
                    if success {
                        print("Biometric authentication successful. Setting isLoggedIn to true.")
                        isLoggedIn = true
                    } else {
                        print("Biometric authentication failed: \(authError?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            print("Biometric authentication not available. Error: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    // MARK: - View Body
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    Text("BoilerBuzz Login")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Rectangle()
                        .fill(tertiaryColor) // Replace tertiaryColor with your actual color.
                        .frame(width: 150, height: 4)
                        .padding(.horizontal)
                        .cornerRadius(2)
                    
                    TextField("Username", text: $username)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        // You can remove any onTapGesture from here since biometric is now triggered onAppear.
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        if !username.isEmpty && !password.isEmpty {
                            loginRequest()
                        } else {
                            showFailedLogin = true
                        }
                    }) {
                        Text("Login")
                            .padding()
                            .foregroundColor(tertiaryColor)
                    }
                    .background(Color.black)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(tertiaryColor, lineWidth: 2)
                    )
                    
                    if showFailedLogin {
                        Text("\(errorMessage). Please try again.")
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
            // On appear, check if a userId is saved, and if so, prompt biometric authentication.
            .onAppear {
                if let savedUserId = UserDefaults.standard.string(forKey: "userId") {
                    print("UserID found: \(savedUserId) on load. Initiating biometric authentication.")
                    authenticateWithBiometrics()
                } else {
                    print("No userID found on load. Skipping biometric authentication.")
                }
            }
        }
    }
}
