//
//  AccountSettingsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/14/25.
//

import SwiftUI

struct AccountSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var profileData: ProfileViewModel
    @State private var isImagePickerPresented = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                    Text("Edit Profile")
                        .font(.headline)
                        .accessibilityIdentifier("editProfileLabel")
                    Spacer()
                    Button("Done") {
                        saveProfileChanges()
                    }
                    .foregroundColor(.blue)
                    .accessibilityIdentifier("doneButton")
                }
                .padding()

                // Show error message if available
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .accessibilityIdentifier("errorMessageLabel")
                }

                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Picture
                        Button(action: {
                            isImagePickerPresented.toggle()
                        }) {
                            VStack {
                                Image(uiImage: profileData.profilePicture)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                Text("Change profile photo")
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                            }
                        }
                        .sheet(isPresented: $isImagePickerPresented) {
                            // Wrap the non-optional binding in an optional binding.
                            ImagePicker(image: Binding<UIImage?>(
                                get: { profileData.profilePicture },
                                set: { newValue in
                                    if let newImage = newValue {
                                        profileData.profilePicture = newImage
                                    }
                                }
                            ))
                        }
                        
                        // Username
                        VStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Username")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                TextField("Enter username", text: $profileData.username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textInputAutocapitalization(.never)
                                    .accessibilityIdentifier("usernameTextField")
                            }
                            // Bio
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Bio")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                TextEditor(text: $profileData.bio)
                                    .frame(height: 100)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                                    .padding(.vertical, 5)
                            }
                        }
                        .padding(.horizontal)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarBackButtonHidden(true)
    }
    

    // Save profile changes to the server
    func saveProfileChanges() {
        guard let url = URL(string: "http://localhost:3000/api/profile/\(profileData.userId)") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "username": profileData.username,
            "bio": profileData.bio,
            "profilePicture": profileData.profilePicture.base64!
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating profile: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Error updating profile."
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 400 {
                    // Decode the error message from the response
                    if let data = data,
                       let errorResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let message = errorResponse["message"] as? String {
                        DispatchQueue.main.async {
                            self.errorMessage = message
                        }
                    }
                    return  // Do not dismiss the view on error.
                } else if httpResponse.statusCode == 200 {
                    // On success, dismiss the view.
                    DispatchQueue.main.async {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }.resume()
    }
}

// ImagePicker for selecting profile picture
// Right now only allows to select picture, doesnt actually save it.
// Also need to test edge cases
import PhotosUI
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary // Default to photo library; can be .camera

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed.
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.image = selectedImage
                }
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// Preview
struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountSettingsView(profileData: ProfileViewModel())
        }
    }
}
