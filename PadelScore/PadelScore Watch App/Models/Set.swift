//
//  Set.swift
//  PadelScore Watch App
//
//  Set scoring model
//

import Foundation

struct TiebreakScore: Codable {
    var team1: Int
    var team2: Int
}

struct Set: Codable, Identifiable {
    let id: UUID
    var team1Games: Int
    var team2Games: Int
    var isCompleted: Bool
    var winner: Int? // 1 or 2, nil if not completed
    var isTiebreak: Bool
    var tiebreakScore: TiebreakScore?
    
    init(id: UUID = UUID(), team1Games: Int = 0, team2Games: Int = 0, isCompleted: Bool = false, winner: Int? = nil, isTiebreak: Bool = false, tiebreakScore: TiebreakScore? = nil) {
        self.id = id
        self.team1Games = team1Games
        self.team2Games = team2Games
        self.isCompleted = isCompleted
        self.winner = winner
        self.isTiebreak = isTiebreak
        self.tiebreakScore = tiebreakScore
    }
    
    mutating func addGame(winner: Int) {
        guard !isCompleted else { return }
        
        if winner == 1 {
            team1Games += 1
        } else {
            team2Games += 1
        }
        
        checkSetCompletion()
    }
    
    mutating func checkSetCompletion() {
        // Check if tiebreak is needed (6-6)
        if team1Games == 6 && team2Games == 6 && !isTiebreak {
            isTiebreak = true
            tiebreakScore = TiebreakScore(team1: 0, team2: 0)
            return
        }
        
        // Check for set win (6 games, win by 2)
        if team1Games >= 6 && team1Games - team2Games >= 2 {
            isCompleted = true
            self.winner = 1
        } else if team2Games >= 6 && team2Games - team1Games >= 2 {
            isCompleted = true
            self.winner = 2
        }
        
        // Check for tiebreak win (first to 7, win by 2)
        if let tiebreak = tiebreakScore {
            if tiebreak.team1 >= 7 && tiebreak.team1 - tiebreak.team2 >= 2 {
                isCompleted = true
                self.winner = 1
            } else if tiebreak.team2 >= 7 && tiebreak.team2 - tiebreak.team1 >= 2 {
                isCompleted = true
                self.winner = 2
            }
        }
    }
    
    mutating func incrementTiebreakPoint(for team: Int) {
        guard isTiebreak, var tiebreak = tiebreakScore, !isCompleted else { return }
        
        if team == 1 {
            tiebreak.team1 += 1
        } else {
            tiebreak.team2 += 1
        }
        
        tiebreakScore = tiebreak
        checkSetCompletion()
    }
}

