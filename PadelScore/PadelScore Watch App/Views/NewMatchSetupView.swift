//
//  NewMatchSetupView.swift
//  PadelScore Watch App
//
//  Player setup before starting a new match
//

import SwiftUI

struct NewMatchSetupView: View {
    @ObservedObject var gameSettings: GameSettings
    @EnvironmentObject var scoreManager: ScoreManager
    @Environment(\.dismiss) var dismiss

    @State private var playerA: Player? = nil
    @State private var playerB: Player? = nil
    @State private var playerC: Player? = nil
    @State private var playerD: Player? = nil
    @State private var allKnownPlayers: [Player] = []
    
    @State private var step = 1
    @State private var servingTeam = 1
    @State private var servingPlayer = "A"
    @State private var startingSide = "R" // "L" or "R"
    @State private var courtCode: String
    @State private var isLoadingPlayers = false
    @State private var loadError: String?
    @State private var showCourtCodeEntry = false
    @State private var showPlayerPicker = false
    @State private var selectedPosition: String = "" // "A", "B", "C", or "D"
    
    private let coordinatorService = CourtCoordinatorService()
    private let knownPlayersKey = "KnownPlayers"
    
    init(gameSettings: GameSettings) {
        self.gameSettings = gameSettings
        _courtCode = State(initialValue: gameSettings.lastWatchCode)
    }
    
