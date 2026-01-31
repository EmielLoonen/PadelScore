//
//  MenuView.swift
//  PadelScore Watch App
//
//  Menu options view
//

import SwiftUI

struct MenuView: View {
    @Binding var showingNewMatchAlert: Bool
    @Binding var showingHistory: Bool
    @Binding var showingSettings: Bool
    @Binding var showingMenu: Bool
    let isMatchInProgress: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if isMatchInProgress {
                    Button {
                        showingNewMatchAlert = true
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("New Match")
                        }
                    }
                }
                
                Button {
                    showingHistory = true
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("History")
                    }
                }
                
                Button {
                    showingSettings = true
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                }
            }
            .navigationTitle("Menu")
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
    MenuView(
        showingNewMatchAlert: .constant(false),
        showingHistory: .constant(false),
        showingSettings: .constant(false),
        showingMenu: .constant(true),
        isMatchInProgress: true
    )
}
