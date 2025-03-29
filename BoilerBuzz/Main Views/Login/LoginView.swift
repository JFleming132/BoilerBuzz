import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var showFailedLogin = false
    @State private var errorMessage: String = "Invalid Credentials"
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
            "password": password,
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
            
            guard let data = data else { return }
                    
            do {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                if loginResponse.message == "Login successful" {
                    // Store the userID and token in UserDefaults
                    UserDefaults.standard.set(loginResponse.userId, forKey: "userId")
                    if let token = loginResponse.token {
                        UserDefaults.standard.set(token, forKey: "token")
                    }
                    UserDefaults.standard.set(loginResponse.isAdmin, forKey: "isAdmin")
                    UserDefaults.standard.set(loginResponse.isPromoted, forKey: "isPromoted")
                    UserDefaults.standard.set(username, forKey: "username")
                    UserDefaults.standard.set(loginResponse.rsvpEvents, forKey: "rsvpEvents")
                    print("Login successful: \(loginResponse.message)")
                    DispatchQueue.main.async {
                        isLoggedIn = true
                    }
                } else {
                    print("failed login!!!!!")
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
        
        struct LoginResponse: Codable {
            let message: String
            let userId: String
            let isAdmin: Bool
            let isPromoted: Bool
            let token: String?
            let rsvpEvents: [String]?
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                
                VStack {
                    Text("BoilerBuzz Login")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Rectangle()
                        .fill(tertiaryColor)
                        .frame(width: 150, height: 4)
                        .padding(.horizontal)
                        .cornerRadius(2)

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
                            .foregroundColor(tertiaryColor)
                    }
                    .background(.black)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10) // Same corner radius as the button
                            .stroke(tertiaryColor, lineWidth: 2) // Border with the desired color and width
                    )
                    .padding()
                    
                    if showFailedLogin {
                        Text("\(errorMessage). Please try again.")
                            .foregroundColor(.red)
                    }
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("New to BoilerBuzz? Sign Up!")
                            .foregroundColor(Color.blue) // iOS Blue color
                            .padding()
                    }
                    
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot password?")
                            .foregroundColor(Color.blue) // iOS Blue color
                            .padding()
                    }
                }
                .padding()
            }
        }
    }
}
