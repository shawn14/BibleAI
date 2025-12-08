//
//  Config.revenuecat.swift
//  BibleAI
//
//  RevenueCat configuration
//  Get your public SDK key from: https://app.revenuecat.com
//

import Foundation

struct RevenueCatConfig {
    // Public SDK key from RevenueCat dashboard
    // This is NOT the secret API key - use the PUBLIC iOS SDK key
    static let publicSDKKey = "appl_LjNylWCOFmMRUgRNfWRxpnvQVjU"

    // Entitlement ID (must match RevenueCat dashboard)
    static let premiumEntitlementID = "premium"

    // Product IDs (must match App Store Connect)
    static let monthlyProductID = "com.shawncarpenter.bibleai_companion.premium.monthly"
    static let yearlyProductID = "com.shawncarpenter.bibleai_companion.premium.yearly"
}
