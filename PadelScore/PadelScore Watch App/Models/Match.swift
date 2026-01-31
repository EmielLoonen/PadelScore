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
    var servingTeam: Int? // 1 or 2, nil if not set
    var servingPlayer: String? // A, B, C, or D
    
    init(id: UUID = UUID(), startDate: Date = Date(), endDate: Date? = nil, sets: [Set] = [Set()], currentSetIndex: Int = 0, currentGame: Game = Game(), isCompleted: Bool = false, winner: Int? = nil, team1Name: String = "Team 1", team2Name: String = "Team 2", servingTeam: Int? = 1, servingPlayer: String? = "A") {
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
        self.servingTeam = servingTeam
        self.servingPlayer = servingPlayer
    }
    
    mutating func rotateServe() {
        // Rotate serve: A (Team 1) -> C (Team 2) -> B (Team 1) -> D (Team 2) -> A...
        guard let currentPlayer = servingPlayer else {
            servingPlayer = "A"
            servingTeam = 1
            return
        }
        
        switch currentPlayer {
        case "A":
            // Team 1 Player A -> Team 2 Player C
            servingPlayer = "C"
            servingTeam = 2
        case "C":
            // Team 2 Player C -> Team 1 Player B
            servingPlayer = "B"
            servingTeam = 1
        case "B":
            // Team 1 Player B -> Team 2 Player D
            servingPlayer = "D"
            servingTeam = 2
        case "D":
            // Team 2 Player D -> Team 1 Player A
            servingPlayer = "A"
            servingTeam = 1
        default:
            servingPlayer = "A"
            servingTeam = 1
        }
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

