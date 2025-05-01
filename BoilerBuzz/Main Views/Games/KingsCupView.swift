//
//  KingsCupView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 4/22/25.
//

import SwiftUI

// MARK: – Rank & RuleVariation

extension Rank: Identifiable {
  var id: Rank { self }
  var displayName: String {
    switch self {
    case .ace:   return "Ace"
    case .two:   return "2"
    case .three: return "3"
    case .four:  return "4"
    case .five:  return "5"
    case .six:   return "6"
    case .seven: return "7"
    case .eight: return "8"
    case .nine:  return "9"
    case .ten:   return "10"
    case .jack:  return "Jack"
    case .queen: return "Queen"
    case .king:  return "King"
    }
  }
}

struct RuleVariation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}

// Predefined variations for each rank
let kingsRuleLibrary: [Rank: [RuleVariation]] = [
    .ace: [
        RuleVariation(title: "Waterfall", description: "Everyone drinks in sequence; each stops when the previous stops."),
        RuleVariation(title: "Race",     description: "Drawer picks an opponent; both race to finish their cup.")
    ],
    .two:  [ RuleVariation(title: "You", description: "Drawer points at another player; they drink.") ],
    .three:[ RuleVariation(title: "Me",  description: "Drawer drinks.") ],
    .four: [ RuleVariation(title: "Floor", description: "Last to touch the floor drinks.") ],
    .five: [
        RuleVariation(title: "Guys Drink", description: "All male players drink."),
        RuleVariation(title: "Drive",      description: "Drawer starts the game. Vroom continue with same direction, Skirt changes direction. First person that messes up drinks.")
    ],
    .six: [
        RuleVariation(title: "Chicks Drink", description: "All female players drink."),
        RuleVariation(title: "Thumb Master", description: "Drawer becomes Thumb Master until next 6.")
    ],
    .seven: [
        RuleVariation(title: "Heaven",    description: "Last to point up drinks."),
        RuleVariation(title: "Snake-Eyes",description: "Drawer is Snake-Eyes: making eye contact triggers a drink.")
    ],
    .eight: [
        RuleVariation(title: "Mate", description: "Drawer picks a mate—they drink together."),
        RuleVariation(title: "Hate", description: "Drawer picks someone to drink until told to stop; roles reverse on finish.")
    ],
    .nine: [ RuleVariation(title: "Rhyme", description: "Rhyme chain game; first to fail drinks.") ],
    .ten:  [ RuleVariation(title: "Categories", description: "Category chain game; first to fail drinks.") ],
    .jack: [
        RuleVariation(title: "Never Have I Ever", description: "Anyone who has done the prompt drinks."),
        RuleVariation(title: "Jokes",               description: "Told joke fails → drawer drinks twice.")
    ],
    .queen:[ RuleVariation(title: "Question Master", description: "As QM, asking a question forces answerers to drink.") ],
    .king: [
        RuleVariation(title: "King’s Cup",   description: "1st–3rd pour in cup; 4th King drinks it all."),
        RuleVariation(title: "Make a Rule",  description: "Make a lasting rule; violators drink. Last king drinks the cup.")
    ]
]
// MARK: – KingsCupView

