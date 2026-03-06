//
//  GameSettings.swift
//  PadelScore Watch App
//
//  Game configuration settings
//

import Foundation
import Combine

enum ScoringMode: String, Codable {
    case goldenPoint = "goldenPoint"
    case advantage = "advantage"
    
    var displayName: String {
        switch self {
        case .goldenPoint:
            return "golden point"
        case .advantage:
            return "Advantage"
        }
    }
    
    var description: String {
        switch self {
        case .goldenPoint:
            return "golden point"
        case .advantage:
            return "At 40-40, play advantage"
        }
    }
}

struct GameSettingsData: Codable {
    var scoringMode: ScoringMode
    var scoreboardEnabled: Bool
    var scoreboardIP: String
    var team1Player1: String
    var team1Player2: String
    var team2Player1: String
    var team2Player2: String

    init(scoringMode: ScoringMode = .goldenPoint, scoreboardEnabled: Bool = false, scoreboardIP: String = "", team1Player1: String = "", team1Player2: String = "", team2Player1: String = "", team2Player2: String = "") {
        self.scoringMode = scoringMode
        self.scoreboardEnabled = scoreboardEnabled
        self.scoreboardIP = scoreboardIP
        self.team1Player1 = team1Player1
        self.team1Player2 = team1Player2
        self.team2Player1 = team2Player1
        self.team2Player2 = team2Player2
    }
}

class GameSettings: ObservableObject {
    @Published var scoringMode: ScoringMode {
        didSet {
            save()
        }
    }
    
    @Published var scoreboardEnabled: Bool {
        didSet {
            save()
        }
    }
    
    @Published var scoreboardIP: String {
        didSet { save() }
    }

    @Published var team1Player1: String {
        didSet { save() }
    }

    @Published var team1Player2: String {
        didSet { save() }
    }

    @Published var team2Player1: String {
        didSet { save() }
    }

    @Published var team2Player2: String {
        didSet { save() }
    }

    private let settingsKey = "PadelScoreGameSettings"

    init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(GameSettingsData.self, from: data) {
            self.scoringMode = decoded.scoringMode
            self.scoreboardEnabled = decoded.scoreboardEnabled
            self.scoreboardIP = decoded.scoreboardIP
            self.team1Player1 = decoded.team1Player1
            self.team1Player2 = decoded.team1Player2
            self.team2Player1 = decoded.team2Player1
            self.team2Player2 = decoded.team2Player2
        } else {
            self.scoringMode = .goldenPoint
            self.scoreboardEnabled = false
            self.scoreboardIP = ""
            self.team1Player1 = ""
            self.team1Player2 = ""
            self.team2Player1 = ""
            self.team2Player2 = ""
            save()
        }
    }

    private func save() {
        let settingsData = GameSettingsData(
            scoringMode: scoringMode,
            scoreboardEnabled: scoreboardEnabled,
            scoreboardIP: scoreboardIP,
            team1Player1: team1Player1,
            team1Player2: team1Player2,
            team2Player1: team2Player1,
            team2Player2: team2Player2
        )
        if let encoded = try? JSONEncoder().encode(settingsData) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
}
