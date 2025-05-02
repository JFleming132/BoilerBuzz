//
//  SpecialsView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 4/24/25.
//

import SwiftUI
import CoreLocation


struct SpecialsView: View {
    @State private var specials: [DrinkSpecial] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading Specials…")
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if specials.isEmpty {
                    Text("No drink specials available.")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                } else {
                    List(specials) { special in
                        VStack(alignment: .leading, spacing: 10) {
                            // Display image if available
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
                                VStack(alignment: .leading) {
                                    Text(special.title)
                                        .font(.headline)
                                    Text(special.barName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(Date(timeIntervalSince1970: special.expiresAt/1000), style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            if let desc = special.description {
                                Text(desc)
                                    .font(.body)
                                    .lineLimit(2)
                            }

                            VStack(alignment: .leading) {
                                ForEach(special.offers) { offer in
                                    HStack {
                                        Text(offer.name)
                                        Spacer()
                                        Text(String(format: "$%.2f", offer.price))
                                    }
                                    .font(.subheadline)
                                }
                            }
                            .padding(.top, 5)
                        }
                        .padding(.vertical, 8)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Drink Specials")
            .onAppear(perform: fetchSpecials)
        }
    }

    private func fetchSpecials() {
        isLoading = true
        errorMessage = nil
        let url = URL(string: "http://54.146.194.154:3000/api/drinkspecials")!
        URLSession.shared.dataTask(with: url) { data, response, error in
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
                    // filter out expired
                    let nowMs = Date().timeIntervalSince1970 * 1000
                    specials = list
                        .filter { $0.expiresAt > nowMs }
                        .sorted { $0.expiresAt < $1.expiresAt }
                } catch {
                    errorMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct SpecialsView_Previews: PreviewProvider {
    static var previews: some View {
        SpecialsView()
    }
}
