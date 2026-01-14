# Padel Score Watch App

An Apple Watch app for tracking padel scores during matches using tennis-style scoring.

## Features

- **Tennis-style scoring**: Love → 15 → 30 → 40 → Game
- **Set tracking**: First to 6 games wins a set (must win by 2), tiebreak at 6-6
- **Match tracking**: Best of 3 sets
- **Match history**: Save and view past matches
- **Haptic feedback**: Tactile feedback on score changes
- **Watch-optimized UI**: Large, readable text and easy-to-tap buttons

## Scoring System

### Points
- **Love (0)** → **15** → **30** → **40** → **Game**
- At 40-40 (deuce), next point gives advantage
- Must win by 2 points from deuce

### Games
- First to 6 games wins a set (must win by 2)
- At 6-6, a tiebreak is played (first to 7, win by 2)

### Sets
- Best of 3 sets wins the match

## Setup

1. Open the project in Xcode
2. Ensure you have watchOS 9.0+ as the deployment target
3. Build and run on your Apple Watch or simulator

## Usage

1. **Start a match**: The app begins with a new match automatically
2. **Increment scores**: Tap the "+1" button for the team that scored
3. **View history**: Tap the clock icon to see past matches
4. **New match**: Tap the refresh icon to start a new match

## Project Structure

```
PadelScore Watch App/
├── PadelScoreApp.swift          # App entry point
├── ContentView.swift            # Main score view
├── MatchHistoryView.swift       # History list and detail views
├── Models/
│   ├── Match.swift              # Match data model
│   ├── Set.swift                # Set scoring logic
│   ├── Game.swift               # Game scoring logic
│   └── ScoreManager.swift       # Score management and persistence
└── Views/
    └── ScoreButtonView.swift    # Reusable score button
```

## Requirements

- watchOS 9.0+
- Xcode 14.0+
- Swift 5.7+

## Notes

- Matches are automatically saved to history when completed
- History is stored locally using UserDefaults
- The app is optimized for Apple Watch screen sizes
- Haptic feedback provides tactile confirmation of score changes




