# RevenueCat Integration for BibleAI Companion

## Why RevenueCat?

RevenueCat provides:
- ✅ Easier subscription management than native StoreKit
- ✅ Cross-platform support (iOS, Android, web)
- ✅ Analytics and subscription insights
- ✅ Paywalls and onboarding templates
- ✅ Server-side receipt validation
- ✅ Webhooks for subscription events

## Step 1: Add RevenueCat SDK to Xcode

### Using Swift Package Manager (Recommended):

1. Open `BibleAI.xcodeproj` in Xcode
2. File > Add Package Dependencies
3. Enter URL: `https://github.com/RevenueCat/purchases-ios`
4. Select version: Up to Next Major Version (5.0.0)
5. Click Add Package
6. Select "RevenueCat" and "RevenueCatUI" targets
7. Click Add Package

### Manual Installation (Alternative):

```bash
# Add to Package.swift dependencies
.package(url: "https://github.com/RevenueCat/purchases-ios", from: "5.0.0")
```

## Step 2: Get RevenueCat API Keys

You already have RevenueCat configured!

**API Key:** `sk_XzbnmErWkYwIVeEDPSNKRXYPbogtv`
**Profile:** stockalarm

### Get Public SDK Key:

1. Go to https://app.revenuecat.com
2. Select your project (or create "BibleAI Companion")
3. Project Settings > API Keys
4. Copy the **Public SDK Key** for iOS
5. This is what goes in the app (not the secret key!)

## Step 3: Configure Products in RevenueCat Dashboard

1. Go to https://app.revenuecat.com
2. Create new app: "BibleAI Companion"
3. Select iOS platform
4. Enter bundle ID: `com.shawncarpenter.bibleai-companion`
5. Go to Products
6. Click "+ New"

### Monthly Subscription:
- **Product Identifier:** `com.shawncarpenter.bibleai_companion.premium.monthly`
- **Type:** Subscription
- **Duration:** Monthly

### Yearly Subscription:
- **Product Identifier:** `com.shawncarpenter.bibleai_companion.premium.yearly`
- **Type:** Subscription
- **Duration:** Yearly

## Step 4: Create Offering

1. Go to Offerings
2. Create offering: "default"
3. Add both products to the offering
4. Set yearly as "featured" (recommended)

## Step 5: Configure Entitlements

1. Go to Entitlements
2. Create entitlement: "premium"
3. Attach both products to this entitlement

## Step 6: App Implementation

The code I'll create will:
- Initialize RevenueCat on app launch
- Check subscription status
- Show paywall during onboarding
- Handle purchases through RevenueCat
- Show paywall when free limit is reached

## Step 7: Testing

### Test with StoreKit Configuration:
1. Xcode > Edit Scheme
2. Run > Options
3. StoreKit Configuration: Select Configuration.storekit
4. This allows testing without real purchases

### Test with Sandbox:
1. Create sandbox tester account in App Store Connect
2. Sign out of App Store on device
3. Run app and make test purchase
4. Use sandbox credentials when prompted

## RevenueCat Dashboard Features

### After Integration:

- **Dashboard:** See active subscriptions, revenue, churn
- **Charts:** MRR, trial conversions, cancellations
- **Customer Lookup:** Search by user ID or email
- **Experiments:** A/B test pricing and paywalls
- **Integrations:** Connect to analytics tools

## Migration from StoreKit

We need to:
1. ✅ Keep Product IDs the same
2. ✅ Replace SubscriptionManager with RevenueCat SDK
3. ✅ Use RevenueCat's paywall UI components
4. ✅ Check entitlements instead of local subscription status

## Next Steps

1. Add SDK to Xcode (you'll do this)
2. Get public SDK key from RevenueCat dashboard
3. I'll update the code to use RevenueCat
4. Create onboarding flow with paywall
5. Test in simulator

---

**Ready?** Once you've added the RevenueCat SDK to Xcode, let me know and I'll update all the code!
