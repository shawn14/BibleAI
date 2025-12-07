# Fastlane Setup Guide for BibleAI Companion

## What is Fastlane?

Fastlane automates tedious tasks like building, signing, and uploading your app to App Store Connect.

## Initial Setup

### 1. Install Dependencies (Already Done ✅)
```bash
# Fastlane is already installed at /opt/homebrew/bin/fastlane
fastlane --version
```

### 2. Update Fastlane (Recommended)
```bash
fastlane update_fastlane
```

## Available Lanes

### Setup App in App Store Connect
```bash
cd /Users/shawncarpenter/Desktop/BibleAI
fastlane setup_app_store
```

This will:
- Create the app listing in App Store Connect
- Set up basic app metadata
- **Note**: IAP products must be created manually (see below)

### Upload to TestFlight (Beta Testing)
```bash
fastlane beta
```

This will:
- Increment build number automatically
- Build the app
- Upload to TestFlight
- Send to internal testers

### Upload to App Store (Production)
```bash
fastlane release
```

This will:
- Increment build number
- Build the app
- Upload to App Store Connect
- Ready for submission to review

## Creating IAP Products

Unfortunately, Fastlane doesn't support creating IAP products automatically. You need to create them manually in App Store Connect.

### Option 1: Manual Creation (Recommended)

1. Go to https://appstoreconnect.apple.com
2. Select **BibleAI Companion**
3. Click **Features** → **In-App Purchases**
4. Click **+** to create new subscription

#### Premium Monthly Subscription:
- **Product ID**: `com.shawncarpenter.bibleai-companion.premium.monthly`
- **Reference Name**: Premium Monthly
- **Type**: Auto-Renewable Subscription
- **Subscription Group**: Create new group called "Premium"
- **Subscription Duration**: 1 Month
- **Price**: $6.99 USD (Tier 70)
- **Subscription Localizations** (English US):
  - **Display Name**: Premium Monthly
  - **Description**: Unlimited AI Bible study questions and features

#### Premium Yearly Subscription:
- **Product ID**: `com.shawncarpenter.bibleai-companion.premium.yearly`
- **Reference Name**: Premium Yearly
- **Type**: Auto-Renewable Subscription
- **Subscription Group**: Same group as monthly (Premium)
- **Subscription Duration**: 1 Year
- **Price**: $49.99 USD (Tier 500)
- **Subscription Localizations** (English US):
  - **Display Name**: Premium Yearly
  - **Description**: Unlimited AI Bible study questions and features - Save 40%!

### Option 2: Using App Store Connect API

For advanced users, you can use the App Store Connect API directly:

1. Create an API Key at https://appstoreconnect.apple.com/access/api
2. Download the .p8 key file
3. Use the API to create products programmatically

See: https://developer.apple.com/documentation/appstoreconnectapi

## Before Running Fastlane

### 1. Set Your Team ID

Edit `fastlane/Appfile` and add your Team ID:

```ruby
team_id("YOUR_TEAM_ID_HERE")
```

Find your Team ID at: https://developer.apple.com/account

### 2. Generate App-Specific Password

For automated uploads, you need an app-specific password:

1. Go to https://appleid.apple.com
2. Sign in
3. Security → App-Specific Passwords
4. Generate password
5. Save it securely

When Fastlane prompts for password, use this app-specific password.

### 3. Set Environment Variables (Optional but Recommended)

```bash
export FASTLANE_USER="shawncarpenter@mac.com"
export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="your-app-specific-password"
```

## Common Commands

### Check Fastlane Status
```bash
fastlane fastlane-credentials check
```

### View App Info
```bash
fastlane run app_store_connect_api_key
```

### Build Only (No Upload)
```bash
xcodebuild -project BibleAI.xcodeproj \
  -scheme BibleAI \
  -configuration Release \
  -archivePath ./build/BibleAI.xcarchive \
  archive
```

### Export IPA
```bash
xcodebuild -exportArchive \
  -archivePath ./build/BibleAI.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist fastlane/ExportOptions.plist
```

## Troubleshooting

### "Could not find app" Error
Make sure the app exists in App Store Connect first:
```bash
fastlane setup_app_store
```

### Code Signing Issues
Make sure you're signed into Xcode with your Apple ID:
1. Xcode → Settings → Accounts
2. Add your Apple ID
3. Download certificates

### Build Fails
Clean and retry:
```bash
xcodebuild clean -project BibleAI.xcodeproj -scheme BibleAI
fastlane beta
```

## Full Workflow: First Release

```bash
# 1. Set up app in App Store Connect
fastlane setup_app_store

# 2. Manually create IAP products (see above)

# 3. Upload first beta to TestFlight
fastlane beta

# 4. Test on TestFlight

# 5. When ready, upload to App Store
fastlane release

# 6. Go to App Store Connect and submit for review
```

## Continuous Delivery

For automated releases on every commit:

1. Set up GitHub Actions
2. Store secrets in repository settings
3. Use fastlane in CI/CD pipeline

Example `.github/workflows/release.yml`:
```yaml
name: Release
on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Dependencies
        run: bundle install
      - name: Release to App Store
        env:
          FASTLANE_USER: ${{ secrets.FASTLANE_USER }}
          FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
        run: fastlane release
```

## Resources

- Fastlane Docs: https://docs.fastlane.tools
- App Store Connect: https://appstoreconnect.apple.com
- Apple Developer: https://developer.apple.com

## Quick Reference

| Command | Description |
|---------|-------------|
| `fastlane setup_app_store` | Create app in ASC |
| `fastlane beta` | Upload to TestFlight |
| `fastlane release` | Upload to App Store |
| `fastlane screenshots` | Generate screenshots |
| `fastlane upload_metadata` | Update app metadata |

---

**Need Help?**
Check `fastlane action [action_name]` for detailed help on any action.
