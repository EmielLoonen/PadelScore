//
//  ScoreboardService.swift
//  PadelScore Watch App
//
//  Service for sending scores to external scoreboard via HTTP
//

import Foundation

class ScoreboardService {
    
    /// Formats the current game score as a string
    /// - Parameter match: The current match
    /// - Returns: Formatted score string (e.g., "15-30", "40-40", "AD-40", "3-5")
    func formatGameScore(match: Match) -> String {
        // Handle tiebreak
        if match.currentSet.isTiebreak {
            if let tiebreak = match.currentSet.tiebreakScore {
                return "\(tiebreak.team1)-\(tiebreak.team2)"
            }
            return "0-0"
        }
        
        // Handle regular game
        let team1Score = match.currentGame.team1Points.displayValue
        let team2Score = match.currentGame.team2Points.displayValue
        return "\(team1Score)-\(team2Score)"
    }
    
    /// Formats the current set score as a string with match score
    /// - Parameter match: The current match
    /// - Returns: Formatted set score string with match score (e.g., "3-2 | 1-0")
    func formatSetScore(match: Match) -> String {
        let setScore = "\(match.currentSet.team1Games)-\(match.currentSet.team2Games)"
        let matchScore = "\(match.team1Sets)-\(match.team2Sets)"
        return "\(setScore) | \(matchScore)"
    }
    
    /// Sends the score to the scoreboard via HTTP POST
    /// - Parameters:
    ///   - text: The score text to display
    ///   - ipAddress: The IP address of the scoreboard
    ///   - servingTeam: The team that is serving (1 for left/team1, 2 for right/team2, nil if unknown)
    func sendScore(text: String, ipAddress: String, servingTeam: Int?) {
        // Validate IP address
        guard !ipAddress.isEmpty else { return }
        
        // Construct URL
        guard let url = URL(string: "http://\(ipAddress)/api/custom?name=GameScore") else {
            return
        }
        
        // Create JSON payload with text, duration, and optional draw property
        var payload: [String: Any] = [
            "text": text,
            "duration": 10
        ]
        
        // Add draw property if serving team is known
        if let servingTeam = servingTeam {
            if servingTeam == 1 {
                // Left team serving
                payload["draw"] = [
                    ["dfc": [2, 3, 2, "#E4F527"]],
                    ["dl": [1, 2, 1, 4, "#FFFFFF"]],
                    ["dp": [2, 1, "#FFFFFF"]],
                    ["dp": [2, 5, "#FFFFFF"]]
                ]
            } else if servingTeam == 2 {
                // Right team serving
                payload["draw"] = [
                    ["dfc": [28, 3, 2, "#E4F527"]],
                    ["dl": [27, 2, 27, 4, "#FFFFFF"]],
                    ["dp": [28, 1, "#FFFFFF"]],
                    ["dp": [28, 5, "#FFFFFF"]]
                ]
            }
        }
        
        // Encode JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Send request asynchronously (fire and forget)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Silently handle errors - don't block UI or crash app
            if let error = error {
                // Could log error in production, but silently fail for now
                print("Scoreboard error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    /// Sends the set score to the scoreboard via HTTP POST
    /// - Parameters:
    ///   - text: The set score text to display
    ///   - ipAddress: The IP address of the scoreboard
    func sendSetScore(text: String, ipAddress: String) {
        // Validate IP address
        guard !ipAddress.isEmpty else { return }
        
        // Construct URL
        guard let url = URL(string: "http://\(ipAddress)/api/custom?name=SetScore") else {
            return
        }
        
        // Create JSON payload with text and duration
        let payload: [String: Any] = [
            "text": text,
            "duration": 2
        ]
        
        // Encode JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Send request asynchronously (fire and forget)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Silently handle errors - don't block UI or crash app
            if let error = error {
                // Could log error in production, but silently fail for now
                print("Scoreboard error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
}
