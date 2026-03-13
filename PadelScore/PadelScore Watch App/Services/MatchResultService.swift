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

    private struct SubmitMatchPayload: Encodable {
        let watchCode: String
        let sets: [SetPayload]

        struct SetPayload: Encodable {
            let setNumber: Int
            let scores: [PlayerScore]
        }

        struct PlayerScore: Encodable {
            let id: String
            let type: String
            let gamesWon: Int
        }
    }

    func submitMatchResult(match: Match) async throws {
        guard let watchCode = match.watchCode, !watchCode.isEmpty else {
            throw MatchResultError.noWatchCode
        }

        guard let url = URL(string: "\(baseURL)/api/matches") else {
            throw URLError(.badURL)
        }

        // Include all sets that have at least one game played, whether or not the set completed
        let playedSets = match.sets.filter { $0.team1Games > 0 || $0.team2Games > 0 }
        guard !playedSets.isEmpty else {
            throw MatchResultError.noCompletedSets
        }

        let setsPayload = playedSets.enumerated().map { index, set in
            SubmitMatchPayload.SetPayload(
                setNumber: index + 1,
                scores: [
                    SubmitMatchPayload.PlayerScore(
                        id: match.team1Player1Id ?? match.team1Player1,
                        type: match.team1Player1Type ?? "guest",
                        gamesWon: set.team1Games
                    ),
                    SubmitMatchPayload.PlayerScore(
                        id: match.team1Player2Id ?? match.team1Player2,
                        type: match.team1Player2Type ?? "guest",
                        gamesWon: set.team1Games
                    ),
                    SubmitMatchPayload.PlayerScore(
                        id: match.team2Player1Id ?? match.team2Player1,
                        type: match.team2Player1Type ?? "guest",
                        gamesWon: set.team2Games
                    ),
                    SubmitMatchPayload.PlayerScore(
                        id: match.team2Player2Id ?? match.team2Player2,
                        type: match.team2Player2Type ?? "guest",
                        gamesWon: set.team2Games
                    ),
                ]
            )
        }

        let payload = SubmitMatchPayload(watchCode: watchCode, sets: setsPayload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
