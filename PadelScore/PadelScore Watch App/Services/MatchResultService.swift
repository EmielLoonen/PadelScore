//
//  MatchResultService.swift
//  PadelScore Watch App
//
//  Service for submitting completed match results to the Court Coordinator API
//

import Foundation

enum MatchResultError: LocalizedError {
    case noWatchCode
    case noCompletedSets

    var errorDescription: String? {
        switch self {
        case .noWatchCode:
            return "No court code linked to this match"
        case .noCompletedSets:
            return "No games played to submit"
        }
    }
}

class MatchResultService {
    private let baseURL = "https://padel-coordinator-api.onrender.com"

    // MARK: - Payload types

    private struct SubmitMatchPayload: Encodable {
        let watchCode: String
        let matchId: String
        let startDate: String
        let endDate: String?
        let durationSeconds: Int?
        let winner: Int?
        let teams: [TeamPayload]
        let sets: [SetPayload]
        let stats: StatsPayload
        let pointLog: [PointLogEntry]
    }

    private struct TeamPayload: Encodable {
        let team: Int
        let name: String
        let players: [PlayerInfoPayload]
    }

    private struct PlayerInfoPayload: Encodable {
        let code: String      // A, B, C, or D
        let id: String
        let type: String
        let name: String
    }

    private struct SetPayload: Encodable {
        let setNumber: Int
        let team1Games: Int
        let team2Games: Int
        let winner: Int?
        let wasTiebreak: Bool
        let tiebreakScore: TiebreakPayload?
    }

    private struct TiebreakPayload: Encodable {
        let team1: Int
        let team2: Int
    }

    private struct StatsPayload: Encodable {
        let team1: TeamStatsPayload
        let team2: TeamStatsPayload
        let players: [String: PlayerStatsPayload]
    }

    private struct TeamStatsPayload: Encodable {
        let pointsWon: Int
        let gamesWon: Int
        let setsWon: Int
        let serveWinPct: Double?
        let returnWinPct: Double?
        let breakPointOpportunities: Int
        let breakPointsConverted: Int
        let breakConversionPct: Double?
        let longestWinStreak: Int
        let clutchPointsWon: Int
    }

    private struct PlayerStatsPayload: Encodable {
        let code: String
        let name: String
        let team: Int
        let pointsWon: Int
        let contributionPct: Double?
        let onServeWinPct: Double?
        let onReturnWinPct: Double?
        let serverWinPct: Double?
        let gameWinningPoints: Int
        let setWinningPoints: Int
        let clutchPoints: Int
        let pointsBySet: [String: Int]  // "1", "2", ... (JSON keys must be strings)
    }

    private struct PointLogEntry: Encodable {
        let playerCode: String?
        let team: Int
        let timestamp: String
        let servingPlayer: String?
        let servingTeam: Int?
        let isTiebreak: Bool
        let gameTeam1PointsBefore: String?
        let gameTeam2PointsBefore: String?
        let tiebreakTeam1Before: Int?
        let tiebreakTeam2Before: Int?
        let setTeam1GamesBefore: Int
        let setTeam2GamesBefore: Int
        let setNumber: Int
        let matchTeam1SetsBefore: Int
        let matchTeam2SetsBefore: Int
    }

    // MARK: - Submit

