import SwiftUI
import StoreKit

struct AccountView: View {
    @EnvironmentObject private var subscriptions: RevenueCatManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @State private var iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil

    var body: some View {
        NavigationStack {
            List {
                Section("Subscription") {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(subscriptions.subscriptionTitle).font(.headline)
                            Text(subscriptions.statusError != nil && subscriptions.customerInfo != nil
                                 ? "Last known status · Tap to refresh"
                                 : "View plan and billing")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("account.subscription")
                }
                Section("Your reading") {
                    LabeledContent("Reading Streak", value: "\(StreakStore.shared.currentStreak()) days")
                        .accessibilityIdentifier("account.streak")
                    Button { showSettings = true } label: {
                        Label("Reading Settings", systemImage: "textformat.size")
                    }
                    .accessibilityIdentifier("account.settings")
                }
                Section {
                    LabeledContent("iCloud", value: iCloudAvailable ? "Available" : "Not signed in")
                        .accessibilityIdentifier("account.icloud")
                } header: {
                    Text("Saved reading")
                } footer: {
                    Text(iCloudAvailable
                         ? "Saved verses, notes and reading progress use this device's iCloud account. Changes may take time to appear on another device."
                         : "Your reading is saved on this device. Sign in to iCloud in iPhone Settings to use iCloud for saved reading.")
                }
                Section {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                }
            }
            .listStyle(.plain)
            .navigationTitle("Account")
            .sheet(isPresented: $showSettings) { SettingsView() }
            .task { await refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await refresh() } }
            }
        }
    }

    private func refresh() async {
        iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        await subscriptions.checkSubscriptionStatus()
    }
}

struct SubscriptionView: View {
    @EnvironmentObject private var subscriptions: RevenueCatManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var showPremium = false
    @State private var showManage = false
    @State private var restoring = false
    @State private var restoreMessage: String?

    var body: some View {
        List {
            Section("Your plan") {
                Text(subscriptions.subscriptionTitle)
                    .font(.headline)
                    .accessibilityIdentifier("subscription.status")
                if subscriptions.checkingStatus { ProgressView("Checking with the App Store…") }
                if let entitlement = subscriptions.premiumEntitlement {
                    if let date = entitlement.expirationDate {
                        LabeledContent(dateLabel, value: date.formatted(date: .abbreviated, time: .omitted))
                    }
                    if entitlement.isActive && entitlement.ownershipType == .familyShared {
                        Text("Shared with you through Family Sharing")
                    }
                    if entitlement.billingIssueDetectedAt != nil {
                        Text("Apple reported a billing issue. Review your payment details in Manage Subscription.")
                            .foregroundStyle(.secondary)
                    }
                    if entitlement.isSandbox {
                        Text("Test subscription · No real charge")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                if let error = subscriptions.statusError {
                    Text(error).foregroundStyle(.secondary)
                        .accessibilityIdentifier("subscription.error")
                    if subscriptions.customerInfo != nil {
                        Text("Showing your last known status.").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Button("Refresh Status") {
                    Task { await subscriptions.checkSubscriptionStatus(forceRefresh: true) }
                }
                .disabled(subscriptions.checkingStatus || restoring)
                .accessibilityIdentifier("subscription.refresh")
            }
            Section {
                if subscriptions.customerInfo != nil && !subscriptions.isPremium {
                    Button("Explore Premium") { showPremium = true }
                        .accessibilityIdentifier("subscription.explore")
                }
                Button("Manage Subscription") { showManage = true }
                    .accessibilityIdentifier("subscription.manage")
                Button {
                    Task { await restore() }
                } label: {
                    HStack {
                        Text(restoring ? "Restoring Purchases…" : "Restore Purchases")
                        Spacer()
                        if restoring { ProgressView() }
                    }
                }
                .disabled(restoring)
                .accessibilityIdentifier("subscription.restore")
            } footer: {
                Text("Purchases use your App Store account. Restore if you subscribed on another device or reinstalled the app.")
            }
            Section("Have I paid?") {
                Link("View Apple Purchase History", destination: URL(string: "https://reportaproblem.apple.com/")!)
                    .accessibilityIdentifier("subscription.history")
                Text("Apple's purchase history shows your charges and receipts. A free trial is not a paid subscription. Buying the app itself is separate from Premium.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .task { await subscriptions.checkSubscriptionStatus() }
        .refreshable { await subscriptions.checkSubscriptionStatus(forceRefresh: true) }
        .sheet(isPresented: $showPremium) { PaywallView(isPresented: $showPremium) }
        .manageSubscriptionsSheet(isPresented: $showManage)
        .onChange(of: showManage) { _, presented in
            if !presented { Task { await subscriptions.checkSubscriptionStatus(forceRefresh: true) } }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await subscriptions.checkSubscriptionStatus(forceRefresh: true) } }
        }
        .alert("Restore Purchases", isPresented: Binding(
            get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } })) {
            Button("OK", role: .cancel) { restoreMessage = nil }
        } message: { Text(restoreMessage ?? "") }
    }

    private var dateLabel: String {
        guard let entitlement = subscriptions.premiumEntitlement else { return "Date" }
        if !entitlement.isActive { return "Expired" }
        if entitlement.periodType == .trial { return "Trial ends" }
        return entitlement.willRenew ? "Renews" : "Access ends"
    }

    private func restore() async {
        guard !restoring else { return }
        restoring = true
        defer { restoring = false }
        do {
            try await subscriptions.restorePurchases()
            restoreMessage = subscriptions.isPremium
                ? "Your Premium access has been restored."
                : "No active Premium subscription was found for this App Store account. Check that you're using the Apple Account that made the purchase."
        } catch {
            restoreMessage = "Purchases couldn't be restored. Check your connection and App Store account, then try again."
        }
    }
}
