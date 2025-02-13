import SwiftUI

struct VerificationView: View {
    @State private var email: String = ""
    @State private var verificationCode: String = ""
    @State private var isVerified: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Verify Your Account")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Enter your email", text: $email)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()
            
            SecureField("Enter verification code", text: $verificationCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if isVerified {
                Text("Account Verified!")
                    .foregroundColor(.green)
                    .font(.headline)
            }
            
            Button(action: verifyCode) {
                Text("Verify")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(email.isEmpty || verificationCode.isEmpty)
        }
        .padding()
    }
    
    func verifyCode() {
        print("verify it")
        guard let url = URL(string: "http://localhost:3000/api/auth/verify") else {
            errorMessage = "Invalid URL"
            return
        }
        
        let body: [String: Any] = [
            "email": email,
            "verificationToken": verificationCode
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            errorMessage = "Failed to encode request"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    let message = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                    errorMessage = message?["message"] as? String ?? "Verification failed"
                    return
                }
                
                if let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if responseJSON["message"] as? String == "Account verified successfully!" {
                        isVerified = true
                        errorMessage = nil
                    } else {
                        errorMessage = responseJSON["message"] as? String
                    }
                } else {
                    errorMessage = "Invalid response"
                }
            }
        }.resume()
    }
}

