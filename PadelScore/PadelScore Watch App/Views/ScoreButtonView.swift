//
//  ScoreButtonView.swift
//  PadelScore Watch App
//
//  Reusable button for incrementing scores
//

import SwiftUI

struct ScoreButtonView: View {
    let team: Int
    let teamName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(teamName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("+1")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
    }
}

