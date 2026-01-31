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

class GameSettings: ObservableObject {
    @Published var scoringMode: ScoringMode {
        didSet {
            save()
        }
    }
    
    private let settingsKey = "PadelScoreGameSettings"
    
    init() {
        // Load settings or use defaults
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(ScoringMode.self, from: data) {
            self.scoringMode = decoded
        } else {
            // Default to golden point
            self.scoringMode = .goldenPoint
            save()
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(scoringMode) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
}