    var body: some View {
        NavigationStack {
            if step == 1 {
                List {
                    Section("Team 1") {
                        Button {
                            selectedPosition = "A"
                            showPlayerPicker = true
                        } label: {
                            HStack {
                                Text("Player A")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(playerA?.initials ?? "Tap to select")
                                    .foregroundColor(playerA == nil ? .gray : .primary)
                            }
                        }
                        
                        Button {
                            selectedPosition = "B"
                            showPlayerPicker = true
                        } label: {
                            HStack {
                                Text("Player B")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(playerB?.initials ?? "Tap to select")
                                    .foregroundColor(playerB == nil ? .gray : .primary)
                            }
                        }
                    }
                    
                    Section("Team 2") {
                        Button {
                            selectedPosition = "C"
                            showPlayerPicker = true
                        } label: {
                            HStack {
                                Text("Player C")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(playerC?.initials ?? "Tap to select")
                                    .foregroundColor(playerC == nil ? .gray : .primary)
                            }
                        }
                        
                        Button {
                            selectedPosition = "D"
                            showPlayerPicker = true
                        } label: {
                            HStack {
                                Text("Player D")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(playerD?.initials ?? "Tap to select")
                                    .foregroundColor(playerD == nil ? .gray : .primary)
                            }
                        }
                    }
                    
                    Section {
                        Button {
                            showCourtCodeEntry = true
                        } label: {
                            HStack {
                                Image(systemName: "network")
                                Text("Load from Court Code")
                            }
                        }
                    }
                    
                    if let error = loadError {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Section {
                        Button("Next") { step = 2 }
                            .disabled(!allPlayersSelected)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .navigationTitle("New Match")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .onAppear {
                    loadKnownPlayers()
                    // Pre-populate players from previous match if available
                    if allKnownPlayers.isEmpty {
                        initializeFromPreviousMatch()
                    }
                }
                .sheet(isPresented: $showCourtCodeEntry) {
                    CourtCodeEntryView(
                        courtCode: $courtCode,
                        isLoading: $isLoadingPlayers,
                        onFetch: fetchPlayersFromService
                    )
                }
                .sheet(isPresented: $showPlayerPicker) {
                    PlayerPickerView(
                        availablePlayers: $allKnownPlayers,
                        selectedPosition: selectedPosition,
                        alreadySelectedPlayers: [playerA, playerB, playerC, playerD].compactMap { $0 },
                        onSelect: { player in
                            assignPlayer(player, to: selectedPosition)
                            showPlayerPicker = false
                        }
                    )
                }
            } else if step == 2 {
                List {
                    Section("Who serves first?") {
                        ForEach([
                            (code: "A", name: playerA?.initials ?? "Player A"),
                            (code: "B", name: playerB?.initials ?? "Player B"),
                            (code: "C", name: playerC?.initials ?? "Player C"),
                            (code: "D", name: playerD?.initials ?? "Player D")
                        ], id: \.code) { player in
                            Button {
                                servingPlayer = player.code
                                servingTeam = (player.code == "A" || player.code == "B") ? 1 : 2
                            } label: {
                                HStack {
                                    Text(player.name)
                                    Spacer()
                                    if servingPlayer == player.code {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    Section {
                        Button("Next") { step = 3 }
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .navigationTitle("Who Serves?")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") { step = 1 }
                    }
                }
            } else {
                // Step 3: Starting side selection
                List {
                    Section("Starting side for serving team?") {
                        Button {
                            startingSide = "L"
                        } label: {
                            HStack {
                                Text("Left side")
                                Spacer()
                                if startingSide == "L" {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Button {
                            startingSide = "R"
                        } label: {
                            HStack {
                                Text("Right side")
                                Spacer()
                                if startingSide == "R" {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    Section {
                        Button("Start Match") {
                            // Save player initials to game settings
                            gameSettings.team1Player1 = playerA?.initials ?? ""
                            gameSettings.team1Player2 = playerB?.initials ?? ""
                            gameSettings.team2Player1 = playerC?.initials ?? ""
                            gameSettings.team2Player2 = playerD?.initials ?? ""
                            
                            // Set the side based on which team is serving
                            if servingTeam == 1 {
                                gameSettings.team1Side = startingSide
                            } else {
                                // If team 2 is serving, they start on the selected side
                                // so team 1 gets the opposite side
                                gameSettings.team1Side = startingSide == "L" ? "R" : "L"
                            }
                            
                            scoreManager.startNewMatch(
                                servingTeam: servingTeam,
                                servingPlayer: servingPlayer,
                                playerA: playerA,
                                playerB: playerB,
                                playerC: playerC,
                                playerD: playerD,
                                watchCode: courtCode.isEmpty ? nil : courtCode
                            )
                            
                            dismiss()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .navigationTitle("Starting Side?")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") { step = 2 }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Check if all players are selected
    private var allPlayersSelected: Bool {
        return playerA != nil && playerB != nil && playerC != nil && playerD != nil
    }
    
    /// Load known players from UserDefaults
    private func loadKnownPlayers() {
        if let data = UserDefaults.standard.data(forKey: knownPlayersKey),
           let players = try? JSONDecoder().decode([Player].self, from: data) {
            allKnownPlayers = players
        }
    }
    
    /// Initialize players from previous match if they exist
    private func initializeFromPreviousMatch() {
        // Create Player objects from game settings if they have names
        var players: [Player] = []
        
        if !gameSettings.team1Player1.isEmpty {
            players.append(Player(
                id: UUID().uuidString,
                initials: gameSettings.team1Player1
            ))
        }
        
        if !gameSettings.team1Player2.isEmpty {
            players.append(Player(
                id: UUID().uuidString,
                initials: gameSettings.team1Player2
            ))
        }
        
        if !gameSettings.team2Player1.isEmpty {
            players.append(Player(
                id: UUID().uuidString,
                initials: gameSettings.team2Player1
            ))
        }
        
        if !gameSettings.team2Player2.isEmpty {
            players.append(Player(
                id: UUID().uuidString,
                initials: gameSettings.team2Player2
            ))
        }
        
        if !players.isEmpty {
            allKnownPlayers = players
            saveKnownPlayers()
        }
    }
    
    /// Save known players to UserDefaults
    private func saveKnownPlayers() {
        if let data = try? JSONEncoder().encode(allKnownPlayers) {
            UserDefaults.standard.set(data, forKey: knownPlayersKey)
        }
    }
    
    /// Assign a player to a specific position
    private func assignPlayer(_ player: Player, to position: String) {
        switch position {
        case "A": playerA = player
        case "B": playerB = player
        case "C": playerC = player
        case "D": playerD = player
        default: break
        }
    }
    
    /// Fetch players from the court coordinator service
    private func fetchPlayersFromService() async {
        loadError = nil
        isLoadingPlayers = true
        
        do {
            let teams = try await coordinatorService.fetchPlayers(courtCode: courtCode)
            
            // Assign players to positions and store all players
            await MainActor.run {
                playerA = teams.team1Player1
                playerB = teams.team1Player2
                playerC = teams.team2Player1
                playerD = teams.team2Player2
                allKnownPlayers = teams.allPlayers
                saveKnownPlayers() // Persist for next time
                gameSettings.lastWatchCode = courtCode // Persist court code for next match
                isLoadingPlayers = false
                showCourtCodeEntry = false
            }
        } catch {
            await MainActor.run {
                isLoadingPlayers = false
                loadError = "Failed to load players. Please try again."
            }
        }
    }
}

// MARK: - Player Picker View

struct PlayerPickerView: View {
    @Binding var availablePlayers: [Player]
    let selectedPosition: String
    let alreadySelectedPlayers: [Player]
    var onSelect: (Player) -> Void
    @Environment(\.dismiss) var dismiss
    
    /// Filter out already-selected players (except for the current position being edited)
    private var selectablePlayers: [Player] {
        // Collect IDs of already selected players
        let selectedIDs = Swift.Set(alreadySelectedPlayers.map { $0.id })
        
        return availablePlayers.filter { player in
            // Show players that aren't selected yet
            !selectedIDs.contains(player.id)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if selectablePlayers.isEmpty {
                    Section {
                        if availablePlayers.isEmpty {
                            Text("No players available")
                                .foregroundColor(.secondary)
                            Text("Load from court code first")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("All players already selected")
                                .foregroundColor(.secondary)
                            Text("Tap another position to change")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Section("Select Player for Position \(selectedPosition)") {
                        ForEach(selectablePlayers) { player in
                            Button {
                                onSelect(player)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(player.initials)
                                            .font(.headline)
                                        if let rating = player.rating {
                                            Text("Rating: \(String(format: "%.2f", rating))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(player.type == "user" ? .blue : .gray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Court Code Entry View

struct CourtCodeEntryView: View {
    @Binding var courtCode: String
    @Binding var isLoading: Bool
    var onFetch: () async -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Enter Court Code") {
                    TextField("Court Code", text: $courtCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                Section {
                    Button {
                        Task {
                            await onFetch()
                        }
                    } label: {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                                Text("Loading...")
                            }
                        } else {
                            Text("Fetch Players")
                        }
                    }
                    .disabled(courtCode.isEmpty || isLoading)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Court Code")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
}

#Preview {
    let gameSettings = GameSettings()
    NewMatchSetupView(gameSettings: gameSettings)
        .environmentObject(ScoreManager(gameSettings: gameSettings))
}
