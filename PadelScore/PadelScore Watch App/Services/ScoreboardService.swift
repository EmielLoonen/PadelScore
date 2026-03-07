//
//  ScoreboardService.swift
//  PadelScore Watch App
//
//  Service for sending scores to external scoreboard via HTTP
//

import Foundation

class ScoreboardService {
    
    /// Formats the current game score as a JSON array with colored text segments.
    /// Team 1 scores are colored blue (0000FF) and Team 2 scores are colored green (00FF00).
    func formatGameScore(match: Match) -> [[String: String]] {
        let team1IsLeft = match.currentTeam1Side == "L"
        
        var result: [[String: String]] = []
        
        if match.currentSet.isTiebreak {
            if let tiebreak = match.currentSet.tiebreakScore {
                if team1IsLeft {
                    result.append(["t": "\(tiebreak.team1)", "c": "0000FF"])
                    result.append(["t": "-", "c": "FFFFFF"])
                    result.append(["t": "\(tiebreak.team2)", "c": "00FF00"])
                } else {
                    result.append(["t": "\(tiebreak.team2)", "c": "00FF00"])
                    result.append(["t": "-", "c": "FFFFFF"])
                    result.append(["t": "\(tiebreak.team1)", "c": "0000FF"])
                }
            } else {
                result.append(["t": "0", "c": "0000FF"])
                result.append(["t": "-", "c": "FFFFFF"])
                result.append(["t": "0", "c": "00FF00"])
            }
        } else {
            let team1Score = match.currentGame.team1Points.displayValue
            let team2Score = match.currentGame.team2Points.displayValue
            
            if team1IsLeft {
                result.append(["t": team1Score, "c": "0000FF"])
                result.append(["t": "-", "c": "FFFFFF"])
                result.append(["t": team2Score, "c": "00FF00"])
            } else {
                result.append(["t": team2Score, "c": "00FF00"])
                result.append(["t": "-", "c": "FFFFFF"])
                result.append(["t": team1Score, "c": "0000FF"])
            }
        }
        
        return result
    }

    /// Formats the current set score as a JSON array with colored text segments.
    /// Team 1 scores are colored blue (0000FF) and Team 2 scores are colored green (00FF00).
    func formatSetScore(match: Match) -> [[String: String]] {
        let team1IsLeft = match.currentTeam1Side == "L"
        let leftGames  = team1IsLeft ? match.currentSet.team1Games : match.currentSet.team2Games
        let rightGames = team1IsLeft ? match.currentSet.team2Games : match.currentSet.team1Games
        let leftSets   = team1IsLeft ? match.team1Sets : match.team2Sets
        let rightSets  = team1IsLeft ? match.team2Sets : match.team1Sets
        
        // Determine colors for left and right sides
        let leftColor = team1IsLeft ? "0000FF" : "00FF00"
        let rightColor = team1IsLeft ? "00FF00" : "0000FF"
        
        var result: [[String: String]] = []
        result.append(["t": "\(leftGames)", "c": leftColor])
        result.append(["t": "-", "c": "FFFFFF"])
        result.append(["t": "\(rightGames)", "c": rightColor])
        result.append(["t": " | ", "c": "FFFFFF"])
        result.append(["t": "\(leftSets)", "c": leftColor])
        result.append(["t": "-", "c": "FFFFFF"])
        result.append(["t": "\(rightSets)", "c": rightColor])
        
        return result
    }

    /// Sends the score to the scoreboard via HTTP POST.
    /// - Parameters:
    ///   - textArray: The score text array with color information
    ///   - ipAddress: The IP address of the scoreboard
    ///   - servingIsOnLeft: true if the serving team is on the left side of the court, false for right, nil if unknown
    func sendScore(textArray: [[String: String]], ipAddress: String, servingIsOnLeft: Bool?) {
        // Validate IP address
        guard !ipAddress.isEmpty else { return }
        
        // Construct URL
        guard let url = URL(string: "http://\(ipAddress)/api/custom?name=GameScore") else {
            return
        }
        
        // Create JSON payload with text array, duration, and optional draw property
        var payload: [String: Any] = [
            "text": textArray,
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
    ///   - textArray: The set score text array with color information
    ///   - ipAddress: The IP address of the scoreboard
    func sendSetScore(textArray: [[String: String]], ipAddress: String) {
        // Validate IP address
        guard !ipAddress.isEmpty else { return }
        
        // Construct URL
        guard let url = URL(string: "http://\(ipAddress)/api/custom?name=SetScore") else {
            return
        }
        
        // Create JSON payload with text array and duration
        let payload: [String: Any] = [
            "text": textArray,
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
