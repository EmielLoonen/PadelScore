//
//  ScoreboardService.swift
//  PadelScore Watch App
//
//  Service for sending scores to external scoreboard via HTTP
//

import Foundation

class ScoreboardService {
    
    /// Returns the initials of the currently serving player from the match.
    private func servingInitials(_ match: Match) -> String {
        switch match.servingPlayer {
        case "A": return match.team1Player1.isEmpty ? "?" : match.team1Player1
        case "B": return match.team1Player2.isEmpty ? "?" : match.team1Player2
        case "C": return match.team2Player1.isEmpty ? "?" : match.team2Player1
        case "D": return match.team2Player2.isEmpty ? "?" : match.team2Player2
        default:  return "?"
        }
    }

    /// Formats the current game score as a JSON array with white text segments.
    /// At 0-0, the serving player's initials replace "0" on their side.
    func formatGameScore(match: Match) -> [[String: String]] {
        let team1IsLeft = match.currentTeam1Side == "L"
        let servingTeam = match.servingTeam ?? 1
        // True when the serving team is positioned on the left side of the court
        let servingIsOnLeft = team1IsLeft ? (servingTeam == 1) : (servingTeam == 2)

        var result: [[String: String]] = []

        if match.currentSet.isTiebreak {
            let t1 = match.currentSet.tiebreakScore?.team1 ?? 0
            let t2 = match.currentSet.tiebreakScore?.team2 ?? 0
            let isZeroZero = t1 == 0 && t2 == 0
            let initials = isZeroZero ? servingInitials(match) : nil

            let leftRaw  = team1IsLeft ? "\(t1)" : "\(t2)"
            let rightRaw = team1IsLeft ? "\(t2)" : "\(t1)"
            let leftVal  = (isZeroZero && servingIsOnLeft)  ? initials! : leftRaw
            let rightVal = (isZeroZero && !servingIsOnLeft) ? initials! : rightRaw

            result.append(["t": leftVal,  "c": "FFFFFF"])
            result.append(["t": "-",      "c": "FFFFFF"])
            result.append(["t": rightVal, "c": "FFFFFF"])
        } else {
            let isLoveLove = match.currentGame.team1Points == .love && match.currentGame.team2Points == .love
            let initials = isLoveLove ? servingInitials(match) : nil

            let team1Score = match.currentGame.team1Points.displayValue
            let team2Score = match.currentGame.team2Points.displayValue
            let leftRaw  = team1IsLeft ? team1Score : team2Score
            let rightRaw = team1IsLeft ? team2Score : team1Score
            let leftVal  = (isLoveLove && servingIsOnLeft)  ? initials! : leftRaw
            let rightVal = (isLoveLove && !servingIsOnLeft) ? initials! : rightRaw

            result.append(["t": leftVal,  "c": "FFFFFF"])
            result.append(["t": "-",      "c": "FFFFFF"])
            result.append(["t": rightVal, "c": "FFFFFF"])
        }

        return result
    }

    /// Formats the current set score as a JSON array with colored text segments.
    /// Team 1 scores are colored blue (FFFFFF) and Team 2 scores are colored green (FFFFFF).
    func formatSetScore(match: Match) -> [[String: String]] {
        let team1IsLeft = match.currentTeam1Side == "L"
        let leftGames  = team1IsLeft ? match.currentSet.team1Games : match.currentSet.team2Games
        let rightGames = team1IsLeft ? match.currentSet.team2Games : match.currentSet.team1Games
        let leftSets   = team1IsLeft ? match.team1Sets : match.team2Sets
        let rightSets  = team1IsLeft ? match.team2Sets : match.team1Sets
        
        // Determine colors for left and right sides
        let leftColor = team1IsLeft ? "FFFFFF" : "FFFFFF"
        let rightColor = team1IsLeft ? "FFFFFF" : "FFFFFF"
        
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
    ///   - servingTeamColor: hex color string for the serving team (e.g. "0000FF"), used for the dfc indicator
    func sendScore(textArray: [[String: String]], ipAddress: String, servingIsOnLeft: Bool?, servingTeamColor: String?) {
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
            let dotColor = servingTeamColor.map { "#\($0)" } ?? "#E4F527"
            if servingIsOnLeft {
                payload["draw"] = [
                    ["dfc": [2, 3, 2, dotColor]],
                    ["dl": [1, 2, 1, 4, "#FFFFFF"]],
                    ["dp": [2, 1, "#FFFFFF"]],
                    ["dp": [2, 5, "#FFFFFF"]]
                ]
            } else {
                payload["draw"] = [
                    ["dfc": [28, 3, 2, dotColor]],
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
