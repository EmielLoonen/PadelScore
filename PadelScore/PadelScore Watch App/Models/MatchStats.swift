//
//  MatchStats.swift
//  PadelScore Watch App
//
//  Computes stats from a match's point log
//

import Foundation

struct MatchStats {

    // MARK: - Team Stats

    struct TeamStats {
        var pointsWon: Int = 0
        var gamesWon: Int = 0
        var setsWon: Int = 0
        // Serve
        var pointsWhileServing: Int = 0
        var pointsWonServing: Int = 0
        // Return
        var pointsWhileReceiving: Int = 0
        var pointsWonReceiving: Int = 0
        // Break points
        var breakPointOpportunities: Int = 0
        var breakPointsConverted: Int = 0
        // Streaks
        var longestWinStreak: Int = 0
        // Clutch
        var clutchPointsWon: Int = 0   // deuce + advantage + tiebreak points

        var serveWinPct: Double? {
            pointsWhileServing > 0 ? Double(pointsWonServing) / Double(pointsWhileServing) : nil
        }
        var returnWinPct: Double? {
            pointsWhileReceiving > 0 ? Double(pointsWonReceiving) / Double(pointsWhileReceiving) : nil
        }
        var breakConversionPct: Double? {
            breakPointOpportunities > 0 ? Double(breakPointsConverted) / Double(breakPointOpportunities) : nil
        }
    }

    // MARK: - Player Stats

    struct PlayerStats {
        let code: String
        let name: String
        let team: Int
        var pointsWon: Int = 0
        var totalTeamPoints: Int = 0       // all points played (for contribution %)
        var pointsAsServer: Int = 0        // won when THIS player was serving
        var totalAsServer: Int = 0         // total points where this player served
        var pointsOnServingTeam: Int = 0   // won when player's team served (any server)
        var totalOnServingTeam: Int = 0
        var pointsOnReceivingTeam: Int = 0 // won when player's team received
        var totalOnReceivingTeam: Int = 0
        var gameWinningPoints: Int = 0
        var setWinningPoints: Int = 0
        var clutchPoints: Int = 0
        var pointsBySet: [Int: Int] = [:]  // setNumber -> points won

        var contributionPct: Double? {
            totalTeamPoints > 0 ? Double(pointsWon) / Double(totalTeamPoints) : nil
        }
        var serverWinPct: Double? {
            totalAsServer > 0 ? Double(pointsAsServer) / Double(totalAsServer) : nil
        }
        var onServeWinPct: Double? {
            totalOnServingTeam > 0 ? Double(pointsOnServingTeam) / Double(totalOnServingTeam) : nil
        }
        var onReturnWinPct: Double? {
            totalOnReceivingTeam > 0 ? Double(pointsOnReceivingTeam) / Double(totalOnReceivingTeam) : nil
        }
    }

    // MARK: - Properties

    let team1: TeamStats
    let team2: TeamStats
    let players: [String: PlayerStats]  // keyed by playerCode
    let hasData: Bool

    // MARK: - Init

