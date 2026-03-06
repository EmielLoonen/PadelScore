//
//  NewMatchSetupView.swift
//  PadelScore Watch App
//
//  Player setup before starting a new match
//

import SwiftUI

struct NewMatchSetupView: View {
    @ObservedObject var gameSettings: GameSettings
    @EnvironmentObject var scoreManager: ScoreManager
    @Environment(\.dismiss) var dismiss

    @State private var player1 = ""
    @State private var player2 = ""
    @State private var player3 = ""
    @State private var player4 = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Team 1") {
                    TextField("Player A", text: $player1)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Player B", text: $player2)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                Section("Team 2") {
                    TextField("Player C", text: $player3)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Player D", text: $player4)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                Section {
                    Button("Start Match") {
                        gameSettings.team1Player1 = player1
                        gameSettings.team1Player2 = player2
                        gameSettings.team2Player1 = player3
                        gameSettings.team2Player2 = player4
                        scoreManager.startNewMatch()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("New Match")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let gameSettings = GameSettings()
    NewMatchSetupView(gameSettings: gameSettings)
        .environmentObject(ScoreManager(gameSettings: gameSettings))
}