    func submitMatchResult(match: Match) async throws {
        guard let watchCode = match.watchCode, !watchCode.isEmpty else {
            throw MatchResultError.noWatchCode
        }

        guard let url = URL(string: "\(baseURL)/api/matches") else {
            throw URLError(.badURL)
        }

        let playedSets = match.sets.filter { $0.team1Games > 0 || $0.team2Games > 0 }
        guard !playedSets.isEmpty else {
            throw MatchResultError.noCompletedSets
        }

        let payload = buildPayload(match: match, watchCode: watchCode, playedSets: playedSets)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        request.httpBody = try encoder.encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Payload builder

    private func buildPayload(match: Match, watchCode: String, playedSets: [Set]) -> SubmitMatchPayload {
        let iso = ISO8601DateFormatter()
        let stats = MatchStats(match: match)

        let teams = [
            TeamPayload(
                team: 1,
                name: match.team1Name,
                players: [
                    PlayerInfoPayload(code: "A", id: match.team1Player1Id ?? match.team1Player1, type: match.team1Player1Type ?? "user", name: match.team1Player1),
                    PlayerInfoPayload(code: "B", id: match.team1Player2Id ?? match.team1Player2, type: match.team1Player2Type ?? "user", name: match.team1Player2),
                ]
            ),
            TeamPayload(
                team: 2,
                name: match.team2Name,
                players: [
                    PlayerInfoPayload(code: "C", id: match.team2Player1Id ?? match.team2Player1, type: match.team2Player1Type ?? "user", name: match.team2Player1),
                    PlayerInfoPayload(code: "D", id: match.team2Player2Id ?? match.team2Player2, type: match.team2Player2Type ?? "user", name: match.team2Player2),
                ]
            ),
        ]

        let setsPayload = playedSets.enumerated().map { index, set in
            SetPayload(
                setNumber: index + 1,
                team1Games: set.team1Games,
                team2Games: set.team2Games,
                winner: set.winner,
                wasTiebreak: set.isTiebreak,
                tiebreakScore: set.tiebreakScore.map { TiebreakPayload(team1: $0.team1, team2: $0.team2) }
            )
        }

        let statsPayload = StatsPayload(
            team1: teamStatsPayload(stats.team1),
            team2: teamStatsPayload(stats.team2),
            players: Dictionary(uniqueKeysWithValues: stats.players.map { code, p in
                (code, playerStatsPayload(p))
            })
        )

        let pointLog = match.pointLog.map { record in
            PointLogEntry(
                playerCode: record.playerCode,
                team: record.team,
                timestamp: iso.string(from: record.timestamp),
                servingPlayer: record.servingPlayer,
                servingTeam: record.servingTeam,
                isTiebreak: record.isTiebreak,
                gameTeam1PointsBefore: record.gameTeam1PointsBefore,
                gameTeam2PointsBefore: record.gameTeam2PointsBefore,
                tiebreakTeam1Before: record.tiebreakTeam1Before,
                tiebreakTeam2Before: record.tiebreakTeam2Before,
                setTeam1GamesBefore: record.setTeam1GamesBefore,
                setTeam2GamesBefore: record.setTeam2GamesBefore,
                setNumber: record.setNumber,
                matchTeam1SetsBefore: record.matchTeam1SetsBefore,
                matchTeam2SetsBefore: record.matchTeam2SetsBefore
            )
        }

        return SubmitMatchPayload(
            watchCode: watchCode,
            matchId: match.id.uuidString,
            startDate: iso.string(from: match.startDate),
            endDate: match.endDate.map { iso.string(from: $0) },
            durationSeconds: match.duration.map { Int($0) },
            winner: match.winner,
            teams: teams,
            sets: setsPayload,
            stats: statsPayload,
            pointLog: pointLog
        )
    }

    private func teamStatsPayload(_ t: MatchStats.TeamStats) -> TeamStatsPayload {
        TeamStatsPayload(
            pointsWon: t.pointsWon,
            gamesWon: t.gamesWon,
            setsWon: t.setsWon,
            serveWinPct: t.serveWinPct,
            returnWinPct: t.returnWinPct,
            breakPointOpportunities: t.breakPointOpportunities,
            breakPointsConverted: t.breakPointsConverted,
            breakConversionPct: t.breakConversionPct,
            longestWinStreak: t.longestWinStreak,
            clutchPointsWon: t.clutchPointsWon
        )
    }

    private func playerStatsPayload(_ p: MatchStats.PlayerStats) -> PlayerStatsPayload {
        PlayerStatsPayload(
            code: p.code,
            name: p.name,
            team: p.team,
            pointsWon: p.pointsWon,
            contributionPct: p.contributionPct,
            onServeWinPct: p.onServeWinPct,
            onReturnWinPct: p.onReturnWinPct,
            serverWinPct: p.serverWinPct,
            gameWinningPoints: p.gameWinningPoints,
            setWinningPoints: p.setWinningPoints,
            clutchPoints: p.clutchPoints,
            pointsBySet: Dictionary(uniqueKeysWithValues: p.pointsBySet.map { ("\($0.key + 1)", $0.value) })
        )
    }
}
