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

    @Published private(set) var isPremium: Bool = false
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var checkingStatus = false
    @Published private(set) var statusError: String?
    private var statusRequest = 0
    @Published var offerings: Offerings?
    @Published var loadingOfferings = false
    @Published var offeringsError: String?

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

    func checkSubscriptionStatus(forceRefresh: Bool = false) async {
        guard !checkingStatus else { return }
        checkingStatus = true
        statusRequest += 1
        let request = statusRequest
        defer { if request == statusRequest { checkingStatus = false } }
        do {
            let info = try await Purchases.shared.customerInfo(fetchPolicy: forceRefresh ? .fetchCurrent : .default)
            // A purchase or restore may finish while this older read is pending.
            guard request == statusRequest else { return }
            apply(info)
        } catch {
            guard request == statusRequest else { return }
            statusError = "Couldn't check your subscription. Check your connection and try again."
            // A failed refresh is unknown, not evidence that existing access was removed.
        }
    }

    private func apply(_ info: CustomerInfo) {
        customerInfo = info
        isPremium = info.entitlements[RevenueCatConfig.premiumEntitlementID]?.isActive == true
        statusError = nil
    }

    private func applyTransaction(_ info: CustomerInfo) {
        statusRequest += 1
        checkingStatus = false
        apply(info)
    }

    var premiumEntitlement: EntitlementInfo? {
        customerInfo?.entitlements[RevenueCatConfig.premiumEntitlementID]
    }

    var subscriptionTitle: String {
        guard customerInfo != nil else {
            return statusError == nil ? "Checking subscription…" : "Status unavailable"
        }
        guard let entitlement = premiumEntitlement else { return "Free plan" }
        guard entitlement.isActive else { return "Premium expired" }
        return entitlement.periodType == .trial ? "Free trial" : "Premium active"
    }

    // MARK: - Offerings

    func loadOfferings() async {
        guard !loadingOfferings else { return }
        loadingOfferings = true
        offeringsError = nil
        defer { loadingOfferings = false }
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            offeringsError = "Subscription plans couldn't be loaded. Check your connection and try again."
        }
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            applyTransaction(result.customerInfo)
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
            applyTransaction(customerInfo)
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
