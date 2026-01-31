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
    var tiebreakServingPlayer: String? // A, B, C, or D - current player serving in tiebreak
    var tiebreakServeCount: Int // Number of serves by current player in this turn (0-2)
    var tiebreakTotalPoints: Int // Total points played in tiebreak (for side change tracking)
    
    init(id: UUID = UUID(), team1Games: Int = 0, team2Games: Int = 0, isCompleted: Bool = false, winner: Int? = nil, isTiebreak: Bool = false, tiebreakScore: TiebreakScore? = nil, tiebreakServingPlayer: String? = nil, tiebreakServeCount: Int = 0, tiebreakTotalPoints: Int = 0) {
        self.id = id
        self.team1Games = team1Games
        self.team2Games = team2Games
        self.isCompleted = isCompleted
        self.winner = winner
        self.isTiebreak = isTiebreak
        self.tiebreakScore = tiebreakScore
        self.tiebreakServingPlayer = tiebreakServingPlayer
        self.tiebreakServeCount = tiebreakServeCount
        self.tiebreakTotalPoints = tiebreakTotalPoints
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
            tiebreakServingPlayer = "A" // Start with Player A
            tiebreakServeCount = 0
            tiebreakTotalPoints = 0
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
        tiebreakTotalPoints += 1
        
        // Rotate tiebreak serve
        rotateTiebreakServe()
        
        checkSetCompletion()
    }
    
    mutating func rotateTiebreakServe() {
        guard isTiebreak else { return }
        
        tiebreakServeCount += 1
        
        // Determine how many serves this player should have
        // Pattern: A(1) -> C(2) -> B(2) -> D(2) -> A(2) -> C(2) -> B(2) -> D(2)...
        let servesForThisPlayer: Int
        if tiebreakServingPlayer == "A" && tiebreakTotalPoints == 1 {
            servesForThisPlayer = 1 // A serves once on first point
        } else {
            servesForThisPlayer = 2 // All other serves are 2 points
        }
        
        // If player has completed their serves, move to next player
        if tiebreakServeCount >= servesForThisPlayer {
            tiebreakServeCount = 0
            
            // Rotate to next player: A -> C -> B -> D -> A...
            // This alternates teams: Team 1 -> Team 2 -> Team 1 -> Team 2...
            switch tiebreakServingPlayer {
            case "A":
                // Team 1 Player A -> Team 2 Player C
                tiebreakServingPlayer = "C"
            case "C":
                // Team 2 Player C -> Team 1 Player B
                tiebreakServingPlayer = "B"
            case "B":
                // Team 1 Player B -> Team 2 Player D
                tiebreakServingPlayer = "D"
            case "D":
                // Team 2 Player D -> Team 1 Player A
                tiebreakServingPlayer = "A"
            default:
                tiebreakServingPlayer = "A"
            }
        }
    }
    
    func getTiebreakServingTeam() -> Int? {
        guard let player = tiebreakServingPlayer else { return nil }
        // A and B are Team 1, C and D are Team 2
        return (player == "A" || player == "B") ? 1 : 2
    }
}

