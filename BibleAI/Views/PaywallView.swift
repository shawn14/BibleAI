import SwiftUI
import RevenueCat
import UserNotifications

// MARK: - Shared look (white page, serif headline, black capsule button)

enum ScrollStyle {
    static let ink = Color.black
    static let paper = Color.white
    static let muted = Color(white: 0.45)
    static let hairline = Color.black.opacity(0.12)
    static func headline(_ size: CGFloat = 30) -> Font { .system(size: size, weight: .regular, design: .serif) }
}

struct BrandMark: View {
    var body: some View {
        Image(systemName: "book.closed")
            .font(.system(size: 26, weight: .light))
            .foregroundStyle(ScrollStyle.ink)
            .accessibilityHidden(true)
    }
}

struct PrimaryCapsuleButton: View {
    let title: String
    var identifier: String = "onboarding.continue"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(ScrollStyle.ink, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}

/// Terms | Privacy | Already Subscribed? | Restore Purchases
struct PaywallFooter: View {
    @EnvironmentObject private var subscriptions: RevenueCatManager
    var onRestored: () -> Void = {}
    @State private var message: String?

    var body: some View {
        HStack(spacing: 6) {
            Link("Terms", destination: URL(string: "https://www.bibleaicompanion.com/terms")!)
            Text("|")
            Link("Privacy", destination: URL(string: "https://www.bibleaicompanion.com/privacy")!)
            Text("|")
            Button("Restore Purchases") {
                Task {
                    do {
                        try await subscriptions.restorePurchases()
                        if subscriptions.isPremium { onRestored() } else { message = "No active subscription was found." }
                    } catch { message = "Purchases couldn't be restored. Please try again." }
                }
            }
        }
        .font(.caption2)
        .foregroundStyle(ScrollStyle.muted)
        .tint(ScrollStyle.muted)
        .alert("Restore Purchases", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") { message = nil }
        } message: { Text(message ?? "") }
    }
}

// MARK: - Trial facts come only from the App Store product and RevenueCat eligibility

enum TrialMath {
    /// Free-trial length in days for a package's introductory offer, or nil when it has none.
    static func freeTrialDays(_ package: Package) -> Int? {
        guard let intro = package.storeProduct.introductoryDiscount, intro.paymentMode == .freeTrial else { return nil }
        let period = intro.subscriptionPeriod
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        default: return nil
        }
    }

    /// Product id → trial days, only for packages the App Store says this user is eligible for.
    @MainActor
    static func eligibleTrials(_ packages: [Package]) async -> [String: Int] {
        guard !packages.isEmpty else { return [:] }
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(packages: packages)
        var trials: [String: Int] = [:]
        for package in packages where eligibility[package]?.status == .eligible {
            if let days = freeTrialDays(package) { trials[package.storeProduct.productIdentifier] = days }
        }
        return trials
    }
}

