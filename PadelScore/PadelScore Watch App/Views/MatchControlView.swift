//
//  MatchControlView.swift
//  PadelScore Watch App
//
//  Match control and management view
//

import SwiftUI

struct MatchControlView: View {
    @EnvironmentObject var scoreManager: ScoreManager
    @Environment(\.dismiss) var dismiss
    @State private var showingStopAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(role: .destructive) {
                        showingStopAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop Match")
                        }
                    }
                }
            }
            .navigationTitle("Match Control")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Stop Match?", isPresented: $showingStopAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Stop", role: .destructive) {
                    scoreManager.stopMatch()
                    dismiss()
                }
            } message: {
                Text("This will end the current match and save it to history.")
            }
        }
    }
}

#Preview {
    let gameSettings = GameSettings()
    MatchControlView()
        .environmentObject(ScoreManager(gameSettings: gameSettings))
        .environmentObject(gameSettings)
}