    init(match: Match, usesGoldenPoint: Bool = false) {
        let log = match.pointLog
        hasData = !log.isEmpty

        var t1 = TeamStats()
        var t2 = TeamStats()

        // Games and sets from match data
        t1.gamesWon = match.sets.reduce(0) { $0 + $1.team1Games }
        t2.gamesWon = match.sets.reduce(0) { $0 + $1.team2Games }
        t1.setsWon  = match.team1Sets
        t2.setsWon  = match.team2Sets

        // Per-player accumulators
        var ps: [String: PlayerStats] = [
            "A": PlayerStats(code: "A", name: match.team1Player1.isEmpty ? "Player A" : match.team1Player1, team: 1),
            "B": PlayerStats(code: "B", name: match.team1Player2.isEmpty ? "Player B" : match.team1Player2, team: 1),
            "C": PlayerStats(code: "C", name: match.team2Player1.isEmpty ? "Player C" : match.team2Player1, team: 2),
            "D": PlayerStats(code: "D", name: match.team2Player2.isEmpty ? "Player D" : match.team2Player2, team: 2),
        ]

        // Streak tracking
        var currentStreak1 = 0
        var currentStreak2 = 0

        for record in log {
            let winner = record.team
            let servingTeam = record.servingTeam

            // --- Team point counts ---
            if winner == 1 { t1.pointsWon += 1 } else { t2.pointsWon += 1 }

            // --- Serve/Return ---
            if let st = servingTeam {
                if st == 1 {
                    t1.pointsWhileServing  += 1
                    t2.pointsWhileReceiving += 1
                    if winner == 1 { t1.pointsWonServing   += 1 }
                    else           { t2.pointsWonReceiving += 1 }
                } else {
                    t2.pointsWhileServing  += 1
                    t1.pointsWhileReceiving += 1
                    if winner == 2 { t2.pointsWonServing   += 1 }
                    else           { t1.pointsWonReceiving += 1 }
                }
            }

            // --- Break points ---
            if Self.isBreakPointOpportunity(record) {
                let receivingTeam = (servingTeam == 1) ? 2 : 1
                if receivingTeam == 1 { t1.breakPointOpportunities += 1 }
                else                  { t2.breakPointOpportunities += 1 }
                if winner == receivingTeam {
                    if receivingTeam == 1 { t1.breakPointsConverted += 1 }
                    else                  { t2.breakPointsConverted += 1 }
                }
            }

            // --- Winning streaks ---
            if winner == 1 {
                currentStreak1 += 1; currentStreak2 = 0
                t1.longestWinStreak = max(t1.longestWinStreak, currentStreak1)
            } else {
                currentStreak2 += 1; currentStreak1 = 0
                t2.longestWinStreak = max(t2.longestWinStreak, currentStreak2)
            }

            // --- Clutch (deuce/advantage/tiebreak) ---
            if Self.isClutchPoint(record) {
                if winner == 1 { t1.clutchPointsWon += 1 } else { t2.clutchPointsWon += 1 }
            }

            // --- Player stats ---
            let gameWinner = Self.isGameWinningPoint(record, usesGoldenPoint: usesGoldenPoint)
            let setWinner  = gameWinner && Self.isSetWinningGame(record)
            let clutch     = Self.isClutchPoint(record)

            for code in ["A", "B", "C", "D"] {
                guard var p = ps[code] else { continue }
                let playerTeam = p.team

                // Total team points (for contribution %)
                p.totalTeamPoints += 1

                // This player was serving
                if record.servingPlayer == code {
                    p.totalAsServer += 1
                    if winner == playerTeam { p.pointsAsServer += 1 }
                }

                // Player's team serving
                if let st = servingTeam {
                    if st == playerTeam {
                        p.totalOnServingTeam += 1
                        if winner == playerTeam { p.pointsOnServingTeam += 1 }
                    } else {
                        p.totalOnReceivingTeam += 1
                        if winner == playerTeam { p.pointsOnReceivingTeam += 1 }
                    }
                }

                // Points won by this player
                if record.playerCode == code {
                    p.pointsWon += 1
                    p.pointsBySet[record.setNumber, default: 0] += 1
                    if gameWinner { p.gameWinningPoints += 1 }
                    if setWinner  { p.setWinningPoints  += 1 }
                    if clutch     { p.clutchPoints      += 1 }
                }

                ps[code] = p
            }
        }

        team1   = t1
        team2   = t2
        players = ps
    }

    // MARK: - Helpers

    private static func isBreakPointOpportunity(_ record: PointRecord) -> Bool {
        guard !record.isTiebreak, let servingTeam = record.servingTeam else { return false }
        let receivingTeam = servingTeam == 1 ? 2 : 1
        guard let t1 = record.gameTeam1PointsBefore.flatMap({ Point(rawValue: $0) }),
              let t2 = record.gameTeam2PointsBefore.flatMap({ Point(rawValue: $0) }) else { return false }
        if receivingTeam == 1 {
            return t1 == .advantage || (t1 == .forty && t2 != .advantage)
        } else {
            return t2 == .advantage || (t2 == .forty && t1 != .advantage)
        }
    }

    private static func isGameWinningPoint(_ record: PointRecord, usesGoldenPoint: Bool) -> Bool {
        if record.isTiebreak {
            guard let t1 = record.tiebreakTeam1Before, let t2 = record.tiebreakTeam2Before else { return false }
            if record.team == 1 { return t1 >= 6 && t1 >= t2 + 1 }
            else                { return t2 >= 6 && t2 >= t1 + 1 }
        }
        guard let t1 = record.gameTeam1PointsBefore.flatMap({ Point(rawValue: $0) }),
              let t2 = record.gameTeam2PointsBefore.flatMap({ Point(rawValue: $0) }) else { return false }
        if record.team == 1 {
            return t1 == .advantage
                || (t1 == .forty && t2 != .forty && t2 != .advantage)
                || (t1 == .forty && t2 == .forty && usesGoldenPoint)
        } else {
            return t2 == .advantage
                || (t2 == .forty && t1 != .forty && t1 != .advantage)
                || (t1 == .forty && t2 == .forty && usesGoldenPoint)
        }
    }

    private static func isSetWinningGame(_ record: PointRecord) -> Bool {
        let t1 = record.setTeam1GamesBefore
        let t2 = record.setTeam2GamesBefore
        if record.team == 1 {
            let new = t1 + 1
            return new >= 6 && (new - t2 >= 2 || new == 7)
        } else {
            let new = t2 + 1
            return new >= 6 && (new - t1 >= 2 || new == 7)
        }
    }

    private static func isClutchPoint(_ record: PointRecord) -> Bool {
        if record.isTiebreak { return true }
        guard let t1 = record.gameTeam1PointsBefore.flatMap({ Point(rawValue: $0) }),
              let t2 = record.gameTeam2PointsBefore.flatMap({ Point(rawValue: $0) }) else { return false }
        return (t1 == .forty && t2 == .forty) || t1 == .advantage || t2 == .advantage
    }

    // MARK: - Convenience

    func teamStats(for team: Int) -> TeamStats { team == 1 ? team1 : team2 }

    var team1Players: [PlayerStats] { [players["A"], players["B"]].compactMap { $0 } }
    var team2Players: [PlayerStats] { [players["C"], players["D"]].compactMap { $0 } }
}
