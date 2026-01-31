//
//  PadelScoreApp.swift
//  PadelScore Watch App
//
//  Created for Padel Score Tracker
//

import SwiftUI

@main
struct PadelScoreApp: App {
    @StateObject private var gameSettings = GameSettings()
    @StateObject private var scoreManager: ScoreManager
    
    init() {
        let settings = GameSettings()
        _gameSettings = StateObject(wrappedValue: settings)
        _scoreManager = StateObject(wrappedValue: ScoreManager(gameSettings: settings))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scoreManager)
                .environmentObject(gameSettings)
        }
    }
}

