//
//  RideTheBusView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 4/22/25.
//


import SwiftUI

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    let amplitude: CGFloat = 10
    let frequency: CGFloat = 8

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translationX = amplitude * sin(animatableData * .pi * CGFloat(frequency))
        return ProjectionTransform(CGAffineTransform(translationX: translationX, y: 0))
    }
}

enum GameMode {
    case strikes(limit: Int)
    case timer(duration: TimeInterval)
}


struct RideTheBusView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Configuration & Settings
    @State private var showSettings: Bool = true
    @State private var isTimerMode: Bool = false
    @State private var strikesLimit: Int = 5
    @State private var timerDuration: TimeInterval = 60
    private var gameMode: GameMode? {
        showSettings ? nil : (isTimerMode ? .timer(duration: timerDuration) : .strikes(limit: strikesLimit))
    }

    // MARK: - Game State
    @State private var deck: [Card] = []
    @State private var previousCards: [Card] = []
    @State private var currentCard: Card? = nil
    @State private var currentPhase: GuessPhase = .color
    @State private var strikes: Int = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var gameOver: Bool = false
    @State private var didWin: Bool = false
    
    // MARK: - Shuffle Animation State
    @State private var shuffleOffsets: [CGSize] = []
    @State private var shuffleRotations: [Double] = []
    @State private var isShuffled: Bool = false

    @State private var shakeTrigger: CGFloat = 0
    @State private var isShaking: Bool = false

    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            Color.green.opacity(0.1).ignoresSafeArea()

            if showSettings {
                settingsView
            } else if !isShuffled {
                deckBackView
            } else {
                gameContentView
            }

            
            if gameOver {
                gameOverOverlay
            }

            if didWin {
                winOverlay
            }
        }
    }

    // MARK: - Settings Screen
    private var settingsView: some View {
        VStack(spacing: 20) {
            Text("Ride the Bus Rules")
                .font(.largeTitle)
            Text("Guess color, then high/low, then inside/outside, then suit. Ace High. Choose a mode below to start.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Toggle("Timed Mode", isOn: $isTimerMode)
                .padding(.horizontal)

            if isTimerMode {
                Stepper("Time: \(Int(timerDuration)) seconds", value: $timerDuration, in: 10...300, step: 10)
                    .padding(.horizontal)
            } else {
                Stepper("Strikes Allowed: \(strikesLimit)", value: $strikesLimit, in: 1...100)
                    .padding(.horizontal)
            }

            Button("Start") {
                initializeDeck()
                withAnimation { showSettings = false }
                performShuffleAnimation()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

    // MARK: - Deck Back View & Shuffle Animation
    private var deckBackView: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(deck.indices, id: \.self) { i in
                    Image("card_back")
                        .resizable()
                        .frame(width: 80, height: 120)
                        .offset(shuffleOffsets.indices.contains(i) ? shuffleOffsets[i] : .zero)
                        .rotationEffect(.degrees(shuffleRotations.indices.contains(i) ? shuffleRotations[i] : 0))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                isShuffled = false
            }
        }
    }

    private func initializeDeck() {
        deck = Deck.standard.shuffled()
        previousCards.removeAll()
        currentCard = nil
        currentPhase = .color
        strikes = 0
        timeRemaining = timerDuration
        isShuffled = false
        didWin = false
        isShaking = false
        shakeTrigger = 0
        gameOver = false
        

        shuffleOffsets = Array(repeating: .zero, count: deck.count)
        shuffleRotations = Array(repeating: 0, count: deck.count)
    }

    private func performShuffleAnimation() {
        // Scatter cards
        withAnimation(.easeOut(duration: 0.5)) {
            for i in deck.indices {
                shuffleOffsets[i] = CGSize(width: CGFloat.random(in: -50...50), height: CGFloat.random(in: -80...80))
                shuffleRotations[i] = Double.random(in: -20...20)
            }
        }
        // Gather and finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeIn(duration: 0.5)) {
                for i in deck.indices {
                    shuffleOffsets[i] = .zero
                    shuffleRotations[i] = 0
                }
            }
            // Show game UI
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isShuffled = true
            }
        }
    }

    // MARK: - Game UI
    private var gameContentView: some View {
        VStack(spacing: 20) {
            // End Game Button + Counter
            HStack {
                if let mode = gameMode {
                    switch mode {
                    case .strikes(let limit):
                        Text("Strikes: \(strikes)/\(limit)")
                    case .timer(_):
                        Text("Time: \(Int(timeRemaining))s")
                    }
                }
                Spacer()
                Button("End Game") { gameOver = true }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            // Deck
            Image("card_back").resizable().frame(width: 80, height: 120)

            Text("Guess: \(currentPhase.prompt)")
                .font(.headline)

            if let card = currentCard {
                CardView(card: card)
                    .modifier(ShakeEffect(animatableData: shakeTrigger))
                    .transition(.scale)
            } else {
                Text("No Card").font(.largeTitle)
            }

            PhasePromptView(phase: currentPhase) { guess in
                if !isShaking { drawCardAndHandleGuess(guess) }
            }
            .disabled(isShaking)

            Spacer()
        }
        .padding()
        .onAppear {
            // Start timer if timed mode
            if case .timer = gameMode {
                startTimer()
            }
        }
    }

    private func startMode() {
        // Reset counters
        strikes = 0; timeRemaining = timerDuration
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if gameOver == true {
                timer?.invalidate()
            }
            if timeRemaining > 0 { timeRemaining -= 1 }
            else { timer?.invalidate(); gameOver = true }
        }
    }

    private var gameOverOverlay: some View {
        VStack(spacing: 20) {
            Text("Game Over")
                .font(.largeTitle)
                .foregroundColor(.white)
            if let mode = gameMode {
                switch mode {
                case .strikes(let limit):
                    Text("Strikes: \(strikes)/\(limit)")
                        .foregroundColor(.white)
                case .timer:
                    Text("Times Up!")
                        .foregroundColor(.white)
                }
            }

            Button("Play Again") {
                reset()
                showSettings = true
                isShuffled = false
                gameOver = false
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            Button("Back to Games") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }

    private var winOverlay: some View {
        VStack(spacing: 20) {
            Text("You Win!")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            Text("Congratulations")
                .font(.title2)

            Button("Play Again") {
                reset()
                showSettings = true
                isShuffled = false
                didWin = false
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            Button("Back to Games") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }

    private func reset() {
        strikes = 0
        timeRemaining = timerDuration
        currentCard = nil
        previousCards.removeAll()
        currentPhase = .color
        isShaking = false
        gameOver = false
        didWin = false
        deck.removeAll()
        previousCards.removeAll()
        currentCard = nil
        currentPhase = .color
        isShuffled = false
        showSettings = true
        timer?.invalidate()
        timer = nil
        shakeTrigger = 0
    }

    // MARK: - Draw & Guess Handling
    private func drawCardAndHandleGuess(_ guess: Guess) {
        guard !deck.isEmpty else { return }
        let drawn = deck.removeFirst()
        withAnimation(.easeIn(duration: 0.5)) {
            currentCard = drawn
        }
        evaluateGuess(guess, with: drawn)
    }

    private func evaluateGuess(_ guess: Guess, with drawn: Card) {
        switch currentPhase {
        case .color:
            let actual: CardColor = [.hearts, .diamonds].contains(drawn.suit) ? .red : .black
            if case .color(let c) = guess, c == actual {
                previousCards = [drawn]
                currentPhase = .highLow
            } else {
                if isStrikesMode {
                    strikes += 1
                }
                triggerWrongAnimation()

            }

        case .highLow:
            if let first = previousCards.first, case .highLow(let hl) = guess {
                let f = first.rank.order, d = drawn.rank.order
                let correct = hl == .higher ? d > f : d < f
                if correct {
                    previousCards.append(drawn)
                    currentPhase = .insideOutside
                } else {
                    if isStrikesMode {
                        strikes += 1
                    }
                    triggerWrongAnimation()

                }
            }

        case .insideOutside:
            if previousCards.count >= 2, case .insideOutside(let io) = guess {
                let v1 = previousCards[0].rank.order
                let v2 = previousCards[1].rank.order
                let low = min(v1, v2), high = max(v1, v2)
                let d = drawn.rank.order
                let correct = io == .inside ? (d > low && d < high) : (d < low || d > high)
                if correct {
                    previousCards.append(drawn)
                    currentPhase = .suit
                } else {
                    if isStrikesMode {
                        strikes += 1
                    }
                    triggerWrongAnimation()

                }
            }

        case .suit:
            if case .suit(let s) = guess {
                if drawn.suit == s {
                    didWin = true
                } else {
                    if isStrikesMode {
                        strikes += 1
                    }
                    triggerWrongAnimation()

                }
            }
        }
    }

    private func triggerWrongAnimation() {
        isShaking = true
        withAnimation(.linear(duration: 0.5)) {
            shakeTrigger += 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            checkGameOver()
            resetToColor()
            isShaking = false
            shakeTrigger = 0
        }
    }

    private func resetToColor() {
        currentPhase = .color
        previousCards.removeAll()
        currentCard = nil
    }
    private var isStrikesMode: Bool {
        if case .strikes = gameMode { return true }
        return false
    }


    private func checkGameOver() {
        if strikes >= strikesLimit {
            gameOver = true
        }
    }
}

// MARK: - Card View
struct CardView: View {
    let card: Card
    var body: some View {
        Image(card.imageName)
            .resizable().aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 120)
            .shadow(radius: 4)
    }
}

// MARK: - Prompt View
struct PhasePromptView: View {
    let phase: GuessPhase
    let onGuess: (Guess) -> Void
    var body: some View {
        switch phase {
        case .color:
            HStack(spacing: 20) {
                Button("Red") { onGuess(.color(.red)) }.buttonStyle(.borderedProminent)
                Button("Black") { onGuess(.color(.black)) }.buttonStyle(.borderedProminent)
            }
        case .highLow:
            HStack(spacing: 20) {
                Button("Higher") { onGuess(.highLow(.higher)) }.buttonStyle(.borderedProminent)
                Button("Lower") { onGuess(.highLow(.lower)) }.buttonStyle(.borderedProminent)
            }
        case .insideOutside:
            HStack(spacing: 20) {
                Button("Inside") { onGuess(.insideOutside(.inside)) }.buttonStyle(.borderedProminent)
                Button("Outside") { onGuess(.insideOutside(.outside)) }.buttonStyle(.borderedProminent)
            }
        case .suit:
            LazyVGrid(columns: [GridItem(), GridItem()], spacing: 16) {
                ForEach(Suit.allCases) { suit in
                    Button(suit.displayName) { onGuess(.suit(suit)) }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

// MARK: - Models
enum Suit: String, CaseIterable, Identifiable {
    case hearts = "H", diamonds = "D", clubs = "C", spades = "S"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .hearts: return "Hearts"
        case .diamonds: return "Diamonds"
        case .clubs: return "Clubs"
        case .spades: return "Spades"
        }
    }
}

enum Rank: String, CaseIterable {
    case ace = "A", two = "2", three = "3", four = "4", five = "5",
         six = "6", seven = "7", eight = "8", nine = "9", ten = "T",
         jack = "J", queen = "Q", king = "K"
}

enum CardColor { case red, black }

enum GuessPhase {
    case color, highLow, insideOutside, suit
    var prompt: String {
        switch self {
        case .color: return "Red or Black?"
        case .highLow: return "Higher or Lower?"
        case .insideOutside: return "Inside or Outside?"
        case .suit: return "Which Suit?"
        }
    }
    var next: GuessPhase? {
        switch self {
        case .color: return .highLow
        case .highLow: return .insideOutside
        case .insideOutside: return .suit
        case .suit: return nil
        }
    }
}

enum HighLow { case higher, lower }

enum InsideOutside { case inside, outside }

enum Guess {
    case color(CardColor)
    case highLow(HighLow)
    case insideOutside(InsideOutside)
    case suit(Suit)
}

struct Card: Identifiable {
    let id = UUID()
    let suit: Suit
    let rank: Rank
    var imageName: String { "\(rank.rawValue)\(suit.rawValue)" }
}

extension Rank {
    var order: Int {
        switch self {
        case .ace: return 14
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        case .seven: return 7
        case .eight: return 8
        case .nine: return 9
        case .ten: return 10
        case .jack: return 11
        case .queen: return 12
        case .king: return 13
        }
    }
}

struct Deck {
    static let standard: [Card] = Suit.allCases.flatMap { s in
        Rank.allCases.map { r in Card(suit: s, rank: r) }
    }
}
