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
    @State private var selectedImage: UIImage? = nil// Should be profileData.profilePicture eventually once we start storing them
    @State private var isImagePickerPresented = false
    @State private var errorMessage: String? = nil
    
    init(profileData: ProfileViewModel) {
        self.selectedImage = profileData.profilePicture
        self.profileData = profileData
    }
    
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
                    Spacer()
                    Button("Done") {
                        saveProfileChanges()
                    }
                    .foregroundColor(.blue)
                }
                .padding()

                // Show error message if available
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Picture
                        Button(action: {
                            isImagePickerPresented.toggle()
                        }) {
                            VStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                }
                                Text("Change profile photo")
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                            }
                        }
                        .sheet(isPresented: $isImagePickerPresented) {
                            ImagePicker(image: $selectedImage)
                        }
                        
                        // Username
                        VStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Username")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                TextField("Enter username", text: $profileData.username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
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
            //properly encode and save profilePicture to database
            //"profilePicture": profileData.profilePicture
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    self.parent.image = image as? UIImage
                }
            }
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
