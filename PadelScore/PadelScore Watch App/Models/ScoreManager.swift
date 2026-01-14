//
//  ScoreManager.swift
//  PadelScore Watch App
//
//  Manages scoring logic and match state
//

import Foundation
import WatchKit

class ScoreManager: ObservableObject {
    @Published var currentMatch: Match
    @Published var matchHistory: [Match] = []
    
    private let historyKey = "PadelScoreMatchHistory"
    
    init() {
        // Initialize with a new match
        self.currentMatch = Match()
        loadHistory()
    }
    
    // MARK: - Score Increment
    
    func incrementPoint(for team: Int) {
        guard !currentMatch.isCompleted else { return }
        
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
        if currentMatch.currentGame.incrementPoint(for: team) {
            haptic.play(.click)
            
            // Check if game is completed
            if currentMatch.currentGame.isCompleted {
                handleGameCompletion()
            }
        }
    }
    
    private func handleGameCompletion() {
        guard let gameWinner = currentMatch.currentGame.winner else { return }
        
        // Add game to current set
        currentMatch.currentSet.addGame(winner: gameWinner)
        
        // Check if set is completed
        if currentMatch.currentSet.isCompleted {
            handleSetCompletion()
        } else {
            // Start new game
            currentMatch.currentGame = Game()
        }
    }
    
    private func handleSetCompletion() {
        guard let setWinner = currentMatch.currentSet.winner else { return }
        
        // Mark set as completed
        currentMatch.currentSet.isCompleted = true
        currentMatch.currentSet.winner = setWinner
        
        // Check if match is completed (best of 3 sets)
        // Count completed sets after this one is marked complete
        let team1Sets = currentMatch.sets.filter { $0.winner == 1 }.count
        let team2Sets = currentMatch.sets.filter { $0.winner == 2 }.count
        
        if team1Sets >= 2 || team2Sets >= 2 {
            // Match completed
            currentMatch.isCompleted = true
            currentMatch.winner = setWinner
            currentMatch.endDate = Date()
            
            // Save to history
            saveMatchToHistory()
            
            // Play success haptic
            let haptic = WKInterfaceDevice.current()
            haptic.play(.success)
        } else {
            // Start new set
            currentMatch.currentSetIndex += 1
            if currentMatch.currentSetIndex >= currentMatch.sets.count {
                currentMatch.sets.append(Set())
            }
            currentMatch.currentGame = Game()
        }
    }
    
    // MARK: - Match Management
    
    func startNewMatch() {
        // Save current match if it has any progress
        if currentMatch.currentSet.team1Games > 0 || currentMatch.currentSet.team2Games > 0 || 
           currentMatch.currentGame.team1Points != .love || currentMatch.currentGame.team2Points != .love {
            saveMatchToHistory()
        }
        
        currentMatch = Match()
    }
    
    func resetCurrentMatch() {
        currentMatch = Match()
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

