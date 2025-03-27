//
//  IdentificationView.swift
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 3/24/25.
//

import SwiftUI
import UIKit

struct IdentificationView: View {
    // MARK: - State Variables for User Input
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var dateOfBirth: String = "" // Alternatively use a DatePicker for production
    @State private var idNumber: String = ""
    @State private var address: String = ""
    
    // MARK: - Image Picker States
    @State private var showingImagePicker = false
    @State private var idImage: Image? = nil
    @State private var inputImage: UIImage? = nil
    
    var body: some View {
        NavigationView {
            Form {
                // Personal Information Section
                Section(header: Text("Personal Information").font(.headline)) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Date of Birth (YYYY-MM-DD)", text: $dateOfBirth)
                    TextField("ID Number", text: $idNumber)
                    TextField("Address", text: $address)
                }
                
                // ID Photo Section
                Section(header: Text("ID Photo").font(.headline)) {
                    if let idImage = idImage {
                        idImage
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .foregroundColor(.gray)
                            .opacity(0.4)
                    }
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Capture ID Photo")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                }
                
                // Submission Section
                Section {
                    Button(action: submitIdentification) {
                        Text("Submit Identification")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Identification")
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                CustomImagePicker(image: $inputImage)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        idImage = Image(uiImage: inputImage)
    }
    
    func submitIdentification() {
        // In a real app, you would validate the input and send it to your backend or a verification API.
        print("Submitted:")
        print("Name: \(firstName) \(lastName)")
        print("DOB: \(dateOfBirth)")
        print("ID Number: \(idNumber)")
        print("Address: \(address)")
        // Optionally, process the captured image (idImage) as well.
    }
}

/// A helper struct to integrate UIImagePickerController into SwiftUI.
/// Renamed to CustomImagePicker to avoid ambiguity.
struct CustomImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CustomImagePicker
        
        init(_ parent: CustomImagePicker) {
            self.parent = parent
        }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CustomImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        // Use camera if available; otherwise, fallback to photo library.
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

struct IdentificationView_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationView()
    }
}
