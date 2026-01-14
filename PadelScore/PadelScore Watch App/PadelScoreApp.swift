//
//  PadelScoreApp.swift
//  PadelScore Watch App
//
//  Created for Padel Score Tracker
//

import SwiftUI

@main
struct PadelScoreApp: App {
    @StateObject private var scoreManager = ScoreManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scoreManager)
        }
    }
}

