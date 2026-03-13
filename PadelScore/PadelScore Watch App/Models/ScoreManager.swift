//
//  ScoreManager.swift
//  PadelScore Watch App
//
//  Manages scoring logic and match state
//

import Foundation
import WatchKit
import Combine

class ScoreManager: ObservableObject {
    @Published var currentMatch: Match
    @Published var matchHistory: [Match] = []
    @Published var pendingServeSelection = false
    @Published var submittedMatchIds: Set<UUID> = []

    private let historyKey = "PadelScoreMatchHistory"
    private let submittedKey = "PadelScoreSubmittedMatches"
    private var undoStack: [Match] = []
    var gameSettings: GameSettings
    private let scoreboardService = ScoreboardService()
    private var cancellables = Swift.Set<AnyCancellable>()

    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
        self.currentMatch = Match(
            team1Player1: gameSettings.team1Player1,
            team1Player2: gameSettings.team1Player2,
            team2Player1: gameSettings.team2Player1,
            team2Player2: gameSettings.team2Player2,
            team1Side: gameSettings.team1Side
        )
        loadHistory()
        loadSubmittedIds()

        // Keep current match side in sync when changed via Settings
        gameSettings.$team1Side
            .dropFirst()
            .sink { [weak self] newSide in
                self?.currentMatch.team1Side = newSide
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Score Increment
    
    func incrementPoint(for team: Int) {
        guard !currentMatch.isCompleted else { return }
        
        // Save current state for undo
        saveStateForUndo()
        
        let haptic = WKInterfaceDevice.current()
        
        // Handle tiebreak
        if currentMatch.currentSet.isTiebreak {
            currentMatch.currentSet.incrementTiebreakPoint(for: team)
            haptic.play(.click)
            
            if currentMatch.currentSet.isCompleted {
                handleSetCompletion()
            }
            
            // Send to scoreboard
            sendScoreToScoreboard()
            return
        }
        
        // Handle regular game
        let useGoldenPoint = gameSettings.scoringMode == .goldenPoint
        if currentMatch.currentGame.incrementPoint(for: team, useGoldenPoint: useGoldenPoint) {
            haptic.play(.click)
            
            // Check if game is completed
            if currentMatch.currentGame.isCompleted {
                handleGameCompletion()
            }
            
            // Send to scoreboard
            sendScoreToScoreboard()
        }
    }
    
    // MARK: - Undo
    
    private func saveStateForUndo() {
        // Create a deep copy of the current match state
        if let encoded = try? JSONEncoder().encode(currentMatch),
           let decoded = try? JSONDecoder().decode(Match.self, from: encoded) {
            undoStack.append(decoded)
            // Limit undo stack to prevent memory issues
            if undoStack.count > 50 {
                undoStack.removeFirst()
            }
        }
    }
    
    func undo() {
        guard !undoStack.isEmpty else { return }
        
        // Store current set score to check if it changes
        let currentSetScore = (currentMatch.currentSet.team1Games, currentMatch.currentSet.team2Games)
        
        // Restore previous state
        let previousMatch = undoStack.removeLast()
        
        // If match was completed, we need to handle undoing completion
        if currentMatch.isCompleted && !previousMatch.isCompleted {
            // Match was completed, undo it
            currentMatch.isCompleted = false
            currentMatch.winner = nil
            currentMatch.endDate = nil
            // Remove from history if it was saved
            if !matchHistory.isEmpty && matchHistory[0].id == currentMatch.id {
                matchHistory.removeFirst()
            }
        }
        
        // Restore the match state
        currentMatch = previousMatch
        
        // Check if set score changed
        let previousSetScore = (currentMatch.currentSet.team1Games, currentMatch.currentSet.team2Games)
        let setScoreChanged = currentSetScore.0 != previousSetScore.0 || currentSetScore.1 != previousSetScore.1
        
        // Play haptic feedback
        let haptic = WKInterfaceDevice.current()
        haptic.play(.click)
        
        // Send to scoreboard
        sendScoreToScoreboard()
        
        // If set score changed, send it to scoreboard
        if setScoreChanged {
            sendSetScoreToScoreboard()
        }
    }
    
    func canUndo() -> Bool {
        return !undoStack.isEmpty
    }
    
    private func handleGameCompletion() {
        guard let gameWinner = currentMatch.currentGame.winner else { return }
        
        // Add game to current set
        currentMatch.currentSet.addGame(winner: gameWinner)
        
        // Send set score to scoreboard (after game is added to set)
        sendSetScoreToScoreboard()
        
        // Rotate serve after each game
        currentMatch.rotateServe()

        // After the first game, ask which player from the now-serving team will serve
        let totalGames = currentMatch.sets.reduce(0) { $0 + $1.team1Games + $1.team2Games }
        if totalGames == 1 {
            pendingServeSelection = true
        }

        // If we just entered a tiebreak (6-6), assign the serving player from match state
        if currentMatch.currentSet.isTiebreak && currentMatch.currentSet.tiebreakServingPlayer == nil {
            currentMatch.currentSet.tiebreakServingPlayer = currentMatch.servingPlayer
        }

        // Check if set is completed
        if currentMatch.currentSet.isCompleted {
            handleSetCompletion()
        } else {
            // Start new game
            currentMatch.currentGame = Game()
        }
    }
    
    func changeServer() {
        currentMatch.rotateServe()
    }

    func selectServer(_ playerCode: String) {
        currentMatch.servingPlayer = playerCode
        currentMatch.servingTeam = (playerCode == "A" || playerCode == "B") ? 1 : 2
    }
    
    private func handleSetCompletion() {
        guard let setWinner = currentMatch.currentSet.winner else { return }
        
        // Mark set as completed
        currentMatch.currentSet.isCompleted = true
        currentMatch.currentSet.winner = setWinner
        
        // Start new set (matches can continue indefinitely)
        currentMatch.currentSetIndex += 1
        if currentMatch.currentSetIndex >= currentMatch.sets.count {
            currentMatch.sets.append(Set())
        }
        currentMatch.currentGame = Game()
        
        // Alternate serving team at start of each set
        // Set 1 (index 0) = Team 1, Set 2 (index 1) = Team 2, Set 3 (index 2) = Team 1, etc.
        let nextSetIndex = currentMatch.currentSetIndex
        currentMatch.servingTeam = (nextSetIndex % 2 == 0) ? 1 : 2
        // Set serving player based on team: Team 1 starts with A, Team 2 starts with C
        currentMatch.servingPlayer = (currentMatch.servingTeam == 1) ? "A" : "C"
    }
    
    // MARK: - Match Control
    
    func stopMatch() {
        guard !currentMatch.isCompleted else { return }
        
        // Determine winner based on sets won
        let team1Sets = currentMatch.sets.filter { $0.winner == 1 }.count
        let team2Sets = currentMatch.sets.filter { $0.winner == 2 }.count
        
        if team1Sets > team2Sets {
            currentMatch.winner = 1
        } else if team2Sets > team1Sets {
            currentMatch.winner = 2
        }
        // If equal sets, winner remains nil (tie)
        
        currentMatch.isCompleted = true
        currentMatch.endDate = Date()
        
        // Save to history
        saveMatchToHistory()
        
        // Play success haptic
        let haptic = WKInterfaceDevice.current()
        haptic.play(.success)
    }
    
    // MARK: - Match Management
    
    func startNewMatch(servingTeam: Int = 1, servingPlayer: String = "A", playerA: Player? = nil, playerB: Player? = nil, playerC: Player? = nil, playerD: Player? = nil, watchCode: String? = nil) {
        // Save current match if it has any progress
        if currentMatch.currentSet.team1Games > 0 || currentMatch.currentSet.team2Games > 0 ||
           currentMatch.currentGame.team1Points != .love || currentMatch.currentGame.team2Points != .love {
            saveMatchToHistory()
        }

        var match = matchWithCurrentPlayers()
        match.servingTeam = servingTeam
        match.servingPlayer = servingPlayer
        match.watchCode = watchCode
        match.team1Player1Id = playerA?.id
        match.team1Player1Type = playerA?.type
        match.team1Player2Id = playerB?.id
        match.team1Player2Type = playerB?.type
        match.team2Player1Id = playerC?.id
        match.team2Player1Type = playerC?.type
        match.team2Player2Id = playerD?.id
        match.team2Player2Type = playerD?.type
        currentMatch = match
        undoStack.removeAll()
    }

    func resetCurrentMatch() {
        currentMatch = matchWithCurrentPlayers()
        undoStack.removeAll()
    }

    private func matchWithCurrentPlayers() -> Match {
        Match(
            team1Player1: gameSettings.team1Player1,
            team1Player2: gameSettings.team1Player2,
            team2Player1: gameSettings.team2Player1,
            team2Player2: gameSettings.team2Player2,
            team1Side: gameSettings.team1Side
        )
    }
    
    // MARK: - History Management
    
    private func saveMatchToHistory() {
        guard currentMatch.isCompleted else { return }
        
        matchHistory.insert(currentMatch, at: 0)
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(matchHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([Match].self, from: data) {
            matchHistory = decoded
        }
    }
    
    func deleteMatch(at index: Int) {
        guard index < matchHistory.count else { return }
        matchHistory.remove(at: index)
        saveHistory()
    }
    
    func clearHistory() {
        matchHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    func markMatchSubmitted(id: UUID) {
        submittedMatchIds.insert(id)
        if let encoded = try? JSONEncoder().encode(Array(submittedMatchIds).map { $0.uuidString }) {
            UserDefaults.standard.set(encoded, forKey: submittedKey)
        }
    }

    private func loadSubmittedIds() {
        if let data = UserDefaults.standard.data(forKey: submittedKey),
           let strings = try? JSONDecoder().decode([String].self, from: data) {
            submittedMatchIds = Set(strings.compactMap { UUID(uuidString: $0) })
        }
    }
    
    // MARK: - Scoreboard Integration
    
    private func sendScoreToScoreboard() {
        // Check if scoreboard is enabled
        guard gameSettings.scoreboardEnabled else { return }
        
        // Validate IP address
        guard !gameSettings.scoreboardIP.isEmpty else { return }
        
        // Format the current game score
        let scoreTextArray = scoreboardService.formatGameScore(match: currentMatch)
        
        // Determine which side the serving team is on
        let servingTeam: Int?
        if currentMatch.currentSet.isTiebreak {
            servingTeam = currentMatch.currentSet.getTiebreakServingTeam()
        } else {
            servingTeam = currentMatch.servingTeam
        }
        let team1IsLeft = currentMatch.currentTeam1Side == "L"
        let servingIsOnLeft: Bool? = servingTeam.map { team in
            team == 1 ? team1IsLeft : !team1IsLeft
        }

        // Send to scoreboard
        scoreboardService.sendScore(textArray: scoreTextArray, ipAddress: gameSettings.scoreboardIP, servingIsOnLeft: servingIsOnLeft)
    }
    
    private func sendSetScoreToScoreboard() {
        // Check if scoreboard is enabled
        guard gameSettings.scoreboardEnabled else { return }
        
        // Validate IP address
        guard !gameSettings.scoreboardIP.isEmpty else { return }
        
        // Format the current set score
        let setScoreTextArray = scoreboardService.formatSetScore(match: currentMatch)
        
        // Send to scoreboard
        scoreboardService.sendSetScore(textArray: setScoreTextArray, ipAddress: gameSettings.scoreboardIP)
    }
}

