# BibleAI - App Store Submission Checklist

## ✅ Current Status
- **Bundle ID**: com.shawncarpenter.bibleai
- **Version**: 1.0
- **Build**: 1
- **Minimum iOS**: 17.0

## 📋 Pre-Submission Requirements

### 1. Apple Developer Account
- [ ] Have active Apple Developer Program membership ($99/year)
- [ ] Account: https://developer.apple.com

### 2. App Icon
- [ ] Create 1024x1024px app icon (PNG, no transparency)
- [ ] Add to Assets.xcassets/AppIcon

### 3. Privacy & Permissions
The app uses:
- **Internet Access**: For OpenAI API and Bible API
- **No tracking or analytics**

Required privacy descriptions (add to project settings):
- [ ] NSUserTrackingUsageDescription: "We do not track you"
- [ ] Privacy Manifest (if needed for iOS 17)

### 4. App Store Connect Setup
- [ ] Create app listing at https://appstoreconnect.apple.com
- [ ] App Information:
  - Name: BibleAI
  - Subtitle: AI-Powered Bible Study
  - Category: Reference (Primary), Education (Secondary)
  - Age Rating: 4+

### 5. Screenshots Required
Capture screenshots for:
- [ ] 6.7" Display (iPhone 15 Pro Max) - at least 1
- [ ] 6.5" Display (iPhone 15 Plus) - at least 1
- [ ] 5.5" Display (optional but recommended)

Suggested screenshots:
1. Home screen with Verse of the Day
2. AI chat conversation
3. Bible reader with highlighted verse
4. Reading plans list
5. Highlights tab

### 6. App Description

**Short Description** (30 chars):
"AI-powered Bible companion"

**Full Description** (max 4000 chars):
```
BibleAI - Your AI-Powered Bible Study Companion

Experience the Bible like never before with BibleAI, an intelligent companion that helps you understand, explore, and grow in your faith.

🤖 AI CHAT ASSISTANT
• Ask questions about any verse or biblical concept
• Get historical context and original language insights
• Explore multiple Christian perspectives
• Receive personalized spiritual guidance
• Cross-references and related passages

📖 COMPLETE BIBLE READER
• Full KJV Bible with all 66 books
• Adjustable font size for comfortable reading
• Search any verse instantly
• Clean, distraction-free reading experience

✨ HIGHLIGHTS & NOTES
• Highlight verses in 5 beautiful colors
• Add personal notes and reflections
• Search your highlights by reference or content
• Keep track of meaningful passages

📚 READING PLANS
• Curated reading plans to guide your journey
• Gospel Tour, Psalms in a Month, and more
• Track your progress with visual indicators
• Jump directly from plan to reading

🌅 DAILY INSPIRATION
• Verse of the Day on your home screen
• Quick verse suggestions to get started
• Continuous conversation with AI assistant

PRIVACY FIRST
• No tracking or analytics
• All data stored locally on your device
• Secure API key management
• Zero data collection

FEATURES:
✓ Multi-perspective biblical analysis
✓ Historical and theological context
✓ Greek/Hebrew word meanings
✓ Conversation history management
✓ Persistent highlights and notes
✓ Multiple reading plans
✓ Fast verse search
✓ Offline reading (Bible text)
✓ Beautiful, modern interface

Whether you're a lifelong believer or just beginning your spiritual journey, BibleAI provides the tools and insights you need for meaningful Bible study.

Requires OpenAI API key for AI chat features.
```

**Keywords** (max 100 chars):
bible,study,ai,chat,scripture,theology,christian,devotional,faith,kjv

**Support URL**: (you'll need to create this)
**Privacy Policy URL**: (you'll need to create this)

### 7. Code Signing
- [ ] Log into Xcode with Apple ID (Xcode > Settings > Accounts)
- [ ] Select development team in project settings
- [ ] Automatic code signing recommended for first submission

### 8. Build Configuration
- [ ] Set build configuration to Release (not Debug)
- [ ] Archive the app (Product > Archive in Xcode)
- [ ] Validate archive before upload
- [ ] Upload to App Store Connect

### 9. API Key Consideration
⚠️ **IMPORTANT**: The app requires users to provide their own OpenAI API key.

Make sure to:
- [ ] Mention this clearly in App Description
- [ ] Add instructions in app for getting API key
- [ ] Consider adding a "How to Get API Key" help screen

### 10. App Review Information
For App Review team:
- [ ] Provide test OpenAI API key in review notes
- [ ] Explain that users need their own API key
- [ ] Demo username/password if needed (not applicable here)

### 11. Legal Requirements
- [ ] Create Privacy Policy (required)
  - State that no user data is collected
  - Explain API key storage (local only)
  - Mention OpenAI API usage

- [ ] Create Terms of Service (optional but recommended)

## 🚀 Build Steps

### Option A: Using Xcode GUI (Recommended for first time)

1. **Open Xcode**
   ```bash
   open BibleAI.xcodeproj
   ```

2. **Select Scheme**
   - Click scheme selector (top left)
   - Select "Any iOS Device (arm64)"

3. **Archive**
   - Product > Archive
   - Wait for build to complete
   - Organizer window will open

4. **Validate**
   - Select archive
   - Click "Validate App"
   - Fix any issues

5. **Distribute**
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Follow wizard steps
   - Upload

### Option B: Using Command Line

```bash
# Set your team ID (find at developer.apple.com)
TEAM_ID="YOUR_TEAM_ID"

# Archive
xcodebuild -project BibleAI.xcodeproj \
  -scheme BibleAI \
  -configuration Release \
  -archivePath ./build/BibleAI.xcarchive \
  archive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath ./build/BibleAI.xcarchive \
  -exportOptionsPlist exportOptions.plist \
  -exportPath ./build

# Upload (requires Application Loader or xcrun altool)
xcrun altool --upload-app \
  -f ./build/BibleAI.ipa \
  -t ios \
  -u your@apple.id \
  -p @keychain:AC_PASSWORD
```

## 📱 Post-Upload

After uploading:
1. Go to App Store Connect
2. Wait for build to process (5-30 minutes)
3. Fill out app information
4. Add screenshots
5. Submit for review
6. Wait for review (typically 1-3 days)

## ⚠️ Common Rejection Reasons to Avoid

1. **Missing Privacy Policy** - Must have one
2. **API Key Required** - Clearly state in description
3. **Crashes on Launch** - Test thoroughly
4. **Misleading Description** - Be accurate about features
5. **Missing Usage Descriptions** - Add all required privacy strings

## 📞 Support

If you get rejected:
- Read rejection reason carefully
- Use Resolution Center to respond
- Fix issues and resubmit
- Usually resolved within 24-48 hours

## 🎯 Next Steps

1. ✅ Review this checklist
2. Create app icon
3. Set up Apple Developer account (if not done)
4. Create App Store Connect listing
5. Generate screenshots
6. Write privacy policy
7. Configure code signing
8. Create archive
9. Upload to App Store Connect
10. Submit for review

---

**Questions?**
- Apple Developer Forums: https://developer.apple.com/forums/
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
