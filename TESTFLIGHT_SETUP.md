# TestFlight Setup Guide for Apple Watch App

## Prerequisites

1. **Apple Developer Account** (paid membership required - $99/year)
2. **App Store Connect** access
3. **Xcode** with your Apple ID signed in

## Step 1: Configure App in App Store Connect

### 1.1 Create App Record
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **"My Apps"** → **"+"** → **"New App"**
3. Fill in:
   - **Platform**: iOS (watchOS apps are created as iOS apps)
   - **Name**: PadelScore (or your preferred name)
   - **Primary Language**: Your language
   - **Bundle ID**: Select the one matching your Xcode project (e.g., `com.yourname.PadelScore.watchkitapp`)
   - **SKU**: Unique identifier (e.g., `padel-score-watch-001`)
   - **User Access**: Full Access
4. Click **"Create"**

### 1.2 Configure App Information
1. In your app's page, go to **"App Information"**
2. Fill in:
   - **Category**: Sports (or appropriate category)
   - **Privacy Policy URL**: (Required for TestFlight - can be a placeholder initially)
3. Save changes

## Step 2: Configure Xcode Project

### 2.1 Update Bundle Identifier
1. Open your project in Xcode
2. Select **PadelScore** project → **PadelScore Watch App** target
3. Go to **General** tab
4. Under **Identity**, ensure **Bundle Identifier** matches what you created in App Store Connect
5. Set **Version** to `1.0` (or your starting version)
6. Set **Build** to `1` (or increment as needed)

### 2.2 Configure Signing
1. Still in **PadelScore Watch App** target
2. Go to **Signing & Capabilities** tab
3. Check **"Automatically manage signing"**
4. Select your **Team** (Apple Developer account)
5. Xcode will create/update provisioning profiles automatically

### 2.3 Set Deployment Target
1. In **Build Settings** tab
2. Search for **"iOS Deployment Target"** or **"watchOS Deployment Target"**
3. Set to **watchOS 9.0** (or your minimum supported version)

## Step 3: Archive the App

### 3.1 Select Generic iOS Device
1. In Xcode, click the device selector (next to Play button)
2. Select **"Any iOS Device"** or **"Generic iOS Device"**
   - Note: For watchOS apps, you select iOS device even though it's a watch app

### 3.2 Create Archive
1. Go to **Product → Archive** (or `Cmd+B` then Archive)
2. Wait for the archive to build (may take a few minutes)
3. The **Organizer** window will open automatically

### 3.3 Verify Archive
1. In Organizer, you should see your archive
2. Click **"Distribute App"**
3. Select **"App Store Connect"**
4. Click **"Next"**

## Step 4: Upload to App Store Connect

### 4.1 Distribution Options
1. Select **"Upload"**
2. Click **"Next"**
3. Review the app information
4. Click **"Upload"**
5. Wait for upload to complete (may take 5-15 minutes)

### 4.2 Processing
- App Store Connect will process your build (usually 10-30 minutes)
- You'll receive an email when processing is complete
- Check status in App Store Connect → TestFlight → Builds

## Step 5: Configure TestFlight

### 5.1 Add Build to TestFlight
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app → **TestFlight** tab
3. Under **"iOS Builds"**, you should see your uploaded build
4. Once processing completes, click **"Add to TestFlight"** (if needed)

### 5.2 Add Test Information
1. In TestFlight, go to **"Test Information"**
2. Fill in:
   - **What to Test**: Brief description of what testers should focus on
   - **Description**: More detailed testing instructions
   - **Feedback Email**: Your email for tester feedback
3. Save

### 5.3 Add Internal Testers
1. Go to **"Internal Testing"** section
2. Click **"+"** to add testers
3. Add email addresses of team members (up to 100 internal testers)
4. Select the build to test
5. Click **"Start Testing"**

### 5.4 Add External Testers (Optional)
1. Go to **"External Testing"** section
2. Click **"+"** to create a group
3. Name your group (e.g., "Beta Testers")
4. Add testers (up to 10,000 external testers)
5. Select the build
6. Submit for Beta App Review (required for external testing)
   - This review usually takes 24-48 hours
   - Provide testing notes and demo account if needed

## Step 6: Testers Install App

### 6.1 For Testers
1. Testers receive an email invitation
2. They need to install **TestFlight** app on their iPhone
3. Open the TestFlight app
4. Accept the invitation
5. Install the app
6. The app will sync to their paired Apple Watch automatically

## Important Notes for watchOS Apps

### Bundle Identifier
- watchOS apps use a specific bundle ID format
- Usually: `com.yourname.AppName.watchkitapp`
- Make sure this matches in both Xcode and App Store Connect

### App Store Connect
- watchOS apps appear under "iOS Apps" in App Store Connect
- The watch app is associated with an iOS app record
- For standalone watchOS apps, you still create an iOS app record

### Testing Requirements
- Testers need an Apple Watch paired with iPhone
- TestFlight app must be installed on iPhone
- watchOS version must meet minimum deployment target

## Troubleshooting

### "No suitable application records were found"
- Ensure Bundle ID in Xcode matches App Store Connect exactly
- Wait a few minutes after creating app record in App Store Connect

### Archive option is grayed out
- Select "Any iOS Device" instead of simulator
- Clean build folder: Product → Clean Build Folder

### Upload fails
- Check internet connection
- Verify signing certificates are valid
- Ensure you have proper permissions in App Store Connect

### Build processing takes too long
- Normal processing time is 10-30 minutes
- Check App Store Connect status page for delays
- Verify build doesn't have errors

### Testers can't install
- Ensure TestFlight app is installed on iPhone
- Check that Apple Watch is paired
- Verify watchOS version meets requirements
- Check that build is approved for testing

## Quick Checklist

- [ ] Apple Developer account active ($99/year)
- [ ] App created in App Store Connect
- [ ] Bundle ID matches in Xcode and App Store Connect
- [ ] Code signing configured correctly
- [ ] App archived successfully
- [ ] Build uploaded to App Store Connect
- [ ] Build processing completed
- [ ] Testers added to TestFlight
- [ ] Test information filled in
- [ ] Testing started

## Next Steps After TestFlight

1. **Collect Feedback**: Monitor tester feedback and crash reports
2. **Iterate**: Fix bugs and upload new builds
3. **Prepare for Release**: When ready, submit for App Store review
4. **Update Version**: Increment version number for each new build

## Version Management

- **Version**: Major.minor (e.g., 1.0, 1.1, 2.0)
- **Build**: Increment for each upload (e.g., 1, 2, 3)
- Each TestFlight build needs a unique build number
- Version can stay the same, but build must increment



