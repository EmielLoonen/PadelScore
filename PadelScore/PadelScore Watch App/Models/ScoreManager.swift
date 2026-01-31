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
    
    private let historyKey = "PadelScoreMatchHistory"
    private var undoStack: [Match] = []
    var gameSettings: GameSettings
    
    init(gameSettings: GameSettings) {
        // Initialize with a new match
        self.currentMatch = Match()
        self.gameSettings = gameSettings
        loadHistory()
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
        
        // Play haptic feedback
        let haptic = WKInterfaceDevice.current()
        haptic.play(.click)
    }
    
    func canUndo() -> Bool {
        return !undoStack.isEmpty
    }
    
    private func handleGameCompletion() {
        guard let gameWinner = currentMatch.currentGame.winner else { return }
        
        // Add game to current set
        currentMatch.currentSet.addGame(winner: gameWinner)
        
        // Rotate serve after each game
        currentMatch.rotateServe()
        
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
    
    func startNewMatch() {
        // Save current match if it has any progress
        if currentMatch.currentSet.team1Games > 0 || currentMatch.currentSet.team2Games > 0 || 
           currentMatch.currentGame.team1Points != .love || currentMatch.currentGame.team2Points != .love {
            saveMatchToHistory()
        }
        
        currentMatch = Match()
        undoStack.removeAll()
    }
    
    func resetCurrentMatch() {
        currentMatch = Match()
        undoStack.removeAll()
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
}

