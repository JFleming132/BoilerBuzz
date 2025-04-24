//
//  CreateDrinkSpecialView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 4/24/25.
//


import SwiftUI

// MARK: - Models
struct OfferInput: Identifiable {
    let id = UUID()
    var name: String = ""
    var price: Double = 0.0
}

struct Offer: Codable, Identifiable {
    let id = UUID()
    let name: String
    let price: Double
}

struct DrinkSpecial: Identifiable, Decodable {
    let id: String
    let title: String
    let barName: String
    let description: String?
    let imageUrl: String?
    let offers: [Offer]
    let createdAt: TimeInterval
    let expiresAt: TimeInterval
}

struct CreateDrinkSpecialView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var expiresAt: Date = Date()
    @State private var offers: [OfferInput] = [OfferInput()] // start with one row
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker: Bool = false

    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    /// Callback invoked when a special is successfully created
    var onCreated: ((DrinkSpecial) -> Void)? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Special Details")) {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.never)
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.2))
                        )
                        .textInputAutocapitalization(.never)
                }

                Section(header: Text("Offers")) {
                    ForEach(offers.indices, id: \ .self) { index in
                        HStack {
                            TextField("Name", text: $offers[index].name)
                                .textInputAutocapitalization(.never)
                            TextField(
                                "Price", value: $offers[index].price,
                                format: .number
                            )
                            .keyboardType(.decimalPad)
                             .frame(width: 80)
                             Spacer()
                             // Delete button for each offer
                            Button(action: {
                                offers.remove(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    Button(action: {
                        offers.append(OfferInput())
                    }) {
                        Label {
                            Text("Add Offer")
                        } icon: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }

                Section(header: Text("Image (optional)")) {
                    if let img = selectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }
                    Button(selectedImage == nil ? "Select Image" : "Change Image") {
                        showImagePicker = true
                    }
                }

                Section(header: Text("Expires At")) {
                    DatePicker(
                        "Expiration", selection: $expiresAt,
                        in: Date()..., displayedComponents: [.date, .hourAndMinute]
                    )
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Drink Special")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Save") {
                            createSpecial()
                        }
                        .disabled(title.isEmpty || offers.isEmpty || !offersValid())
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: Binding(
                    get: { selectedImage ?? UIImage() },
                    set: { selectedImage = $0 }
                ))
            }
        }
    }

    private func offersValid() -> Bool {
        // Ensure at least one valid offer
        for offer in offers {
            if offer.name.isEmpty { return false }
            if Double(offer.price) == nil { return false }
        }
        return true
    }

    private func createSpecial() {
        guard !isSubmitting else { return }
        // Fetch author and barName from UserDefaults
        guard let author = UserDefaults.standard.string(forKey: "userId"),
              let barName = UserDefaults.standard.string(forKey: "username") else {
            errorMessage = "User information unavailable"
            return
        }

        let imageDataStr: String = {
            guard let data = selectedImage?.jpegData(compressionQuality: 0.8) else { return "" }
            return data.base64EncodedString()
        }()

        isSubmitting = true
        errorMessage = nil

        // Build offers payload
        let offersPayload = offers.map { ["name": $0.name, "price": $0.price] }
        let body: [String: Any] = [
            "title": title,
            "author": author,
            "barName": barName,
            "description": description,
            "imageUrl": imageDataStr,
            "offers": offersPayload,
            "expiresAt": Int(expiresAt.timeIntervalSince1970 * 1000)
        ]

        print("Creating special with body: \(body)")


        // Request setup
        guard let url = URL(string: "http://localhost:3000/api/drinkspecials") else {
            errorMessage = "Invalid endpoint URL"
            isSubmitting = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                guard let data = data,
                      let created = try? JSONDecoder().decode(DrinkSpecial.self, from: data) else {
                    errorMessage = "Failed to decode server response"
                    return
                }
                // Invoke callback and dismiss
                onCreated?(created)
                presentationMode.wrappedValue.dismiss()
            }
        }.resume()
    }
}

struct CreateDrinkSpecialView_Previews: PreviewProvider {
    static var previews: some View {
        CreateDrinkSpecialView(onCreated: { special in
            print("Created special: \(special)")
        })
    }
}
