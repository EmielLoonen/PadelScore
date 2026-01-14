# Xcode Project Setup Guide

## Creating the watchOS App Target

### Step 1: Create New Project
1. Open **Xcode**
2. Go to **File → New → Project** (or press `Cmd+Shift+N`)
3. Select **watchOS** tab at the top
4. Choose **App** template
5. Click **Next**

### Step 2: Configure Project
Fill in the project details:
- **Product Name**: `PadelScore`
- **Team**: Select your Apple Developer team
- **Organization Identifier**: e.g., `com.yourname` or `com.backbase`
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Include Tests**: (Optional, can be unchecked)

### Step 3: Save Project
- Choose a location to save (the `PadelScore` folder is fine)
- Make sure **"Create Git repository"** is unchecked (or checked if you want version control)
- Click **Create**

### Step 4: Replace Default Files
After Xcode creates the project:

1. **Delete** the default `ContentView.swift` that Xcode created (if it exists)
2. **Keep** the `PadelScoreApp.swift` file, but replace its contents with your version
3. **Add** all your files:
   - Right-click on the project navigator
   - Select **Add Files to "PadelScore"...**
   - Navigate to `PadelScore Watch App/` folder
   - Select all files and folders:
     - `PadelScoreApp.swift`
     - `ContentView.swift`
     - `MatchHistoryView.swift`
     - `Models/` folder (with all Swift files inside)
     - `Views/` folder (with `ScoreButtonView.swift`)
   - Make sure **"Copy items if needed"** is checked
   - Make sure the **watchOS app target** is selected in "Add to targets"
   - Click **Add**

### Step 5: Verify Target Membership
1. Select any Swift file in the project navigator
2. Open the **File Inspector** (right panel, first tab)
3. Under **Target Membership**, ensure the watchOS app target is checked
4. Repeat for all files

### Step 6: Configure Deployment Target
1. Select the **PadelScore** project in the navigator (blue icon at top)
2. Select the **PadelScore Watch App** target
3. Go to **General** tab
4. Set **Minimum Deployments** to **watchOS 9.0** (or your preferred version)

### Step 7: Build and Run
1. Select a watchOS simulator or connected Apple Watch from the device menu
2. Press `Cmd+R` to build and run
3. The app should launch on the watch simulator/device

## Troubleshooting

### If files show errors:
- Make sure all files are added to the correct target
- Check that `ScoreManager` is marked as `@ObservableObject` (it is)
- Verify all imports are correct

### If the app doesn't build:
- Clean build folder: **Product → Clean Build Folder** (`Cmd+Shift+K`)
- Check that watchOS deployment target is set correctly
- Verify all Swift files compile individually

### If you see "Cannot find type in scope":
- Make sure all model files are included in the target
- Check that file organization matches the imports

## Project Structure After Setup

```
PadelScore/
├── PadelScore Watch App/
│   ├── PadelScoreApp.swift
│   ├── ContentView.swift
│   ├── MatchHistoryView.swift
│   ├── Models/
│   │   ├── Match.swift
│   │   ├── Set.swift
│   │   ├── Game.swift
│   │   └── ScoreManager.swift
│   └── Views/
│       └── ScoreButtonView.swift
└── README.md
```

## Notes

- The watchOS app is standalone (no iPhone companion app needed)
- All data is stored locally using UserDefaults
- The app works on watchOS 9.0 and later




