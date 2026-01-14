//
//  Match.swift
//  PadelScore Watch App
//
//  Match model with sets and games
//

import Foundation

struct Match: Codable, Identifiable {
    let id: UUID
    let startDate: Date
    var endDate: Date?
    var sets: [Set]
    var currentSetIndex: Int
    var currentGame: Game
    var isCompleted: Bool
    var winner: Int? // 1 or 2, nil if not completed
    var team1Name: String
    var team2Name: String
    
    init(id: UUID = UUID(), startDate: Date = Date(), endDate: Date? = nil, sets: [Set] = [Set()], currentSetIndex: Int = 0, currentGame: Game = Game(), isCompleted: Bool = false, winner: Int? = nil, team1Name: String = "Team 1", team2Name: String = "Team 2") {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.sets = sets
        self.currentSetIndex = currentSetIndex
        self.currentGame = currentGame
        self.isCompleted = isCompleted
        self.winner = winner
        self.team1Name = team1Name
        self.team2Name = team2Name
    }
    
    var currentSet: Set {
        get {
            guard currentSetIndex < sets.count else {
                return Set()
            }
            return sets[currentSetIndex]
        }
        set {
            guard currentSetIndex < sets.count else { return }
            sets[currentSetIndex] = newValue
        }
    }
    
    mutating func updateCurrentSet(_ update: (inout Set) -> Void) {
        guard currentSetIndex < sets.count else { return }
        update(&sets[currentSetIndex])
    }
    
    var team1Sets: Int {
        sets.filter { $0.winner == 1 }.count
    }
    
    var team2Sets: Int {
        sets.filter { $0.winner == 2 }.count
    }
    
    var duration: TimeInterval? {
        guard let endDate = endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "In progress" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var finalScore: String {
        guard isCompleted else { return "In progress" }
        return "\(team1Sets) - \(team2Sets)"
    }
}

