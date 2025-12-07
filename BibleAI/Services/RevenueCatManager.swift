//
//  RevenueCatManager.swift
//  BibleAI
//
//  Manages subscriptions via RevenueCat
//

import Foundation
import RevenueCat

@MainActor
class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()

    @Published var isPremium: Bool = false
    @Published var offerings: Offerings?

    // Free tier limits
    let freeQuestionsPerDay = 5
    private let dailyQuestionCountKey = "daily_question_count"
    private let lastQuestionDateKey = "last_question_date"

    private init() {
        configureRevenueCat()
    }

    // MARK: - Configuration

    private func configureRevenueCat() {
        // Configure RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: RevenueCatConfig.publicSDKKey)

        // Set user attributes if needed
        // Purchases.shared.setAttributes(["user_id": "..."])

        Task {
            await checkSubscriptionStatus()
            await loadOfferings()
        }
    }

    // MARK: - Subscription Status

    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPremium = customerInfo.entitlements[RevenueCatConfig.premiumEntitlementID]?.isActive == true

            print(isPremium ? "✅ User is premium" : "ℹ️ User is free tier")
        } catch {
            print("❌ Failed to check subscription: \(error)")
            isPremium = false
        }
    }

    // MARK: - Offerings

    func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
            print("✅ Loaded offerings: \(offerings?.current?.availablePackages.count ?? 0) packages")
        } catch {
            print("❌ Failed to load offerings: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            await checkSubscriptionStatus()
            return result.customerInfo.entitlements[RevenueCatConfig.premiumEntitlementID]?.isActive == true
        } catch {
            print("❌ Purchase failed: \(error)")
            throw error
        }
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            isPremium = customerInfo.entitlements[RevenueCatConfig.premiumEntitlementID]?.isActive == true
            print(isPremium ? "✅ Purchases restored - Premium active" : "ℹ️ No active subscriptions found")
        } catch {
            print("❌ Restore failed: \(error)")
            throw error
        }
    }

    // MARK: - Free Tier Limits

    func canAskQuestion() -> Bool {
        // Premium users have unlimited questions
        if isPremium {
            return true
        }

        // Free users are limited
        resetDailyCountIfNeeded()
        let count = UserDefaults.standard.integer(forKey: dailyQuestionCountKey)
        return count < freeQuestionsPerDay
    }

    func incrementQuestionCount() {
        resetDailyCountIfNeeded()
        let count = UserDefaults.standard.integer(forKey: dailyQuestionCountKey)
        UserDefaults.standard.set(count + 1, forKey: dailyQuestionCountKey)
    }

    func getRemainingQuestions() -> Int {
        if isPremium {
            return Int.max // Unlimited
        }

        resetDailyCountIfNeeded()
        let count = UserDefaults.standard.integer(forKey: dailyQuestionCountKey)
        return max(0, freeQuestionsPerDay - count)
    }

    private func resetDailyCountIfNeeded() {
        let lastDate = UserDefaults.standard.object(forKey: lastQuestionDateKey) as? Date ?? Date.distantPast
        let calendar = Calendar.current

        if !calendar.isDateInToday(lastDate) {
            UserDefaults.standard.set(0, forKey: dailyQuestionCountKey)
            UserDefaults.standard.set(Date(), forKey: lastQuestionDateKey)
        }
    }

    // MARK: - Offerings Helper

    var monthlyPackage: Package? {
        offerings?.current?.availablePackages.first { package in
            package.storeProduct.productIdentifier == RevenueCatConfig.monthlyProductID
        }
    }

    var yearlyPackage: Package? {
        offerings?.current?.availablePackages.first { package in
            package.storeProduct.productIdentifier == RevenueCatConfig.yearlyProductID
        }
    }
}
