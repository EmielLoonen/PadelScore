//
//  CourtCoordinatorService.swift
//  PadelScore Watch App
//
//  Service for fetching player information from Court Coordinator API
//

import Foundation

/// Response model for the Court Coordinator API
struct CourtCoordinatorResponse: Codable {
    let courtId: String
    let courtNumber: Int
    let session: SessionInfo
    let teams: Teams
    
    struct SessionInfo: Codable {
        let date: String
        let time: String
        let venue: String
    }
    
    struct Teams: Codable {
        let team1: [PlayerInfo]
        let team2: [PlayerInfo]
    }
    
    struct PlayerInfo: Codable {
        let id: String
        let initials: String
        let type: String
        let rating: Double?
    }
}

/// Represents a player with their identity
struct Player: Identifiable, Codable, Equatable {
    let id: String
    let initials: String
    let type: String
    let rating: Double?
    
    init(id: String, initials: String, type: String = "user", rating: Double? = nil) {
        self.id = id
        self.initials = initials
        self.type = type
        self.rating = rating
    }
}

class CourtCoordinatorService {
    private let baseURL = "https://padel-coordinator-api.onrender.com/api/watch"
    
    /// Result structure containing team assignments with full player data
    struct TeamAssignments {
        let team1Player1: Player
        let team1Player2: Player
        let team2Player1: Player
        let team2Player2: Player
        
        /// Get all players as an array
        var allPlayers: [Player] {
            [team1Player1, team1Player2, team2Player1, team2Player2]
        }
    }
    
    /// Fetches player data from the Court Coordinator API
    /// - Parameter courtCode: The court code to fetch players for
    /// - Returns: TeamAssignments with full player data organized by team
    /// - Throws: URLError or DecodingError
    func fetchPlayers(courtCode: String) async throws -> TeamAssignments {
        // Validate court code
        guard !courtCode.isEmpty else {
            throw URLError(.badURL)
        }
        
        // Construct URL
        guard let url = URL(string: "\(baseURL)/\(courtCode)") else {
            throw URLError(.badURL)
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10 // 10 second timeout
        
        // Perform request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Decode response
        let decoder = JSONDecoder()
        let coordinatorResponse = try decoder.decode(CourtCoordinatorResponse.self, from: data)
        
        // Validate we got 2 players per team
        guard coordinatorResponse.teams.team1.count == 2,
              coordinatorResponse.teams.team2.count == 2 else {
            throw URLError(.cannotParseResponse)
        }
        
        // Convert to Player objects
        let team1Players = coordinatorResponse.teams.team1.map {
            Player(id: $0.id, initials: $0.initials, type: $0.type, rating: $0.rating)
        }
        let team2Players = coordinatorResponse.teams.team2.map {
            Player(id: $0.id, initials: $0.initials, type: $0.type, rating: $0.rating)
        }
        
        return TeamAssignments(
            team1Player1: team1Players[0],
            team1Player2: team1Players[1],
            team2Player1: team2Players[0],
            team2Player2: team2Players[1]
        )
    }
}
