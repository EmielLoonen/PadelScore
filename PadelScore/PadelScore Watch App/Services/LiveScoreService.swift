//
//  LiveScoreService.swift
//  PadelScore Watch App
//
//  Polls the backend for live score updates (secondary watch / viewer mode)
//

import Foundation
import Combine

struct LiveScoreState: Codable {
    struct Players: Codable {
        let A: String
        let B: String
        let C: String
        let D: String
    }

    struct GameInfo: Codable {
        let team1Points: String
        let team2Points: String
        let isTiebreak: Bool
    }

    struct TiebreakInfo: Codable {
        let team1: Int
        let team2: Int
    }

    struct SetInfo: Codable {
        let team1Games: Int
        let team2Games: Int
        let isTiebreak: Bool
        let winner: Int?
    }

    struct MatchScore: Codable {
        let team1Sets: Int
        let team2Sets: Int
    }

    let courtCode: String
    let players: Players
    let servingPlayer: String?
    let servingTeam: Int?
    let game: GameInfo
    let tiebreak: TiebreakInfo?
    let currentSet: SetInfo
    let sets: [SetInfo]
    let matchScore: MatchScore
    let team1Side: String   // effective current side, already accounts for set switching
    let isCompleted: Bool
    let winner: Int?
    let updatedAt: String?
}

class LiveScoreService: ObservableObject {
    static let productionURL = "https://padel-coordinator-api.onrender.com"
    static let testURL       = "http://localhost:3000"

    enum ConnectionStatus { case waiting, connected, notFound, error }

    @Published var scoreState: LiveScoreState?
    @Published var connectionStatus: ConnectionStatus = .waiting

    private var pollingTask: Task<Void, Never>?

    func startPolling(courtCode: String, useTestServer: Bool = false) {
        stopPolling()
        let base = useTestServer ? Self.testURL : Self.productionURL
        pollingTask = Task {
            while !Task.isCancelled {
                await fetchScore(courtCode: courtCode, baseURL: base)
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func fetchScore(courtCode: String, baseURL: String) async {
        guard let url = URL(string: "\(baseURL)/courts/\(courtCode)/score") else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else { return }

            if http.statusCode == 404 {
                await MainActor.run { self.connectionStatus = .notFound }
                return
            }
            guard (200...299).contains(http.statusCode) else {
                await MainActor.run { self.connectionStatus = .error }
                return
            }

            let decoded = try JSONDecoder().decode(LiveScoreState.self, from: data)
            await MainActor.run {
                self.scoreState = decoded
                self.connectionStatus = .connected
            }
        } catch {
            await MainActor.run { self.connectionStatus = .error }
        }
    }
}
