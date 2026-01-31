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
    @State private var showingNewMatchAlert = false
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
                                        
                                        Text("-")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("\(scoreManager.currentMatch.currentSet.team2Games)")
                                            .font(.system(size: 16, weight: .bold))
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
                                        
                                        Text("-")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("\(scoreManager.currentMatch.team2Sets)")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                }
                            }
                            
                        }
                        .padding(.top, 4)
                        
                        Spacer()
                            .frame(height: geometry.size.height * 0.1)
                        
                        // Current game score or tiebreak (clickable buttons) - HUGE
                        if !scoreManager.currentMatch.isCompleted {
                            if scoreManager.currentMatch.currentSet.isTiebreak {
                                if let tiebreak = scoreManager.currentMatch.currentSet.tiebreakScore {
                                    HStack(spacing: 8) {
                                        // Left button - Team 1
                                        VStack(spacing: 4) {
                                            if let tiebreakServingTeam = scoreManager.currentMatch.currentSet.getTiebreakServingTeam(),
                                               tiebreakServingTeam == 1 {
                                                Circle()
                                                    .fill(.blue)
                                                    .frame(width: 8, height: 8)
                                            } else {
                                                Circle()
                                                    .fill(.clear)
                                                    .frame(width: 8, height: 8)
                                            }
                                            
                                            Button(action: {
                                                handleButtonTap(team: 1)
                                            }) {
                                                Text("\(tiebreak.team1)")
                                                    .font(.system(size: 50, weight: .bold))
                                                    .frame(maxWidth: .infinity)
                                                    .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(.blue)
                                            .frame(height: geometry.size.height * 0.5)
                                            .frame(maxWidth: .infinity)
                                        }
                                        
                                        // Right button - Team 2
                                        VStack(spacing: 4) {
                                            if let tiebreakServingTeam = scoreManager.currentMatch.currentSet.getTiebreakServingTeam(),
                                               tiebreakServingTeam == 2 {
                                                Circle()
                                                    .fill(.blue)
                                                    .frame(width: 8, height: 8)
                                            } else {
                                                Circle()
                                                    .fill(.clear)
                                                    .frame(width: 8, height: 8)
                                            }
                                            
                                            Button(action: {
                                                handleButtonTap(team: 2)
                                            }) {
                                                Text("\(tiebreak.team2)")
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
                                }
                            } else {
                                HStack(spacing: 8) {
                                    // Left button - Team 1
                                    VStack(spacing: 4) {
                                        if scoreManager.currentMatch.servingTeam == 1 {
                                            Circle()
                                                .fill(.blue)
                                                .frame(width: 8, height: 8)
                                        } else {
                                            Circle()
                                                .fill(.clear)
                                                .frame(width: 8, height: 8)
                                        }
                                        
                                        Button(action: {
                                            handleButtonTap(team: 1)
                                        }) {
                                            Text(scoreManager.currentMatch.currentGame.team1Points.displayValue)
                                                .font(.system(size: 50, weight: .bold))
                                                .foregroundColor(scoreManager.currentMatch.currentGame.team1Points == .advantage ? .green : .primary)
                                                .frame(maxWidth: .infinity)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(scoreManager.currentMatch.currentGame.team1Points == .advantage ? .green : .primary)
                                        .frame(height: geometry.size.height * 0.5)
                                        .frame(maxWidth: .infinity)
                                    }
                                    
                                    // Right button - Team 2
                                    VStack(spacing: 4) {
                                        if scoreManager.currentMatch.servingTeam == 2 {
                                            Circle()
                                                .fill(.blue)
                                                .frame(width: 8, height: 8)
                                        } else {
                                            Circle()
                                                .fill(.clear)
                                                .frame(width: 8, height: 8)
                                        }
                                        
                                        Button(action: {
                                            handleButtonTap(team: 2)
                                        }) {
                                            Text(scoreManager.currentMatch.currentGame.team2Points.displayValue)
                                                .font(.system(size: 50, weight: .bold))
                                                .foregroundColor(scoreManager.currentMatch.currentGame.team2Points == .advantage ? .green : .primary)
                                                .frame(maxWidth: .infinity)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(scoreManager.currentMatch.currentGame.team2Points == .advantage ? .green : .primary)
                                        .frame(height: geometry.size.height * 0.5)
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                        } else {
                            // Match complete message
                            VStack(spacing: 8) {
                                Text("Winner: \(scoreManager.currentMatch.winner == 1 ? scoreManager.currentMatch.team1Name : scoreManager.currentMatch.team2Name)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                Button("New Match") {
                                    showingNewMatchAlert = true
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
                    showingNewMatchAlert: $showingNewMatchAlert,
                    showingHistory: $showingHistory,
                    showingSettings: $showingSettings,
                    showingMenu: $showingMenu,
                    isMatchInProgress: !scoreManager.currentMatch.isCompleted
                )
            }
            .alert("Start New Match?", isPresented: $showingNewMatchAlert) {
                Button("Cancel", role: .cancel) { }
                Button("New Match") {
                    scoreManager.startNewMatch()
                }
            } message: {
                Text("This will save the current match and start a new one.")
            }
        }
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

#Preview {
    let gameSettings = GameSettings()
    ContentView()
        .environmentObject(ScoreManager(gameSettings: gameSettings))
        .environmentObject(gameSettings)
}

