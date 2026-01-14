//
//  ContentView.swift
//  PadelScore Watch App
//
//  Main score display view
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var scoreManager: ScoreManager
    @State private var showingHistory = false
    @State private var showingNewMatchAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Match status
                    if scoreManager.currentMatch.isCompleted {
                        Text("Match Complete")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Set \(scoreManager.currentMatch.currentSetIndex + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Set scores
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("\(scoreManager.currentMatch.currentSet.team1Games)")
                                .font(.system(size: 32, weight: .bold))
                            Text(scoreManager.currentMatch.team1Name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("-")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 4) {
                            Text("\(scoreManager.currentMatch.currentSet.team2Games)")
                                .font(.system(size: 32, weight: .bold))
                            Text(scoreManager.currentMatch.team2Name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Current game score or tiebreak
                    if scoreManager.currentMatch.currentSet.isTiebreak {
                        if let tiebreak = scoreManager.currentMatch.currentSet.tiebreakScore {
                            VStack(spacing: 4) {
                                Text("Tiebreak")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                HStack(spacing: 12) {
                                    Text("\(tiebreak.team1)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Text("-")
                                        .foregroundColor(.secondary)
                                    Text("\(tiebreak.team2)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        VStack(spacing: 4) {
                            Text("Game")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 16) {
                                Text(scoreManager.currentMatch.currentGame.team1Points.displayValue)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(scoreManager.currentMatch.currentGame.team1Points == .advantage ? .green : .primary)
                                
                                Text("-")
                                    .foregroundColor(.secondary)
                                
                                Text(scoreManager.currentMatch.currentGame.team2Points.displayValue)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(scoreManager.currentMatch.currentGame.team2Points == .advantage ? .green : .primary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Match score (sets won)
                    if scoreManager.currentMatch.sets.count > 1 || scoreManager.currentMatch.team1Sets > 0 || scoreManager.currentMatch.team2Sets > 0 {
                        HStack(spacing: 8) {
                            Text("Match:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(scoreManager.currentMatch.team1Sets) - \(scoreManager.currentMatch.team2Sets)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.top, 4)
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Score buttons
                    if !scoreManager.currentMatch.isCompleted {
                        VStack(spacing: 8) {
                            ScoreButtonView(
                                team: 1,
                                teamName: scoreManager.currentMatch.team1Name,
                                action: {
                                    scoreManager.incrementPoint(for: 1)
                                }
                            )
                            
                            ScoreButtonView(
                                team: 2,
                                teamName: scoreManager.currentMatch.team2Name,
                                action: {
                                    scoreManager.incrementPoint(for: 2)
                                }
                            )
                        }
                        .padding(.horizontal, 4)
                    } else {
                        VStack(spacing: 8) {
                            Text("Winner: \(scoreManager.currentMatch.winner == 1 ? scoreManager.currentMatch.team1Name : scoreManager.currentMatch.team2Name)")
                                .font(.headline)
                                .foregroundColor(.green)
                                .padding(.vertical, 8)
                            
                            Button("New Match") {
                                showingNewMatchAlert = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Padel Score")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                
                if !scoreManager.currentMatch.isCompleted {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingNewMatchAlert = true
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                MatchHistoryView()
                    .environmentObject(scoreManager)
            }
            .alert("Start New Match?", isPresented: $showingNewMatchAlert) {
                Button("Cancel", role: .cancel) { }
                Button("New Match") {
                    scoreManager.startNewMatch()
                }
            } message: {
                Text("This will save the current match and start a new one.")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ScoreManager())
}