enum TrialReminder {
    static let daysBeforeKey = "trialReminder.daysBefore"

    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Schedules the promised heads-up. Called only after a purchase that started a free trial.
    static func schedule(trialDays: Int, daysBefore: Int) {
        let offset = trialDays - daysBefore
        guard offset > 0,
              let fire = Calendar.current.date(byAdding: .day, value: offset, to: .now) else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your free trial ends in \(daysBefore) days"
        content.body = "Keep going deeper with BibleAI Premium, or cancel in Settings before it renews. No pressure either way."
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let request = UNNotificationRequest(identifier: "bibleai.trial-reminder", content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Plan picker (last paywall step, also used standalone)

struct PlanPickerScreen: View {
    @EnvironmentObject private var subscriptions: RevenueCatManager
    let trials: [String: Int]
    var reminderDaysBefore: Int?
    let onClose: () -> Void
    let onPurchased: () -> Void

    @State private var annualSelected = true
    @State private var purchasing = false
    @State private var message: String?

    private var selected: Package? {
        annualSelected ? (subscriptions.yearlyPackage ?? subscriptions.monthlyPackage)
                       : (subscriptions.monthlyPackage ?? subscriptions.yearlyPackage)
    }
    private func trial(_ package: Package?) -> Int? {
        package.flatMap { trials[$0.storeProduct.productIdentifier] }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                BrandMark()
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark").font(.body.weight(.medium))
                            .foregroundStyle(ScrollStyle.muted).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("paywall.close")
                    Spacer()
                }
            }
            .padding(.horizontal, 12)

            ScrollView {
                VStack(spacing: 14) {
                    Text(trial(subscriptions.yearlyPackage).map { "Try BibleAI Premium free for \($0) days" }
                         ?? "Go deeper with BibleAI Premium")
                        .font(ScrollStyle.headline(30))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Unlimited verse studies, word meanings, context and more.")
                        .font(.footnote).foregroundStyle(ScrollStyle.muted)
                        .multilineTextAlignment(.center)

                    if subscriptions.isPremium {
                        Label("Premium is active", systemImage: "checkmark.circle.fill").padding(.top, 24)
                    } else if subscriptions.loadingOfferings {
                        ProgressView("Loading plans…").padding(.top, 40)
                    } else if subscriptions.yearlyPackage == nil && subscriptions.monthlyPackage == nil {
                        VStack(spacing: 12) {
                            Text(subscriptions.offeringsError ?? "Plans are currently unavailable.")
                                .font(.callout).foregroundStyle(ScrollStyle.muted).multilineTextAlignment(.center)
                            Button("Try Again") { Task { await subscriptions.loadOfferings() } }
                        }.padding(.top, 40)
                    } else {
                        VStack(spacing: 12) {
                            if let annual = subscriptions.yearlyPackage {
                                planRow(annual, title: "Yearly", isOn: annualSelected,
                                        badge: trial(annual).map { "\($0)-DAY FREE TRIAL" } ?? "BEST VALUE",
                                        detail: annualDetail(annual)) { annualSelected = true }
                            }
                            if let monthly = subscriptions.monthlyPackage {
                                planRow(monthly, title: "Monthly", isOn: !annualSelected || subscriptions.yearlyPackage == nil,
                                        badge: trial(monthly).map { "\($0)-DAY FREE TRIAL" },
                                        detail: "\(monthly.localizedPriceString) / month") { annualSelected = false }
                            }
                        }
                        .padding(.top, 18)
                    }
                }
                .padding(.horizontal, 24).padding(.vertical, 12)
            }

            VStack(spacing: 10) {
                if let days = trial(selected) {
                    Label("No payment due now", systemImage: "checkmark")
                        .font(.footnote.weight(.semibold))
                    PrimaryCapsuleButton(title: "Try for \(zeroPrice(selected!))", identifier: "paywall.purchase") { buy() }
                    Text("\(days) days free, then \(selected!.localizedPriceString)/\(annualSelected ? "year" : "month"). Renews automatically unless canceled at least 24 hours before the period ends. Cancel anytime in Settings.")
                        .font(.caption2).foregroundStyle(ScrollStyle.muted).multilineTextAlignment(.center)
                } else if let selected {
                    PrimaryCapsuleButton(title: "Continue", identifier: "paywall.purchase") { buy() }
                    Text("\(selected.localizedPriceString)/\(annualSelected ? "year" : "month"). Renews automatically unless canceled at least 24 hours before the period ends. Cancel anytime in Settings.")
                        .font(.caption2).foregroundStyle(ScrollStyle.muted).multilineTextAlignment(.center)
                }
                PaywallFooter(onRestored: onPurchased)
            }
            .padding(.horizontal, 24).padding(.bottom, 8)
            .disabled(purchasing || subscriptions.isPremium)
        }
        .background(ScrollStyle.paper.ignoresSafeArea())
        .foregroundStyle(ScrollStyle.ink)
        .overlay { if purchasing { ProgressView().controlSize(.large) } }
        .alert("Subscription", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") { message = nil }
        } message: { Text(message ?? "") }
    }

    private func annualDetail(_ package: Package) -> String {
        var text = "\(package.localizedPriceString) / year"
        if let weekly = package.storeProduct.localizedPricePerWeek { text += " · \(weekly)/week" }
        return text
    }

    /// "$0.00" in the store's own currency format.
    private func zeroPrice(_ package: Package) -> String {
        let formatter = package.storeProduct.priceFormatter ?? NumberFormatter()
        if package.storeProduct.priceFormatter == nil { formatter.numberStyle = .currency }
        return formatter.string(from: 0) ?? "0"
    }

    private func planRow(_ package: Package, title: String, isOn: Bool, badge: String?, detail: String,
                         select: @escaping () -> Void) -> some View {
        Button(action: select) {
            HStack(spacing: 14) {
                Image(systemName: isOn ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline)
                    Text(detail).font(.subheadline).foregroundStyle(ScrollStyle.muted)
                }
                Spacer(minLength: 8)
                if let badge {
                    Text(badge).font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(ScrollStyle.ink, in: Capsule())
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isOn ? ScrollStyle.ink : ScrollStyle.hairline, lineWidth: isOn ? 2 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier("paywall.plan.\(title.lowercased())")
    }

    private func buy() {
        guard let package = selected else { return }
        let trialDays = trial(package)
        purchasing = true
        Task {
            do {
                if try await subscriptions.purchase(package: package) {
                    if let trialDays, let daysBefore = reminderDaysBefore
                        ?? (UserDefaults.standard.object(forKey: TrialReminder.daysBeforeKey) as? Int) {
                        TrialReminder.schedule(trialDays: trialDays, daysBefore: daysBefore)
                    }
                    onPurchased()
                }
            } catch {
                message = "The purchase wasn't completed. You haven't lost access to your Bible."
            }
            purchasing = false
        }
    }
}

/// Premium screen opened from Settings or a study limit.
struct PaywallView: View {
    @EnvironmentObject private var subscriptions: RevenueCatManager
    @Binding var isPresented: Bool
    @State private var trials: [String: Int] = [:]

    var body: some View {
        PlanPickerScreen(trials: trials, onClose: { isPresented = false }, onPurchased: { isPresented = false })
            .preferredColorScheme(.light)
            .task(id: subscriptions.offerings?.current?.identifier) {
                let packages = [subscriptions.yearlyPackage, subscriptions.monthlyPackage].compactMap { $0 }
                trials = await TrialMath.eligibleTrials(packages)
            }
    }
}
