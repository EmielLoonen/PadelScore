//
//  Match.swift
//  PadelScore Watch App
//
//  Match model with sets and games
//

import Foundation

struct PointRecord: Codable {
    let playerCode: String?       // A, B, C, or D; nil if not tracked
    let team: Int                 // 1 or 2
    let timestamp: Date

    // Context at time of scoring (optional for backwards compat)
    let servingPlayer: String?    // who was serving during this point
    let servingTeam: Int?         // which team was serving
    let isTiebreak: Bool          // was this a tiebreak point
    let gameTeam1PointsBefore: String?  // Point.rawValue before the point
    let gameTeam2PointsBefore: String?
    let tiebreakTeam1Before: Int? // tiebreak score before (if tiebreak)
    let tiebreakTeam2Before: Int?
    let setTeam1GamesBefore: Int  // games in current set before the point
    let setTeam2GamesBefore: Int
    let setNumber: Int            // 0-indexed set number
    let matchTeam1SetsBefore: Int // sets won before this point
    let matchTeam2SetsBefore: Int

    init(
        playerCode: String?,
        team: Int,
        timestamp: Date = Date(),
        servingPlayer: String? = nil,
        servingTeam: Int? = nil,
        isTiebreak: Bool = false,
        gameTeam1PointsBefore: String? = nil,
        gameTeam2PointsBefore: String? = nil,
        tiebreakTeam1Before: Int? = nil,
        tiebreakTeam2Before: Int? = nil,
        setTeam1GamesBefore: Int = 0,
        setTeam2GamesBefore: Int = 0,
        setNumber: Int = 0,
        matchTeam1SetsBefore: Int = 0,
        matchTeam2SetsBefore: Int = 0
    ) {
        self.playerCode = playerCode
        self.team = team
        self.timestamp = timestamp
        self.servingPlayer = servingPlayer
        self.servingTeam = servingTeam
        self.isTiebreak = isTiebreak
        self.gameTeam1PointsBefore = gameTeam1PointsBefore
        self.gameTeam2PointsBefore = gameTeam2PointsBefore
        self.tiebreakTeam1Before = tiebreakTeam1Before
        self.tiebreakTeam2Before = tiebreakTeam2Before
        self.setTeam1GamesBefore = setTeam1GamesBefore
        self.setTeam2GamesBefore = setTeam2GamesBefore
        self.setNumber = setNumber
        self.matchTeam1SetsBefore = matchTeam1SetsBefore
        self.matchTeam2SetsBefore = matchTeam2SetsBefore
    }
}

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
    var canonicalServingPlayer: String? // Tracks rotation position independently of user overrides
    var team1Player1: String
    var team1Player2: String
    var team2Player1: String
    var team2Player2: String
    var team1Side: String // "L" or "R"; team 2 gets the opposite
    // Player IDs and types for API submission (optional for backwards compatibility)
    var watchCode: String?
    var team1Player1Id: String?
    var team1Player1Type: String?
    var team1Player2Id: String?
    var team1Player2Type: String?
    var team2Player1Id: String?
    var team2Player1Type: String?
    var team2Player2Id: String?
    var team2Player2Type: String?
    var pointLog: [PointRecord]

    init(id: UUID = UUID(), startDate: Date = Date(), endDate: Date? = nil, sets: [Set] = [Set()], currentSetIndex: Int = 0, currentGame: Game = Game(), isCompleted: Bool = false, winner: Int? = nil, team1Name: String = "Team 1", team2Name: String = "Team 2", servingTeam: Int? = 1, servingPlayer: String? = "A", team1Player1: String = "", team1Player2: String = "", team2Player1: String = "", team2Player2: String = "", team1Side: String = "R", watchCode: String? = nil, team1Player1Id: String? = nil, team1Player1Type: String? = nil, team1Player2Id: String? = nil, team1Player2Type: String? = nil, team2Player1Id: String? = nil, team2Player1Type: String? = nil, team2Player2Id: String? = nil, team2Player2Type: String? = nil, pointLog: [PointRecord] = []) {
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
        self.team1Player1 = team1Player1
        self.team1Player2 = team1Player2
        self.team2Player1 = team2Player1
        self.team2Player2 = team2Player2
        self.team1Side = team1Side
        self.watchCode = watchCode
        self.team1Player1Id = team1Player1Id
        self.team1Player1Type = team1Player1Type
        self.team1Player2Id = team1Player2Id
        self.team1Player2Type = team1Player2Type
        self.team2Player1Id = team2Player1Id
        self.team2Player1Type = team2Player1Type
        self.team2Player2Id = team2Player2Id
        self.team2Player2Type = team2Player2Type
        self.pointLog = pointLog
    }

    // Sides switch after every set
    var currentTeam1Side: String {
        currentSetIndex % 2 == 0 ? team1Side : (team1Side == "L" ? "R" : "L")
    }
    var currentTeam2Side: String { currentTeam1Side == "L" ? "R" : "L" }
    
    mutating func rotateServe() {
        // Rotate serve: A (Team 1) -> C (Team 2) -> B (Team 1) -> D (Team 2) -> A...
        // Use canonicalServingPlayer to track rotation position independently of user overrides
        let canonical = canonicalServingPlayer ?? servingPlayer ?? "A"

        switch canonical {
        case "A":
            canonicalServingPlayer = "C"
            servingTeam = 2
        case "C":
            canonicalServingPlayer = "B"
            servingTeam = 1
        case "B":
            canonicalServingPlayer = "D"
            servingTeam = 2
        case "D":
            canonicalServingPlayer = "A"
            servingTeam = 1
        default:
            canonicalServingPlayer = "A"
            servingTeam = 1
        }
        servingPlayer = canonicalServingPlayer
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

