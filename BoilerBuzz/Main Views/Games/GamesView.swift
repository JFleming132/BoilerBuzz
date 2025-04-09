//
//  GamesView.swift
//  BoilerBuzz
//
//  Created by user272845 on 4/8/25.
//

import SwiftUI

struct GamesView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showGame = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Drinking Games")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.primary)

            Button(action: {
                showGame = true
            }) {
                Text("Start 2-Player Game")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .fullScreenCover(isPresented: $showGame) {
            SplitScreenGameView()
        }
        .padding()
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
    }
}
