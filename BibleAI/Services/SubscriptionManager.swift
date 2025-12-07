//
//  SubscriptionManager.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation
import StoreKit

enum SubscriptionStatus {
    case free
    case premium
}

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var products: [Product] = []

    // Product IDs - These must match App Store Connect
    private let monthlyProductID = "com.shawncarpenter.bibleai.premium.monthly"
    private let yearlyProductID = "com.shawncarpenter.bibleai.premium.yearly"

    // Free tier limits
    let freeQuestionsPerDay = 5
    private let dailyQuestionCountKey = "daily_question_count"
    private let lastQuestionDateKey = "last_question_date"

    private init() {
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    // MARK: - Product Loading

    func loadProducts() async {
        do {
            let productIDs = [monthlyProductID, yearlyProductID]
            products = try await Product.products(for: productIDs)
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }

    // MARK: - Subscription Status

    func updateSubscriptionStatus() async {
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == monthlyProductID || transaction.productID == yearlyProductID {
                    subscriptionStatus = .premium
                    print("✅ User has premium subscription")
                    return
                }
            }
        }

        subscriptionStatus = .free
        print("ℹ️ User is on free tier")
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                // Transaction is verified, grant access
                await transaction.finish()
                await updateSubscriptionStatus()
                return true
            case .unverified:
                // Transaction failed verification
                return false
            }
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }

    // MARK: - Free Tier Limits

    func canAskQuestion() -> Bool {
        // Premium users have unlimited questions
        if subscriptionStatus == .premium {
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
        if subscriptionStatus == .premium {
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

    // MARK: - Pricing Display

    var monthlyProduct: Product? {
        products.first { $0.id == monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == yearlyProductID }
    }

    var monthlySavings: String? {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else {
            return nil
        }

        let monthlyYearlyCost = monthly.price * 12
        let savings = monthlyYearlyCost - yearly.price
        let savingsDouble = NSDecimalNumber(decimal: savings).doubleValue
        let monthlyYearlyCostDouble = NSDecimalNumber(decimal: monthlyYearlyCost).doubleValue
        let percentage = Int((savingsDouble / monthlyYearlyCostDouble) * 100)

        return "\(percentage)%"
    }
}
