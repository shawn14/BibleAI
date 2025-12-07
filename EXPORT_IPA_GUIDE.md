# How to Export .ipa File for Transporter

## Step 1: Open Project in Xcode

```bash
cd /Users/shawncarpenter/Desktop/BibleAI
open BibleAI.xcodeproj
```

## Step 2: Configure Code Signing

1. Click on **BibleAI** project in left sidebar (blue icon)
2. Select **BibleAI** target
3. Go to **Signing & Capabilities** tab
4. Check **"Automatically manage signing"**
5. Select your **Team** from dropdown (must have Apple Developer account)
6. Xcode will automatically create provisioning profiles

## Step 3: Select Device

1. In the top toolbar, click the scheme/device selector (next to Play/Stop buttons)
2. Select **"Any iOS Device (arm64)"** from the dropdown
   - Do NOT select simulator
   - Must be "Generic iOS Device" or "Any iOS Device"

## Step 4: Create Archive

1. In menu bar: **Product > Archive**
2. Wait for build to complete (may take 1-2 minutes)
3. Xcode Organizer window will open automatically

If you get errors:
- Make sure code signing is configured
- Make sure you selected "Any iOS Device" not simulator
- Check that your Apple Developer account is valid

## Step 5: Export .ipa File

In the Organizer window:

1. Select your archive (should be at the top)
2. Click **"Distribute App"** button on right side
3. Choose distribution method:
   - Select **"App Store Connect"**
   - Click **Next**

4. Select distribution options:
   - Choose **"Upload"** if you want Xcode to upload directly
   - OR choose **"Export"** if you want to use Transporter
   - Click **Next**

5. For Transporter, select **"Export"**:
   - Distribution certificate: Automatic
   - Click **Next**

6. App Store distribution options:
   - Keep defaults checked:
     - ✅ Include bitcode (if available)
     - ✅ Upload symbols
     - ✅ Manage version and build number
   - Click **Next**

7. Re-sign options:
   - Keep "Automatically manage signing"
   - Click **Next**

8. Review summary:
   - Click **Export**

9. Choose save location:
   - Desktop or Downloads folder
   - Click **Export**

## Step 6: Find Your .ipa File

After export, you'll have a folder containing:
```
BibleAI [DATE]/
├── BibleAI.ipa          ← This is what you need!
├── DistributionSummary.plist
├── ExportOptions.plist
└── Packaging.log
```

The **BibleAI.ipa** file is what you upload to Transporter.

## Step 7: Upload via Transporter

### Option A: Using Transporter App

1. **Download Transporter** (if you don't have it):
   - Mac App Store: https://apps.apple.com/app/transporter/id1450874784
   - Or search "Transporter" in App Store

2. **Open Transporter**

3. **Sign in** with your Apple ID (same as Developer account)

4. **Add your .ipa**:
   - Click the big **"+"** button
   - OR drag and drop the BibleAI.ipa file into the window

5. **Deliver**:
   - Click **"Deliver"** button
   - Wait for upload (may take 5-30 minutes depending on internet speed)
   - You'll see "Delivered" when complete

### Option B: Using Command Line

```bash
# Navigate to where your .ipa is
cd ~/Desktop/BibleAI\ [DATE]/

# Upload using xcrun altool
xcrun altool --upload-app \
  --type ios \
  --file "BibleAI.ipa" \
  --username "your@appleid.com" \
  --password "@keychain:AC_PASSWORD"
```

Note: You'll need to create an app-specific password:
1. Go to https://appleid.apple.com
2. Sign in
3. Security > App-Specific Passwords
4. Generate password
5. Save it to keychain with name "AC_PASSWORD"

## Step 8: After Upload

1. Go to **App Store Connect**: https://appstoreconnect.apple.com
2. Click on your app (you need to create it first if you haven't)
3. Wait 5-30 minutes for build to process
4. Build will appear under **TestFlight > iOS Builds**
5. Once processed, you can select it for App Store submission

## Troubleshooting

### Error: "No accounts with App Store Connect access"
- Make sure you're signed in to Xcode with correct Apple ID
- Xcode > Settings > Accounts
- Add account if needed

### Error: "Code signing error"
- Go to Signing & Capabilities
- Uncheck "Automatically manage signing"
- Then re-check it
- Select your team again

### Error: "No provisioning profiles found"
- Make sure you have active Apple Developer Program membership
- Check at https://developer.apple.com/account
- Membership must be active ($99/year)

### Error: "Archive doesn't show up in Organizer"
- Make sure you selected "Any iOS Device" not simulator
- Clean build folder: Product > Clean Build Folder
- Try archiving again

### Build takes forever to process in App Store Connect
- Normal processing time: 5-30 minutes
- If more than 1 hour, contact Apple Support

## Quick Reference

**Full workflow:**
1. Xcode > Select "Any iOS Device"
2. Product > Archive
3. Distribute App > App Store Connect > Export
4. Save .ipa file
5. Open Transporter
6. Drag .ipa into Transporter
7. Click Deliver
8. Wait for upload
9. Go to App Store Connect
10. Wait for processing
11. Submit for review

## Next Steps After Upload

Once build is processed in App Store Connect:
1. Fill out app information (if not done)
2. Add screenshots
3. Add app description
4. Select the build
5. Submit for review

Review typically takes 1-3 days.

---

**Need help?** Check the APP_STORE_CHECKLIST.md for full submission guide.
