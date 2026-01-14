//
//  MatchHistoryView.swift
//  PadelScore Watch App
//
//  View displaying match history
//

import SwiftUI

struct MatchHistoryView: View {
    @EnvironmentObject var scoreManager: ScoreManager
    @Environment(\.dismiss) var dismiss
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationStack {
            if scoreManager.matchHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No Match History")
                        .font(.headline)
                    Text("Completed matches will appear here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .navigationTitle("History")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            } else {
                List {
                    ForEach(scoreManager.matchHistory) { match in
                        NavigationLink {
                            MatchDetailView(match: match)
                        } label: {
                            MatchRowView(match: match)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            scoreManager.deleteMatch(at: index)
                        }
                    }
                }
                .navigationTitle("History")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingClearAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                .alert("Clear All History?", isPresented: $showingClearAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Clear", role: .destructive) {
                        scoreManager.clearHistory()
                    }
                } message: {
                    Text("This action cannot be undone.")
                }
            }
        }
    }
}

struct MatchRowView: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(match.team1Name)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("vs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(match.team2Name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text(match.finalScore)
                    .font(.headline)
                
                Spacer()
                
                Text(match.formattedDuration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(match.startDate, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct MatchDetailView: View {
    let match: Match
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Match header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Match Details")
                        .font(.headline)
                    
                    HStack {
                        Text(match.team1Name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("vs")
                            .foregroundColor(.secondary)
                        Text(match.team2Name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    if match.isCompleted {
                        Text("Winner: \(match.winner == 1 ? match.team1Name : match.team2Name)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Divider()
                
                // Set scores
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sets")
                        .font(.headline)
                    
                    ForEach(Array(match.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(set.team1Games) - \(set.team2Games)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if set.isTiebreak, let tiebreak = set.tiebreakScore {
                                Text("(\(tiebreak.team1)-\(tiebreak.team2))")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            
                            if set.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Match info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Match Info")
                        .font(.headline)
                    
                    InfoRow(label: "Started", value: match.startDate.formatted(date: .abbreviated, time: .shortened))
                    
                    if let endDate = match.endDate {
                        InfoRow(label: "Ended", value: endDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    InfoRow(label: "Duration", value: match.formattedDuration)
                    
                    InfoRow(label: "Final Score", value: match.finalScore)
                }
            }
            .padding()
        }
        .navigationTitle("Match")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    MatchHistoryView()
        .environmentObject(ScoreManager())
}

