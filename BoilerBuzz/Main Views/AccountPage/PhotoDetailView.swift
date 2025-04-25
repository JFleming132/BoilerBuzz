//
//  PhotoDetailView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 3/30/25.
//

import SwiftUI
import UIKit

struct PhotoDetailView: View {
    let photo: Photo
    let isOwnProfile: Bool
    let isAdmin: Bool
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: photo.url)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                } else if phase.error != nil {
                    Text("Error loading image")
                } else {
                    ProgressView()
                }
            }
            .padding()
        }
        .navigationTitle("Photo Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwnProfile || isAdmin {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityIdentifier("deletePhotoButton")
                }
            }
        }
        .alert("Delete Photo", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deletePhoto()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this photo?")
        }
    }
    
    func deletePhoto() {
        guard let url = URL(string: backendURL + "api/photo/\(photo.id)") else {
            print("Invalid URL for photo deletion")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting photo: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response deleting photo")
                return
            }
            
            DispatchQueue.main.async {
                // Dismiss the detail view upon successful deletion.
                presentationMode.wrappedValue.dismiss()
                // Optionally, post a notification or call a callback to refresh the photos grid.
            }
        }.resume()
    }
}
