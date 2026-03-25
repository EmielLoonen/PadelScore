//
//  SettingsView.swift
//  PadelScore Watch App
//
//  Configuration settings view
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var gameSettings: GameSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Golden point", isOn: Binding(
                        get: { gameSettings.scoringMode == .goldenPoint },
                        set: { newValue in
                            gameSettings.scoringMode = newValue ? .goldenPoint : .advantage
                        }
                    ))
                }
                
                Section("Court Side") {
                    Picker("Team 1 Side", selection: $gameSettings.team1Side) {
                        Text("Left").tag("L")
                        Text("Right").tag("R")
                    }
                }

                Section("Scoreboard") {
                    Toggle("Enable Scoreboard", isOn: $gameSettings.scoreboardEnabled)

                    TextField("Scoreboard IP Address", text: $gameSettings.scoreboardIP)
                }

                Section("Developer") {
                    Toggle("Use Test Server", isOn: $gameSettings.useTestServer)
                    if gameSettings.useTestServer {
                        Text(MatchResultService.testURL)
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(gameSettings: GameSettings())
}
