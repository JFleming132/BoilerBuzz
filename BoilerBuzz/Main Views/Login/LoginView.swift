import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var showFailedLogin = false
    @State private var errorMessage: String = "Invalid Credentials"
    @Binding var isLoggedIn: Bool
    
    // MARK: - Login Request
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
                DispatchQueue.main.async {
                    if loginResponse.message == "Login successful" {
                        UserDefaults.standard.set(loginResponse.userId, forKey: "userId")
                        UserDefaults.standard.set(loginResponse.isAdmin, forKey: "isAdmin")
                        UserDefaults.standard.set(loginResponse.isPromoted, forKey: "isPromoted")
                        UserDefaults.standard.set(username, forKey: "username")
                        UserDefaults.standard.set(loginResponse.rsvpEvents, forKey: "rsvpEvents")

                        print("UserID stored: \(loginResponse.userId)")
                        print("isAdmin stored: \(loginResponse.isAdmin)")
                        print("isPromoted stored: \(loginResponse.isPromoted)")
                        print("rsvpEvents stored: \(String(describing: loginResponse.rsvpEvents))")
                        print("Login successful: \(loginResponse.message)")
                        isLoggedIn = true
                        if let prefs = loginResponse.notificationPreferences {
                            // Convert the entire notificationPreferences to a dictionary
                            if let encodedPrefs = try? JSONEncoder().encode(prefs),
                            let prefsDict = try? JSONSerialization.jsonObject(with: encodedPrefs, options: []) as? [String: Any] {
                                UserDefaults.standard.set(prefsDict, forKey: "notificationPreferences")
                            }
                        }
                    } else {
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
    
    struct LoginResponse: Codable {
        let message: String
        let userId: String
        let isAdmin: Bool
        let isPromoted: Bool
        let token: String?
        let rsvpEvents: [String]?
        let notificationPreferences: NotificationPreferences?
    }
    
    // MARK: - Biometric Auth
    func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate with Face ID to access your account"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        checkServerAvailability { isServerUp in
                            if isServerUp {
                                isLoggedIn = true
                            }
                        }
                    }
                }
            }
        }
    }

    func checkServerAvailability(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3000/api/auth/health") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
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
               // On appear, check if a userId is saved and if the server is available before prompting biometric authentication.
               .onAppear {
                   if let savedUserId = UserDefaults.standard.string(forKey: "userId") {
                       print("UserID found: \(savedUserId) on load. Checking server availability...")
                       checkServerAvailability { isServerUp in
                           if isServerUp {
                               print("Server is up, initiating biometric authentication.")
                               authenticateWithBiometrics()
                           } else {
                               print("Server is down, skipping biometric authentication.")
                           }
                       }
                   } else {
                       print("No userID found on load. Skipping biometric authentication.")
                   }
               }
           }
       }
   }
