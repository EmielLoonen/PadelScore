# Troubleshooting Xcode Build Issues

## Common Issues and Solutions

### Issue 1: "Cannot find type 'X' in scope"
**Solution**: Files may not be added to the target
1. Select the file in Project Navigator
2. Open File Inspector (right panel, first icon)
3. Under **Target Membership**, check the box for your watchOS app target
4. Repeat for all Swift files

### Issue 2: "No such module 'WatchKit'"
**Solution**: Ensure you're building for watchOS, not iOS
1. Select your project in Navigator
2. Select the watchOS app target
3. Go to **Build Settings**
4. Verify **Supported Platforms** includes `watchos`
5. Check **Base SDK** is set to `watchos` (latest)

### Issue 3: Multiple "Cannot find type" errors
**Solution**: Clean build and verify file organization
1. **Product → Clean Build Folder** (Cmd+Shift+K)
2. Verify all files are in the correct groups:
   - `Models/` folder contains: Game.swift, Set.swift, Match.swift, ScoreManager.swift
   - `Views/` folder contains: ScoreButtonView.swift
   - Root contains: PadelScoreApp.swift, ContentView.swift, MatchHistoryView.swift
3. **Product → Build** (Cmd+B)

### Issue 4: "Value of type 'Match' has no member 'currentSet'"
**Solution**: This should be fixed now, but if it persists:
1. Verify Match.swift is added to target
2. Clean build folder
3. Check that all files compile individually

### Issue 5: Preview errors
**Solution**: Previews may fail if environment objects aren't provided
- This is normal - previews are optional
- The app should still build and run

### Issue 6: "Ambiguous reference to member"
**Solution**: Check for duplicate definitions
1. Search for duplicate type names
2. Ensure each file is only added once to the target

## Step-by-Step Fix for Multiple Errors

### Step 1: Verify Target Membership
1. Select **PadelScore** project (blue icon) in Navigator
2. Select **PadelScore Watch App** target
3. Go to **Build Phases** tab
4. Expand **Compile Sources**
5. Verify all Swift files are listed:
   - PadelScoreApp.swift
   - ContentView.swift
   - MatchHistoryView.swift
   - Models/Game.swift
   - Models/Set.swift
   - Models/Match.swift
   - Models/ScoreManager.swift
   - Views/ScoreButtonView.swift

### Step 2: Add Missing Files
If files are missing from Compile Sources:
1. Click **+** button in Compile Sources
2. Add missing Swift files
3. Or: Select file → File Inspector → Check target membership

### Step 3: Check Build Settings
1. Select **PadelScore Watch App** target
2. Go to **Build Settings**
3. Search for "Swift Language Version"
4. Set to **Swift 5** or latest
5. Search for "Deployment Target"
6. Set **watchOS Deployment Target** to **9.0** or higher

### Step 4: Clean and Rebuild
1. **Product → Clean Build Folder** (Cmd+Shift+K)
2. Close Xcode
3. Delete `DerivedData` folder:
   - `~/Library/Developer/Xcode/DerivedData/PadelScore-*`
4. Reopen Xcode
5. **Product → Build** (Cmd+B)

## Quick Checklist

- [ ] All Swift files are in the project navigator
- [ ] All files have target membership checked
- [ ] Build target is set to watchOS (not iOS)
- [ ] Deployment target is watchOS 9.0+
- [ ] No duplicate file references
- [ ] All imports are correct (SwiftUI, Foundation, WatchKit)

## If Issues Persist

1. **Create a new watchOS project** and copy files manually
2. **Check Xcode version** - ensure it's Xcode 14.0 or later
3. **Verify watchOS SDK** is installed:
   - Xcode → Settings → Platforms
   - Install watchOS SDK if missing

## File Structure Verification

Your project should look like this in Xcode:

```
PadelScore (Project)
└── PadelScore Watch App (Target)
    ├── PadelScoreApp.swift
    ├── ContentView.swift
    ├── MatchHistoryView.swift
    ├── Models/
    │   ├── Game.swift
    │   ├── Set.swift
    │   ├── Match.swift
    │   └── ScoreManager.swift
    ├── Views/
    │   └── ScoreButtonView.swift
    └── Assets.xcassets/
```

All files should have a checkmark next to the watchOS target in File Inspector.