struct KingsCupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showSettings = true
    @State private var showRulesDetail = false  
    @State private var showRulesOnDraw = false
    @State private var selectedIndex: [Rank: Int] = [:]
    @State private var showRuleOverlay = false


    @State private var deck: [Card] = Deck.standard.shuffled()
    @State private var drawnCards: [Card] = []

    @Namespace private var drawNamespace
    @State private var currentCard: Card? = nil
    @State private var isFlipped: Bool = false

    @State private var kingsDrawn: Int = 0

    @State private var gameOver: Bool = false


    var body: some View {
        ZStack {
            if showSettings {
                settingsView
            } else {
                gameView
            }

            if gameOver, let card = currentCard {
                gameOverOverlay(for: card)
            }
        }
    }

    // MARK: Settings

    private var settingsView: some View {
        NavigationView {
            Form {
                // MARK: — How to Play Section
                Section(header: Text("How to Play")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kings Cup is a social card-based drinking game for a group.")
                        Text("• Players sit in a circle and take turns drawing the top card from a central deck.")
                        Text("• When you draw, follow the rule associated with the card’s rank.")
                        Text("• The 4th King drawn drinks the entire contents of the center “King’s Cup.”")
                        Text("• Play continues until the deck is exhausted or you decide to reshuffle and start anew.")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("Show rules when drawing cards", isOn: $showRulesOnDraw)
                }

                // LOOP OVER RANK.SECTION
                ForEach(Rank.allCases, id: \.self) { rank in
                    // pull out this rank's variations into a local array
                    let variations = kingsRuleLibrary[rank] ?? []
                    Section(header: Text(rank.displayName)) {
                        // binding into selectedIndex
                        let bindingIndex = Binding<Int>(
                            get: { selectedIndex[rank] ?? 0 },
                            set: { selectedIndex[rank] = $0 }
                        )

                        // PICKER FROM 0..<variations.count
                        Picker("Variation", selection: bindingIndex) {
                            ForEach(0..<variations.count, id: \.self) { idx in
                                Text(variations[idx].title).tag(idx)
                            }
                        }
                        .pickerStyle(.menu)

                        // description of the currently selected variation
                        Text(variations[selectedIndex[rank] ?? 0].description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    Button("Start Game") {
                        for rank in Rank.allCases {
                            selectedIndex[rank] = selectedIndex[rank] ?? 0
                        }
                        showSettings = false
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    Button("Back to Games") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Kings Cup Rules")
        }
    }

    // MARK: Game View

    private var gameView: some View {
    ZStack {
        VStack(spacing: 0) {
            // MARK: — Scrollable Main Content
            ScrollView {
                VStack(spacing: 20) {
                    // ─── TOP BAR ────────────────────────────────────────────
                    HStack {
                        Button {
                            resetGame()
                        } label: {
                            Image(systemName: "arrow.clockwise.circle")
                                .imageScale(.large)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                            Text("\(kingsDrawn)/4")
                                .font(.headline)
                        }
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.yellow.opacity(0.2)))
                    }
                    .padding(.horizontal)

                    // ─── TITLE & RULES TOGGLE ───────────────────────────────
                    Text("Kings Cup")
                        .font(.largeTitle).bold()

                    Button {
                        showRulesDetail.toggle()
                    } label: {
                        Text(showRulesDetail ? "Hide Rules" : "Show Rules")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)

                    // ─── RULES DETAIL ──────────────────────────────────────
                    if showRulesDetail {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(Rank.allCases, id: \.self) { rank in
                                    let variations = kingsRuleLibrary[rank] ?? []
                                    let variation = variations[selectedIndex[rank] ?? 0]
                                    HStack {
                                        Text("\(rank.displayName):")
                                            .fontWeight(.semibold)
                                        Text(variation.title)
                                    }
                                    Text(variation.description)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 16)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 250)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }

                    // ─── DECK FAN ───────────────────────────────────────────
                    DeckFanView(deckCount: deck.count)
                        .padding(.top)
                        .onTapGesture { drawCard() }
                        .disabled(showRuleOverlay || gameOver)

                    // ─── REVEAL SLOT ───────────────────────────────────────
                    ZStack {
                        if currentCard == nil {
                            Rectangle()
                                .strokeBorder(Color.secondary, lineWidth: 1)
                                .frame(width: 80, height: 120)
                                .opacity(0.3)
                                .matchedGeometryEffect(id: "drawnCard",
                                                       in: drawNamespace)
                        }
                        if let card = currentCard {
                            Image(isFlipped ? card.imageName : "card_back")
                                .resizable()
                                .frame(width: 80, height: 120)
                                .matchedGeometryEffect(id: "drawnCard",
                                                       in: drawNamespace)
                                .rotation3DEffect(
                                    .degrees(isFlipped ? 0 : 180),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                        }
                    }
                    .frame(height: 140)

                    // ─── DRAW HISTORY ──────────────────────────────────────
                    if !drawnCards.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(drawnCards) { c in
                                    Image(c.imageName)
                                        .resizable()
                                        .frame(width: 40, height: 60)
                                        .shadow(radius: 1)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 80)
                    }
                }
                .padding()
            }

            Spacer(minLength: 0)

            // MARK: — Footer Buttons
            HStack(spacing: 16) {
                Button("Back to Rules") {
                    resetGame()
                    showSettings = true
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Back to Games") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(UIColor.systemBackground).shadow(radius: 2))
        }

        // MARK: — Rule Overlay
        if showRuleOverlay, let card = currentCard {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 16) {
                Image(card.imageName)
                    .resizable()
                    .frame(width: 100, height: 140)
                    .shadow(radius: 4)

                let variation = kingsRuleLibrary[card.rank]![selectedIndex[card.rank] ?? 0]
                Text(variation.title)
                    .font(.title2).bold()
                Text(variation.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Got It") {
                    withAnimation {
                        showRuleOverlay = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemBackground)))
            .frame(maxWidth: 300)
        }
    }
}



    // MARK: – Draw logic
    private func drawCard() {
        guard !deck.isEmpty else { return }
        // 1) If there’s already a card revealed, move it to history
        if let prev = currentCard {
            drawnCards.append(prev)
        }
        // 2) Pull the next card into currentCard, reset flip
        let drawn = deck.removeFirst()
        currentCard = drawn
        isFlipped = false

        // Schedule the flip every time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.6)) {
                isFlipped = true
            }
        }

        // then show the rule overlay
        if showRulesOnDraw {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showRuleOverlay = true
            }
        }

        if drawn.rank == .king {
            kingsDrawn += 1
            if kingsDrawn == 4 {
                // handle game-over for final King…
                gameOver = true
            }
        }
    }

    private func resetGame() {
        // back to fresh state
        deck = Deck.standard.shuffled()
        drawnCards.removeAll()
        currentCard = nil
        isFlipped = false
        kingsDrawn = 0
        showRulesDetail = false
    }

    private func gameOverOverlay(for card: Card) -> some View {
        // Always the final King on currentCard
        let variation = RuleVariation(
            title: "King’s Cup",
            description: "You must drink the entire King’s Cup!"
        )

        return ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(card.imageName)
                    .resizable().frame(width: 100, height: 140)
                Text(variation.title)
                    .font(.title2).bold()
                Text(variation.description)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                HStack(spacing: 12) {
                    Button("Reset") {
                        resetGame()
                        gameOver = false
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Continue") {
                        // collect final King and dismiss overlay
                        if let final = currentCard {
                            drawnCards.append(final)
                        }
                        currentCard = nil
                        isFlipped = false
                        gameOver = false
                    }
                    .buttonStyle(.bordered)

                    Button("Back to Games") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemBackground)))
            .frame(maxWidth: 300)
        }
    }

}


/// A small fan of card-back images arranged in a semicircle.
struct DeckFanView: View {
    let deckCount: Int
    /// How many cards in the fan at once
    let visibleCount: Int = 10
    /// Maximum rotation spread (in degrees) across the fan
    let spread: Double = 140

    var body: some View {
        ZStack {
            // Only take as many as we want to display
            ForEach(0..<min(deckCount, visibleCount), id: \.self) { i in
                // Evenly space angles from -spread/2 … +spread/2
                let step = spread / Double(max(visibleCount - 1, 1))
                let angle = -spread/2 + Double(i) * step

                Image("card_back")
                    .resizable()
                    .frame(width: 60, height: 90)
                    .rotationEffect(.degrees(angle))
                    // Offset along a shallow arc (radius can be tweaked)
                    .offset(
                      x: CGFloat(sin(angle * .pi/180)) * 80,
                      y: CGFloat(-cos(angle * .pi/180)) * 10
                    )
                    .shadow(radius: 2)
            }
        }
        // Reserve enough vertical space for the fan
        .frame(height: 140)
    }
}

struct KingsCupView_Previews: PreviewProvider {
    static var previews: some View {
        KingsCupView()
    }
}
