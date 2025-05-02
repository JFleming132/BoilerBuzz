//
//  BarSpecialsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 4/24/25.
//

import SwiftUI
import UIKit


struct BarSpecialsView: View {
    let barId: String
    @State private var specials: [DrinkSpecial] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false


    private var isOwnBar: Bool {
        UserDefaults.standard.string(forKey: "userId") == barId
    }

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView("Loading Specials…")
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if specials.isEmpty {
                Text("No drink specials available for this bar.")
                    .foregroundColor(.gray)
                    .italic()
                    .padding()
            } else {
                ForEach(specials) { special in
                    VStack(alignment: .leading, spacing: 8) {
                        if let base64 = special.imageUrl,
                           let data = Data(base64Encoded: base64),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .clipped()
                        }

                        HStack {
                            Text(special.title)
                                .font(.headline)
                            Spacer()
                            if isOwnBar {
                                Button(role: .destructive) {
                                    deleteSpecial(special)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }

                        Text("Posted: \(Date(timeIntervalSince1970: special.createdAt/1000), style: .date)")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("Expires: \(Date(timeIntervalSince1970: special.expiresAt/1000), style: .date)")
                            .font(.caption)
                            .foregroundColor(.gray)

                        if let desc = special.description, !desc.isEmpty {
                            Text(desc)
                                .font(.body)
                                .lineLimit(2)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(special.offers) { offer in
                                HStack {
                                    Text(offer.name)
                                    Spacer()
                                    Text(String(format: "$%.2f", offer.price))
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 1)
                }
            }
        }
        .padding(.horizontal)
        .onAppear(perform: fetchBarSpecials)
    }

    private func fetchBarSpecials() {
        isLoading = true
        errorMessage = nil
        let url = URL(string: "http://54.146.194.154:3000/api/drinkspecials/bar/\(barId)")!
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let list = try decoder.decode([DrinkSpecial].self, from: data)
                    let nowMs = Date().timeIntervalSince1970 * 1000
                    specials = list.filter { $0.expiresAt > nowMs }
                        .sorted { $0.expiresAt < $1.expiresAt }
                } catch {
                    errorMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func deleteSpecial(_ special: DrinkSpecial) {
        guard let url = URL(string: "http://54.146.194.154:3000/api/drinkspecials/\(special.id)") else {
            errorMessage = "Invalid delete URL"; return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = error.localizedDescription; return
                }
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    errorMessage = "Failed to delete special"; return
                }
                // Remove from our list
                specials.removeAll { $0.id == special.id }
            }
        }.resume()
    }
}

struct BarSpecialsView_Previews: PreviewProvider {
    static var previews: some View {
        BarSpecialsView(barId: "")
    }
}
