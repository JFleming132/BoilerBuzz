//
//  UserRatingPopup.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 3/26/25.
//


import SwiftUI

/// A star rating input view that supports half‑star increments.
struct StarRatingInputView: View {
    @Binding var rating: Float  // Expected in increments of 0.5, from 0 to maximumRating
    var maximumRating: Int = 5
    let starSize: CGFloat = 44
    let spacing: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            // Calculate total width of the star component based on fixed sizes and spacing.
            let totalWidth = starSize * CGFloat(maximumRating) + spacing * CGFloat(maximumRating - 1)
            
            HStack(spacing: spacing) {
                ForEach(0..<maximumRating, id: \.self) { index in
                    let starNumber = Float(index) + 1.0
                    let fullStar = rating >= starNumber
                    let halfStar = rating >= (starNumber - 0.5) && rating < starNumber
                    ZStack {
                        if fullStar {
                            Image(systemName: "star.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.yellow)
                        } else if halfStar {
                            Image(systemName: "star.leadinghalf.filled")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.yellow)
                        } else {
                            Image(systemName: "star")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.yellow)
                        }
                    }
                    .frame(width: starSize, height: starSize)
                }
            }
            .frame(width: totalWidth)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        // Use the fixed totalWidth for calculation.
                        let computed = (value.location.x / totalWidth) * CGFloat(maximumRating)
                        let newRating = (Float(computed) * 2).rounded() / 2
                        rating = min(max(newRating, 0), Float(maximumRating))
                    }
            )
            // Center the fixed width HStack in the available geometry.
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: starSize)
    }
}

/// A popup view that lets the user rate with half‑star increments and leave feedback.
struct UserRatingPopup: View {
    @Binding var isPresented: Bool
    @State private var selectedRating: Float = 0.0
    @State private var feedback: String = ""
    
    // Closure called when the rating is submitted.
    var submitAction: ((Float, String) -> Void)?

    var body: some View {
        ZStack {
            // Semi-transparent background that dismisses the popup when tapped.
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // The popup card.
            VStack(spacing: 16) {
                Text("Rate This User")
                    .font(.headline)
                
                // Use the custom star rating input view (assumed defined elsewhere).
                StarRatingInputView(rating: $selectedRating)
                
                Text("Selected Rating: \(selectedRating, specifier: "%.1f")")
                    .font(.subheadline)
                
                TextField("Leave feedback (optional)", text: $feedback)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .textInputAutocapitalization(.never)
                
                HStack {
                    Button("Cancel") {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    Spacer()
                    Button("Submit") {
                        submitAction?(selectedRating, feedback)
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .disabled(selectedRating == 0)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 8)
            .padding(40)
        }
    }
}
