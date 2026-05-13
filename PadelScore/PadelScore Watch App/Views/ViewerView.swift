//
//  ViewerView.swift
//  PadelScore Watch App
//
//  Read-only live score display for secondary watches
//

import SwiftUI

struct ViewerView: View {
    @EnvironmentObject var gameSettings: GameSettings
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = LiveScoreService()

    @State private var courtCode = ""
    @State private var isViewing = false

    var body: some View {
        if isViewing {
            liveView
        } else {
            setupView
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        NavigationStack {
            List {
                Section("Court Code") {
                    TextField("Code", text: $courtCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                Section {
                    Button("Start Viewing") {
                        isViewing = true
                        service.startPolling(courtCode: courtCode, useTestServer: gameSettings.useTestServer)
                    }
                    .disabled(courtCode.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Join as Viewer")
            .onAppear { courtCode = gameSettings.lastWatchCode }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Live score

    private var liveView: some View {
        NavigationStack {
            GeometryReader { geometry in
                Group {
                    if let state = service.scoreState {
                        scoreBody(state: state, geometry: geometry)
                    } else {
                        waitingBody
                    }
                }
            }
            .navigationTitle(courtCode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onDisappear { service.stopPolling() }
    }

    private var waitingBody: some View {
        VStack(spacing: 8) {
            switch service.connectionStatus {
            case .notFound:
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red)
                Text("Court not found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .error:
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                Text("Connection error")
                    .font(.caption)
                    .foregroundColor(.secondary)
            default:
                ProgressView()
                Text("Waiting for score…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Score layout

    @ViewBuilder
    private func scoreBody(state: LiveScoreState, geometry: GeometryProxy) -> some View {
        let team1Color = Color(red: 0.2, green: 0.55, blue: 1.0)
        let team2Color = Color(red: 0.1, green: 0.95, blue: 0.45)
        let team1IsLeft = state.team1Side == "L"

        VStack(spacing: 6) {
            // Player badges
            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    playerBadge(name: state.players.A, code: "A", serving: state.servingPlayer, color: team1Color)
                    playerBadge(name: state.players.B, code: "B", serving: state.servingPlayer, color: team1Color)
                }
                .frame(maxWidth: .infinity)
                Text("|").font(.caption2).foregroundColor(.secondary)
                HStack(spacing: 4) {
                    playerBadge(name: state.players.C, code: "C", serving: state.servingPlayer, color: team2Color)
                    playerBadge(name: state.players.D, code: "D", serving: state.servingPlayer, color: team2Color)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 4)

            // Game score
            let (leftGame, rightGame) = gameScores(state: state, team1IsLeft: team1IsLeft)
            HStack(spacing: 8) {
                Text(leftGame)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(team1IsLeft ? team1Color : team2Color)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("-")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                Text(rightGame)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(team1IsLeft ? team2Color : team1Color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Set + match score
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("Set \(state.sets.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text("\(state.currentSet.team1Games)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(team1Color)
                        Text("-").font(.caption).foregroundColor(.secondary)
                        Text("\(state.currentSet.team2Games)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(team2Color)
                    }
                }
                Text("|").font(.caption).foregroundColor(.secondary)
                VStack(spacing: 2) {
                    Text("Match")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text("\(state.matchScore.team1Sets)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(team1Color)
                        Text("-").font(.caption).foregroundColor(.secondary)
                        Text("\(state.matchScore.team2Sets)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(team2Color)
                    }
                }
            }

            if state.isCompleted {
                Text("Match completed")
                    .font(.caption2)
                    .foregroundColor(Color(red: 0.1, green: 0.95, blue: 0.45))
            }
        }
        .padding(.horizontal)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func gameScores(state: LiveScoreState, team1IsLeft: Bool) -> (String, String) {
        if state.currentSet.isTiebreak, let tb = state.tiebreak {
            let left  = team1IsLeft ? "\(tb.team1)" : "\(tb.team2)"
            let right = team1IsLeft ? "\(tb.team2)" : "\(tb.team1)"
            return (left, right)
        }
        let left  = team1IsLeft ? state.game.team1Points : state.game.team2Points
        let right = team1IsLeft ? state.game.team2Points : state.game.team1Points
        return (left, right)
    }

    private func playerBadge(name: String, code: String, serving: String?, color: Color) -> some View {
        let isServing = serving == code
        return ZStack {
            Circle()
                .fill(isServing ? color : color.opacity(0.2))
                .frame(width: 26, height: 26)
            Text(name.isEmpty ? "?" : name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(isServing ? .white : color)
        }
    }
}

#Preview {
    let gs = GameSettings()
    ViewerView()
        .environmentObject(gs)
}
