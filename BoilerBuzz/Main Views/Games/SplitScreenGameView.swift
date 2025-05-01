//
//  SplitScreenGameView.swift
//  BoilerBuzz
//
//  Created by user272845 on 4/8/25.
//

struct Tile: Identifiable {
    let id = UUID()
    var yPosition: CGFloat
    var lane: Int
}

import SwiftUI
import AVFoundation


struct SplitScreenGameView: View {
    @Environment(\.dismiss) var dismiss

    @State private var player1Tiles: [Tile] = []
    @State private var player2Tiles: [Tile] = []

    @State private var speed: CGFloat = 2.5
    @State private var tileSpawnInterval: Double = 1.2
    @State private var tileSpawnTimer = Timer.publish(every: 1.2, on: .main, in: .common).autoconnect()
    @State private var complexityTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    @State private var showPlayer1Hit = false
    @State private var showPlayer2Hit = false

    @State private var score1 = 0
    @State private var score2 = 0
    @State private var misses1 = 0
    @State private var misses2 = 0
    @State private var gameOver = false
    @State private var loser: Int? = nil

    @State private var audioPlayer: AVAudioPlayer?

    let numLanes = 4
    let tileWidth: CGFloat = 60
    let tileHeight: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            let centerY = geometry.size.height / 2
            let laneSpacing = geometry.size.width / CGFloat(numLanes)

            ZStack {
                Color.black.ignoresSafeArea()

                // Player 1 Tiles (top half)
                ForEach(player1Tiles) { tile in
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: tileWidth, height: tileHeight)
                        .position(
                            x: laneX(lane: tile.lane, spacing: laneSpacing),
                            y: tile.yPosition
                        )
                }

                // Player 2 Tiles (bottom half)
                ForEach(player2Tiles) { tile in
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: tileWidth, height: tileHeight)
                        .position(
                            x: laneX(lane: tile.lane, spacing: laneSpacing),
                            y: tile.yPosition
                        )
                }

                if showPlayer1Hit {
                    Text("HIT!")
                        .font(.title)
                        .foregroundColor(.green)
                        .position(x: geometry.size.width / 2, y: 80)
                }

                if showPlayer2Hit {
                    Text("HIT!")
                        .font(.title)
                        .foregroundColor(.green)
                        .position(x: geometry.size.width / 2, y: geometry.size.height - 80)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(height: 2)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                VStack {
                    VStack(spacing: 4) {
                        Text("Player 1: \(score1)")
                            .foregroundColor(.red)
                        Text("Misses: \(misses1)")
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .font(.title2)

                    Spacer()

                    VStack(spacing: 4) {
                        Text("Player 2: \(score2)")
                            .foregroundColor(.blue)
                        Text("Misses: \(misses2)")
                            .foregroundColor(.blue.opacity(0.7))
                    }
                    .font(.title2)
                }
                .padding()

                if gameOver {
                    VStack(spacing: 20) {
                        Text("Player \(loser ?? 0) Loses!")
                            .font(.largeTitle)
                            .foregroundColor(.white)

                        Button("Play Again") {
                            resetGame()
                        }
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)

                        Button("Back to Games") {
                            dismiss()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.8))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let tapLocation = value.location
                        let tapY = tapLocation.y

                        if tapY < geometry.size.height / 2 {
                            if let hitIndex = player1Tiles.firstIndex(where: { tile in
                                let tileCenter = CGPoint(
                                    x: laneX(lane: tile.lane, spacing: laneSpacing),
                                    y: tile.yPosition
                                )
                                return distance(from: tileCenter, to: tapLocation) < tileWidth * 1.2
                            }) {
                                player1Tiles.remove(at: hitIndex)
                                score1 += 1
                                flashHit(for: 1)
                            } else {
                                misses1 += 1    
                                checkGameOver()
                            }
                        } else {
                            if let hitIndex = player2Tiles.firstIndex(where: { tile in
                                let tileCenter = CGPoint(
                                    x: laneX(lane: tile.lane, spacing: laneSpacing),
                                    y: tile.yPosition
                                )
                                return distance(from: tileCenter, to: tapLocation) < tileWidth * 1.2
                            }) {
                                player2Tiles.remove(at: hitIndex)
                                score2 += 1
                                flashHit(for: 2)
                            } else {
                                misses2 += 1
                                checkGameOver()
                            }
                        }
                    }
            )
            .onReceive(tileSpawnTimer) { _ in
                spawnComplexTiles(in: geometry)
            }
            .onReceive(complexityTimer) { _ in
                speed += 0.1
                if tileSpawnInterval > 0.4 {
                    tileSpawnInterval -= 0.05
                    tileSpawnTimer = Timer.publish(every: tileSpawnInterval, on: .main, in: .common).autoconnect()
                }
            }
            .onReceive(Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()) { _ in
                updateTiles(in: geometry)
            }
        }
    }

    private func playLoseSound() {
        if let soundURL = Bundle.main.url(forResource: "lose", withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error)")
            }
        }
    }

    private func resetGame() {
        player1Tiles.removeAll()
        player2Tiles.removeAll()
        score1 = 0
        score2 = 0
        misses1 = 0
        misses2 = 0
        loser = nil
        gameOver = false
    }

    private func spawnComplexTiles(in geometry: GeometryProxy) {
        let shouldDouble = Bool.random()
        addTile(for: 1, in: geometry)
        addTile(for: 2, in: geometry)
        if shouldDouble {
            addTile(for: Int.random(in: 1...2), in: geometry)
        }
    }

    private func addTile(for player: Int, in geometry: GeometryProxy) {
        let centerY = geometry.size.height / 2
        let lane = Int.random(in: 0..<numLanes)
        let newTile = Tile(yPosition: centerY, lane: lane)
        if player == 1 {
            player1Tiles.append(newTile)
        } else {
            player2Tiles.append(newTile)
        }
    }

    private func updateTiles(in geometry: GeometryProxy) {
        let topBoundary: CGFloat = -tileHeight
        let bottomBoundary: CGFloat = geometry.size.height + tileHeight
        player1Tiles = player1Tiles.compactMap { tile in
            var newTile = tile
            newTile.yPosition -= speed
            if newTile.yPosition > topBoundary {
                return newTile
            } else {
                // misses1 += 1   //UNCOMMENT FOR PLAYER1
                checkGameOver()
                return nil
            }
        }
        player2Tiles = player2Tiles.compactMap { tile in
            var newTile = tile
            newTile.yPosition += speed
            if newTile.yPosition < bottomBoundary {
                return newTile
            } else {
                misses2 += 1
                checkGameOver()
                return nil
            }
        }
    }

    private func checkGameOver() {
        if misses1 >= 3 {
            gameOver = true
            loser = 1
            playLoseSound()
        } else if misses2 >= 3 {
            gameOver = true
            loser = 2
            playLoseSound()
        }
    }

    private func flashHit(for player: Int) {
        if player == 1 {
            showPlayer1Hit = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showPlayer1Hit = false
            }
        } else {
            showPlayer2Hit = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showPlayer2Hit = false
            }
        }
    }

    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        return hypot(p1.x - p2.x, p1.y - p2.y)
    }

    private func laneX(lane: Int, spacing: CGFloat) -> CGFloat {
        return spacing * CGFloat(lane) + spacing / 2
    }
}
