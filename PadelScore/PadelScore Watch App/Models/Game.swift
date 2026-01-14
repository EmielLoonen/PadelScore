//
//  Game.swift
//  PadelScore Watch App
//
//  Game scoring model for tennis-style scoring
//

import Foundation

enum Point: String, Codable {
    case love = "0"
    case fifteen = "15"
    case thirty = "30"
    case forty = "40"
    case advantage = "AD"
    case game = "Game"
    
    var displayValue: String {
        return self.rawValue
    }
    
    func nextPoint() -> Point? {
        switch self {
        case .love:
            return .fifteen
        case .fifteen:
            return .thirty
        case .thirty:
            return .forty
        case .forty:
            return .game
        case .advantage:
            return .game
        case .game:
            return nil
        }
    }
}

struct Game: Codable, Identifiable {
    let id: UUID
    var team1Points: Point
    var team2Points: Point
    var isCompleted: Bool
    var winner: Int? // 1 or 2, nil if not completed
    
    init(id: UUID = UUID(), team1Points: Point = .love, team2Points: Point = .love, isCompleted: Bool = false, winner: Int? = nil) {
        self.id = id
        self.team1Points = team1Points
        self.team2Points = team2Points
        self.isCompleted = isCompleted
        self.winner = winner
    }
    
    mutating func incrementPoint(for team: Int) -> Bool {
        guard !isCompleted else { return false }
        
        if team == 1 {
            return incrementTeam1Point()
        } else {
            return incrementTeam2Point()
        }
    }
    
    private mutating func incrementTeam1Point() -> Bool {
        // Handle deuce (40-40)
        if team1Points == .forty && team2Points == .forty {
            team1Points = .advantage
            team2Points = .forty
            return true
        }
        
        // Handle advantage scenarios
        if team1Points == .advantage {
            team1Points = .game
            isCompleted = true
            winner = 1
            return true
        }
        
        if team2Points == .advantage {
            team2Points = .forty
            team1Points = .forty
            return true
        }
        
        // Normal progression
        if let nextPoint = team1Points.nextPoint() {
            team1Points = nextPoint
            if team1Points == .game {
                isCompleted = true
                winner = 1
            }
            return true
        }
        
        return false
    }
    
    private mutating func incrementTeam2Point() -> Bool {
        // Handle deuce (40-40)
        if team1Points == .forty && team2Points == .forty {
            team2Points = .advantage
            team1Points = .forty
            return true
        }
        
        // Handle advantage scenarios
        if team2Points == .advantage {
            team2Points = .game
            isCompleted = true
            winner = 2
            return true
        }
        
        if team1Points == .advantage {
            team1Points = .forty
            team2Points = .forty
            return true
        }
        
        // Normal progression
        if let nextPoint = team2Points.nextPoint() {
            team2Points = nextPoint
            if team2Points == .game {
                isCompleted = true
                winner = 2
            }
            return true
        }
        
        return false
    }
}

