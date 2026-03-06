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
    @State private var step = 1
    @State private var servingTeam = 1
    @State private var servingPlayer = "A"

    var body: some View {
        NavigationStack {
            if step == 1 {
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
                        Button("Next") { step = 2 }
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .navigationTitle("New Match")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") { dismiss() }
                    }
                }
            } else {
                List {
                    Section("Who serves first?") {
                        ForEach([
                            (code: "A", name: player1.isEmpty ? "Player A" : player1),
                            (code: "B", name: player2.isEmpty ? "Player B" : player2),
                            (code: "C", name: player3.isEmpty ? "Player C" : player3),
                            (code: "D", name: player4.isEmpty ? "Player D" : player4)
                        ], id: \.code) { player in
                            Button {
                                servingPlayer = player.code
                                servingTeam = (player.code == "A" || player.code == "B") ? 1 : 2
                            } label: {
                                HStack {
                                    Text(player.name)
                                    Spacer()
                                    if servingPlayer == player.code {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    Section {
                        Button("Start Match") {
                            gameSettings.team1Player1 = player1
                            gameSettings.team1Player2 = player2
                            gameSettings.team2Player1 = player3
                            gameSettings.team2Player2 = player4
                            scoreManager.startNewMatch(servingTeam: servingTeam, servingPlayer: servingPlayer)
                            dismiss()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .navigationTitle("Who Serves?")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") { step = 1 }
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
