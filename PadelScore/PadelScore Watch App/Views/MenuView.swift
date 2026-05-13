//
//  MenuView.swift
//  PadelScore Watch App
//
//  Menu options view
//

import SwiftUI

struct MenuView: View {
    @Binding var showingNewMatchSetup: Bool
    @Binding var showingHistory: Bool
    @Binding var showingSettings: Bool
    @Binding var showingMenu: Bool
    @Binding var showingChangeServer: Bool
    @Binding var showingViewer: Bool
    let isMatchInProgress: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                if isMatchInProgress {
                    Button {
                        showingNewMatchSetup = true
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("New Match")
                        }
                    }

                    Button {
                        showingChangeServer = true
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Change Server")
                        }
                    }
                }
                
                Button {
                    showingViewer = true
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "eye")
                        Text("Join as Viewer")
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
        showingNewMatchSetup: .constant(false),
        showingHistory: .constant(false),
        showingSettings: .constant(false),
        showingMenu: .constant(true),
        showingChangeServer: .constant(false),
        showingViewer: .constant(false),
        isMatchInProgress: true
    )
}
