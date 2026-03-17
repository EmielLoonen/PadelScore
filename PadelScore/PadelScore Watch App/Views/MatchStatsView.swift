//
//  MatchStatsView.swift
//  PadelScore Watch App
//
//  Displays match statistics
//

import SwiftUI

struct MatchStatsView: View {
    let match: Match
    let stats: MatchStats

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Overview
                teamOverviewSection

                Divider()

                // Serve / Return
                serveReturnSection

                Divider()

                // Break points
                breakPointSection

                Divider()

                // Clutch & Streaks
                clutchSection

                Divider()

                // Individual players
                playersSection(players: stats.team1Players, teamColor: .blue, teamLabel: "Team 1")

                Divider()

                playersSection(players: stats.team2Players, teamColor: .green, teamLabel: "Team 2")
            }
            .padding()
        }
        .navigationTitle("Stats")
    }

    // MARK: - Sections

    private var teamOverviewSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Overview").font(.headline)
            statRow("Points", left: "\(stats.team1.pointsWon)", right: "\(stats.team2.pointsWon)")
            statRow("Games",  left: "\(stats.team1.gamesWon)",  right: "\(stats.team2.gamesWon)")
            statRow("Sets",   left: "\(stats.team1.setsWon)",   right: "\(stats.team2.setsWon)")
        }
    }

    private var serveReturnSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Serve / Return").font(.headline)
            statRow("Win% serve",  left: pct(stats.team1.serveWinPct),  right: pct(stats.team2.serveWinPct))
            statRow("Win% return", left: pct(stats.team1.returnWinPct), right: pct(stats.team2.returnWinPct))
        }
    }

    private var breakPointSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Break Points").font(.headline)
            let t1 = stats.team1
            let t2 = stats.team2
            statRow("Opportunities", left: "\(t1.breakPointOpportunities)", right: "\(t2.breakPointOpportunities)")
            statRow("Converted",     left: "\(t1.breakPointsConverted)",    right: "\(t2.breakPointsConverted)")
            statRow("Rate",          left: pct(t1.breakConversionPct),      right: pct(t2.breakConversionPct))
        }
    }

    private var clutchSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Clutch & Streaks").font(.headline)
            statRow("Clutch pts",   left: "\(stats.team1.clutchPointsWon)", right: "\(stats.team2.clutchPointsWon)")
            statRow("Best streak",  left: "\(stats.team1.longestWinStreak)", right: "\(stats.team2.longestWinStreak)")
        }
    }

    private func playersSection(players: [MatchStats.PlayerStats], teamColor: Color, teamLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(teamLabel).font(.headline).foregroundColor(teamColor)
            ForEach(players, id: \.code) { p in
                playerCard(p, teamColor: teamColor)
            }
        }
    }

    private func playerCard(_ p: MatchStats.PlayerStats, teamColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(p.name).font(.subheadline).fontWeight(.semibold).foregroundColor(teamColor)

            playerStatRow("Points won", value: "\(p.pointsWon)")
            if let pct = p.contributionPct {
                playerStatRow("Contribution", value: fmtPct(pct))
            }
            if let pct = p.onServeWinPct {
                playerStatRow("Win% on serve", value: fmtPct(pct))
            }
            if let pct = p.onReturnWinPct {
                playerStatRow("Win% on return", value: fmtPct(pct))
            }
            if p.gameWinningPoints > 0 {
                playerStatRow("Game winners", value: "\(p.gameWinningPoints)")
            }
            if p.setWinningPoints > 0 {
                playerStatRow("Set winners", value: "\(p.setWinningPoints)")
            }
            if p.clutchPoints > 0 {
                playerStatRow("Clutch pts", value: "\(p.clutchPoints)")
            }
            // Per-set breakdown
            if p.pointsBySet.count > 1 {
                let sets = p.pointsBySet.sorted { $0.key < $1.key }
                HStack(spacing: 6) {
                    Text("By set:").font(.caption2).foregroundColor(.secondary)
                    ForEach(sets, id: \.key) { setNum, pts in
                        Text("S\(setNum + 1):\(pts)").font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private func statRow(_ label: String, left: String, right: String) -> some View {
        HStack {
            Text(left).font(.caption).fontWeight(.bold).foregroundColor(.blue).frame(minWidth: 36, alignment: .trailing)
            Text(label).font(.caption2).foregroundColor(.secondary).frame(maxWidth: .infinity)
            Text(right).font(.caption).fontWeight(.bold).foregroundColor(.green).frame(minWidth: 36, alignment: .leading)
        }
    }

    private func playerStatRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption2).fontWeight(.medium)
        }
    }

    private func pct(_ value: Double?) -> String {
        guard let v = value else { return "-" }
        return fmtPct(v)
    }

    private func fmtPct(_ v: Double) -> String {
        "\(Int(v * 100))%"
    }
}
