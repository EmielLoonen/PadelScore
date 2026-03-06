//
//  ScoreboardService.swift
//  PadelScore Watch App
//
//  Service for sending scores to external scoreboard via HTTP
//

import Foundation

class ScoreboardService {
    
    /// Formats the current game score as a string, ordered left-to-right by court side.
    func formatGameScore(match: Match) -> String {
        let team1IsLeft = match.currentTeam1Side == "L"
        if match.currentSet.isTiebreak {
            if let tiebreak = match.currentSet.tiebreakScore {
                return team1IsLeft
                    ? "\(tiebreak.team1)-\(tiebreak.team2)"
                    : "\(tiebreak.team2)-\(tiebreak.team1)"
            }
            return "0-0"
        }
        let team1Score = match.currentGame.team1Points.displayValue
        let team2Score = match.currentGame.team2Points.displayValue
        return team1IsLeft ? "\(team1Score)-\(team2Score)" : "\(team2Score)-\(team1Score)"
    }

    /// Formats the current set score as a string with match score, ordered left-to-right by court side.
    func formatSetScore(match: Match) -> String {
        let team1IsLeft = match.currentTeam1Side == "L"
        let leftGames  = team1IsLeft ? match.currentSet.team1Games : match.currentSet.team2Games
        let rightGames = team1IsLeft ? match.currentSet.team2Games : match.currentSet.team1Games
        let leftSets   = team1IsLeft ? match.team1Sets : match.team2Sets
        let rightSets  = team1IsLeft ? match.team2Sets : match.team1Sets
        return "\(leftGames)-\(rightGames) | \(leftSets)-\(rightSets)"
    }

    /// Sends the score to the scoreboard via HTTP POST.
    /// - Parameters:
    ///   - text: The score text to display
    ///   - ipAddress: The IP address of the scoreboard
    ///   - servingIsOnLeft: true if the serving team is on the left side of the court, false for right, nil if unknown
    func sendScore(text: String, ipAddress: String, servingIsOnLeft: Bool?) {
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
        
        // Add draw property if serving side is known
        if let servingIsOnLeft = servingIsOnLeft {
            if servingIsOnLeft {
                payload["draw"] = [
                    ["dfc": [2, 3, 2, "#E4F527"]],
                    ["dl": [1, 2, 1, 4, "#FFFFFF"]],
                    ["dp": [2, 1, "#FFFFFF"]],
                    ["dp": [2, 5, "#FFFFFF"]]
                ]
            } else {
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
