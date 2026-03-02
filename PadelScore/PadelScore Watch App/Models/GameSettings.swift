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
    
    init(scoringMode: ScoringMode = .goldenPoint, scoreboardEnabled: Bool = false, scoreboardIP: String = "") {
        self.scoringMode = scoringMode
        self.scoreboardEnabled = scoreboardEnabled
        self.scoreboardIP = scoreboardIP
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
        didSet {
            save()
        }
    }
    
    private let settingsKey = "PadelScoreGameSettings"
    
    init() {
        // Load settings or use defaults
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(GameSettingsData.self, from: data) {
            self.scoringMode = decoded.scoringMode
            self.scoreboardEnabled = decoded.scoreboardEnabled
            self.scoreboardIP = decoded.scoreboardIP
        } else {
            // Defaults
            self.scoringMode = .goldenPoint
            self.scoreboardEnabled = false
            self.scoreboardIP = ""
            save()
        }
    }
    
    private func save() {
        let settingsData = GameSettingsData(
            scoringMode: scoringMode,
            scoreboardEnabled: scoreboardEnabled,
            scoreboardIP: scoreboardIP
        )
        if let encoded = try? JSONEncoder().encode(settingsData) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
}
