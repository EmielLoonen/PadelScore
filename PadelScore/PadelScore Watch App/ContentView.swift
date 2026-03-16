//
//  ContentView.swift
//  PadelScore Watch App
//
//  Main score display view
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var gameSettings: GameSettings
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var showingMatchControl = false
    @State private var showingMenu = false
    @State private var showingNewMatchSetup = false
    @State private var showingServeSelection = false
    @State private var lastTapTime: Date?
    @State private var lastTapTeam: Int?
    @State private var pendingIncrementTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 4) {
                        // Top section - compact info
                        VStack(spacing: 2) {
                            // Match status
                            if scoreManager.currentMatch.isCompleted {
                                Text("Match Complete")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }

                            // Set scores and Match scores side by side
                            HStack(spacing: 16) {
                                // Set scores (games for current set)
                                VStack(spacing: 2) {
                                    Text("Set \(scoreManager.currentMatch.currentSetIndex + 1)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 8) {
                                        Text("\(scoreManager.currentMatch.currentSet.team1Games)")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.blue)

                                        Text("-")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Text("\(scoreManager.currentMatch.currentSet.team2Games)")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                // Pipe separator
                                Text("|")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // Match score (sets won)
                                VStack(spacing: 2) {
                                    Text("Match")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 8) {
                                        Text("\(scoreManager.currentMatch.team1Sets)")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.blue)

                                        Text("-")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Text("\(scoreManager.currentMatch.team2Sets)")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            
                        }
                        .padding(.top, 4)
                        
                        Spacer()
                            .frame(height: geometry.size.height * 0.05)

                        // Player initials row with serving indicator
                        playerInitialsRow()

                        // Current game score or tiebreak (clickable buttons) - HUGE
                        if !scoreManager.currentMatch.isCompleted {
                            let leftTeam = scoreManager.currentMatch.currentTeam1Side == "L" ? 1 : 2
                            let rightTeam = leftTeam == 1 ? 2 : 1
                            if scoreManager.currentMatch.currentSet.isTiebreak {
                                if let tiebreak = scoreManager.currentMatch.currentSet.tiebreakScore {
                                    HStack(spacing: 8) {
                                        tiebreakButton(team: leftTeam, score: leftTeam == 1 ? tiebreak.team1 : tiebreak.team2, geometry: geometry)
                                        tiebreakButton(team: rightTeam, score: rightTeam == 1 ? tiebreak.team1 : tiebreak.team2, geometry: geometry)
                                    }
                                }
                            } else {
                                HStack(spacing: 8) {
                                    regularGameButton(team: leftTeam, geometry: geometry)
                                    regularGameButton(team: rightTeam, geometry: geometry)
                                }
                            }
                        } else {
                            // Match complete message
                            VStack(spacing: 8) {
                                Text("Winner: \(scoreManager.currentMatch.winner == 1 ? scoreManager.currentMatch.team1Name : scoreManager.currentMatch.team2Name)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                Button("New Match") {
                                    showingNewMatchSetup = true
                                }
                                .buttonStyle(.bordered)
                                .frame(height: geometry.size.height * 0.3)
                            }
                        }
                        
                        Spacer()
                            .frame(height: geometry.size.height * 0.2)
                        
                        // Match control button - appears when scrolling
                        if !scoreManager.currentMatch.isCompleted {
                            Button {
                                showingMatchControl = true
                            } label: {
                                HStack {
                                    Image(systemName: "stop.circle.fill")
                                    Text("Stop Match")
                                }
                                .font(.body)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal)
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationTitle("Padel Score")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingMenu = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                MatchHistoryView()
                    .environmentObject(scoreManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(gameSettings: gameSettings)
            }
            .sheet(isPresented: $showingMatchControl) {
                MatchControlView()
                    .environmentObject(scoreManager)
            }
            .sheet(isPresented: $showingMenu) {
                MenuView(
                    showingNewMatchSetup: $showingNewMatchSetup,
                    showingHistory: $showingHistory,
                    showingSettings: $showingSettings,
                    showingMenu: $showingMenu,
                    isMatchInProgress: !scoreManager.currentMatch.isCompleted
                )
            }
            .sheet(isPresented: $showingNewMatchSetup) {
                NewMatchSetupView(gameSettings: gameSettings)
                    .environmentObject(scoreManager)
            }
            .onChange(of: scoreManager.pendingServeSelection) { _, newValue in
                if newValue { showingServeSelection = true }
            }
            .sheet(isPresented: $showingServeSelection, onDismiss: {
                scoreManager.pendingServeSelection = false
            }) {
                ServeSelectionView()
                    .environmentObject(scoreManager)
                    .interactiveDismissDisabled(true)
            }
        }
    }
    
    @ViewBuilder
    private func playerInitialsRow() -> some View {
        let match = scoreManager.currentMatch
        let servingPlayer = match.currentSet.isTiebreak
            ? (match.currentSet.tiebreakServingPlayer ?? match.servingPlayer ?? "A")
            : (match.servingPlayer ?? "A")
        let team1Left = match.currentTeam1Side == "L"
        let names: [String: String] = [
            "A": match.team1Player1,
            "B": match.team1Player2,
            "C": match.team2Player1,
            "D": match.team2Player2
        ]
        let hasPlayers = names.values.contains { !$0.isEmpty }

        if hasPlayers {
            // Fixed 4-position layout — no ForEach, stable identity
            let codes: [String] = team1Left ? ["A", "B", "C", "D"] : ["C", "D", "A", "B"]
            HStack(spacing: 4) {
                playerInitialBadge(name: names[codes[0]] ?? "", playerCode: codes[0], servingPlayer: servingPlayer)
                playerInitialBadge(name: names[codes[1]] ?? "", playerCode: codes[1], servingPlayer: servingPlayer)
                Text("|").font(.caption2).foregroundColor(.secondary)
                playerInitialBadge(name: names[codes[2]] ?? "", playerCode: codes[2], servingPlayer: servingPlayer)
                playerInitialBadge(name: names[codes[3]] ?? "", playerCode: codes[3], servingPlayer: servingPlayer)
            }
        }
    }

    private func playerInitialBadge(name: String, playerCode: String, servingPlayer: String) -> some View {
        let isServing = servingPlayer == playerCode
        let teamColor: Color = (playerCode == "A" || playerCode == "B") ? .blue : .green
        return ZStack {
            Circle()
                .fill(isServing ? teamColor : teamColor.opacity(0.2))
                .frame(width: 28, height: 28)
            Text(name.isEmpty ? " " : name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isServing ? .white : teamColor)
        }
        .opacity(name.isEmpty ? 0 : 1)
    }

    private func teamInitialsLabel(for team: Int) -> String? {
        if team == 1 {
            return teamInitials(player1: scoreManager.currentMatch.team1Player1,
                                player2: scoreManager.currentMatch.team1Player2)
        } else {
            return teamInitials(player1: scoreManager.currentMatch.team2Player1,
                                player2: scoreManager.currentMatch.team2Player2)
        }
    }

    @ViewBuilder
    private func regularGameButton(team: Int, geometry: GeometryProxy) -> some View {
        let points = team == 1 ? scoreManager.currentMatch.currentGame.team1Points
                               : scoreManager.currentMatch.currentGame.team2Points
        VStack(spacing: 4) {
            Button(action: { handleButtonTap(team: team) }) {
                Text(points.displayValue)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(points == .advantage ? .green : .primary)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .tint(points == .advantage ? .green : .primary)
            .frame(height: geometry.size.height * 0.5)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func tiebreakButton(team: Int, score: Int, geometry: GeometryProxy) -> some View {
        VStack(spacing: 4) {
            Button(action: { handleButtonTap(team: team) }) {
                Text("\(score)")
                    .font(.system(size: 50, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            .frame(height: geometry.size.height * 0.5)
            .frame(maxWidth: .infinity)
        }
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }

    private func teamInitials(player1: String, player2: String) -> String? {
        let i1 = initials(player1)
        let i2 = initials(player2)
        let combined = [i1, i2].filter { !$0.isEmpty }.joined(separator: "/")
        return combined.isEmpty ? nil : combined
    }

    private func handleButtonTap(team: Int) {
        let now = Date()
        
        // Cancel any pending increment
        pendingIncrementTask?.cancel()
        pendingIncrementTask = nil
        
        // Check if this is a double tap (within 0.4 seconds and same team)
        if let lastTime = lastTapTime,
           let lastTeam = lastTapTeam,
           lastTeam == team,
           now.timeIntervalSince(lastTime) < 0.4 {
            // Double tap detected - undo the previous action (before the double tap started)
            scoreManager.undo()
            // Clear the tap tracking
            lastTapTime = nil
            lastTapTeam = nil
            return
        }
        
        // Single tap - delay increment slightly to detect potential double tap
        lastTapTime = now
        lastTapTeam = team
        
        let teamToIncrement = team
        pendingIncrementTask = Task {
            // Wait a short time to see if there's a second tap
            try? await Task.sleep(nanoseconds: 350_000_000) // 0.35 seconds
            
            // Only increment if task wasn't cancelled (no double tap detected)
            if !Task.isCancelled {
                await MainActor.run {
                    scoreManager.incrementPoint(for: teamToIncrement)
                    pendingIncrementTask = nil
                }
            }
        }
    }
}

struct ServeSelectionView: View {
    @EnvironmentObject var scoreManager: ScoreManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        let match = scoreManager.currentMatch
        let team = match.servingTeam ?? 1
        let teamColor: Color = team == 1 ? .blue : .green
        let players: [(code: String, name: String)] = team == 1
            ? [("A", match.team1Player1.isEmpty ? "Player A" : match.team1Player1),
               ("B", match.team1Player2.isEmpty ? "Player B" : match.team1Player2)]
            : [("C", match.team2Player1.isEmpty ? "Player C" : match.team2Player1),
               ("D", match.team2Player2.isEmpty ? "Player D" : match.team2Player2)]

        GeometryReader { geometry in
            VStack(spacing: 8) {
                Text("Who serves?")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ForEach(players, id: \.code) { player in
                        Button {
                            scoreManager.selectServer(player.code)
                            dismiss()
                        } label: {
                            Text(player.name)
                                .font(.system(size: 16, weight: .bold))
                                .minimumScaleFactor(0.5)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.bordered)
                        .tint(teamColor)
                        .frame(height: geometry.size.height * 0.7)
                    }
                }
            }
            .padding(.horizontal, 4)
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .navigationTitle("Serve")
    }
}

#Preview {
    let gameSettings = GameSettings()
    ContentView()
        .environmentObject(ScoreManager(gameSettings: gameSettings))
        .environmentObject(gameSettings)
}

