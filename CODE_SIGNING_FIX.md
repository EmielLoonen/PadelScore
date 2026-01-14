# Fixing Code Signing Error

## Error: "Embedded binary is not signed with the same certificate as the parent app"

This error occurs when there are multiple targets with mismatched code signing settings, or when Xcode thinks there's a parent-child app relationship that shouldn't exist.

## Solution 1: Standalone watchOS App (Recommended)

Since you're building a **standalone watchOS app** (no iPhone companion), follow these steps:

### Step 1: Verify Target Structure
1. Open your project in Xcode
2. Select the **PadelScore** project (blue icon) in the Navigator
3. In the **TARGETS** list, you should see:
   - ✅ **PadelScore Watch App** (this is what you need)
   - ❌ If you see **PadelScore** (iOS app) or **PadelScore WatchKit Extension**, delete them

### Step 2: Remove Unnecessary Targets (if they exist)
If you see an iOS app target:
1. Select the iOS app target
2. Press **Delete** key
3. Choose **Delete** when prompted
4. This removes the parent app that's causing the conflict

### Step 3: Configure Code Signing for watchOS App
1. Select **PadelScore Watch App** target
2. Go to **Signing & Capabilities** tab
3. Check **"Automatically manage signing"**
4. Select your **Team** from the dropdown
5. Xcode will automatically generate a Bundle Identifier (e.g., `com.yourname.PadelScore.watchkitapp`)

### Step 4: Verify Build Settings
1. Still in **PadelScore Watch App** target
2. Go to **Build Settings** tab
3. Search for **"Code Signing Identity"**
4. Set to **"Apple Development"** (or your distribution certificate)
5. Search for **"Provisioning Profile"**
6. Should be set to **"Automatic"** if auto-signing is enabled

### Step 5: Clean and Rebuild
1. **Product → Clean Build Folder** (Cmd+Shift+K)
2. **Product → Build** (Cmd+B)

## Solution 2: If You Need Both iOS and watchOS Apps

If you actually want both an iOS app and watchOS app:

### Step 1: Configure iOS App Signing
1. Select **PadelScore** (iOS) target
2. **Signing & Capabilities** tab
3. Set **Team** and enable **"Automatically manage signing"**
4. Note the **Bundle Identifier** (e.g., `com.yourname.PadelScore`)

### Step 2: Configure watchOS App Signing
1. Select **PadelScore Watch App** target
2. **Signing & Capabilities** tab
3. Set **Team** (same as iOS app)
4. Enable **"Automatically manage signing"**
5. Bundle Identifier should be: `com.yourname.PadelScore.watchkitapp`

### Step 3: Ensure Same Team
- Both targets must use the **same Team**
- Both should have **"Automatically manage signing"** enabled

## Solution 3: Manual Code Signing (Advanced)

If automatic signing doesn't work:

1. **PadelScore Watch App** target → **Signing & Capabilities**
2. Uncheck **"Automatically manage signing"**
3. Select **Provisioning Profile** manually
4. Choose a profile that matches your Bundle Identifier
5. Select **Code Signing Identity** (Development or Distribution)

## Quick Checklist

- [ ] Only one target exists (watchOS app) OR both targets use same Team
- [ ] "Automatically manage signing" is enabled
- [ ] Team is selected for the watchOS target
- [ ] No duplicate or conflicting provisioning profiles
- [ ] Build folder is cleaned

## Common Causes

1. **Multiple targets with different teams** - Ensure all targets use the same Team
2. **Missing Team selection** - Select your Apple Developer team
3. **Stale provisioning profiles** - Let Xcode regenerate them automatically
4. **Wrong target selected** - Make sure you're building the watchOS app target

## If Error Persists

1. Close Xcode
2. Delete `~/Library/Developer/Xcode/DerivedData/PadelScore-*`
3. Delete `~/Library/Developer/Xcode/Archives` (if exists)
4. Reopen Xcode
5. Clean build folder and rebuild

## For Standalone watchOS App (Your Case)

Since you're building a **standalone watchOS app**:
- You should **NOT** have an iOS app target
- Only the **PadelScore Watch App** target should exist
- Code signing should be straightforward with just the watchOS target

If Xcode created an iOS app target automatically, delete it - you don't need it for a standalone watchOS app.




