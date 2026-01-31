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
