import SwiftUI
import StoreKit
import AuthenticationServices

struct AccountView: View {
    @EnvironmentObject private var appleAccount: AppleAccount
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSignOut = false
    @State private var showRemoveProfile = false
    @EnvironmentObject private var subscriptions: RevenueCatManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @State private var iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let profile = appleAccount.profile {
                        Text(profile.name ?? "Apple Account").font(.headline)
                            .accessibilityIdentifier("account.name")
                        if let email = profile.email {
                            Text(email).foregroundStyle(.secondary).textSelection(.enabled)
                                .accessibilityIdentifier("account.email")
                        }
                        Label("Signed in with Apple", systemImage: "checkmark.circle")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Button("Sign Out", role: .destructive) { showSignOut = true }
                            .accessibilityIdentifier("account.signOut")
                    } else {
                        Text("Sign in to BibleAI").font(.headline)
                        SignInWithAppleButton(.signIn, onRequest: appleAccount.prepare, onCompletion: appleAccount.complete)
                            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                            .frame(height: 50)
                            .disabled(appleAccount.checkingCredential || appleAccount.signingIn)
                            .accessibilityIdentifier("account.appleSignIn")
                    }
                    if appleAccount.checkingCredential || appleAccount.signingIn {
                        ProgressView("Checking your Apple account…")
                    }
                    if let error = appleAccount.errorMessage {
                        Text(error).font(.footnote).foregroundStyle(.secondary)
                            .accessibilityIdentifier("account.authError")
                    }
                } footer: {
                    Text("Reading is available without signing in. Your saved reading uses iCloud; purchases use your App Store account.")
                }
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
                    LabeledContent("Reading Streak", value: StreakStore.shared.currentStreakDescription)
                        .accessibilityIdentifier("account.streak")
                    Button { showSettings = true } label: {
                        Label("Reading Settings", systemImage: "textformat.size")
                    }
                    .accessibilityIdentifier("account.settings")
                }
                Section {
                    LabeledContent("iCloud", value: iCloudAvailable ? "Available" : "Unavailable")
                        .accessibilityIdentifier("account.icloud")
                } header: {
                    Text("Saved reading")
                } footer: {
                    Text(iCloudAvailable
                         ? "Saved verses, notes and reading progress use this device's iCloud account. Changes may take time to appear on another device."
                         : "Your reading is saved on this device. Check iCloud in iPhone Settings to use it for saved reading.")
                }
                Section("Account settings") {
                    if appleAccount.isSignedIn {
                        Button("Delete Account", role: .destructive) { showRemoveProfile = true }
                            .accessibilityIdentifier("account.removeProfile")
                    }
                    Link("Manage Sign in with Apple", destination: URL(string: "https://support.apple.com/102571")!)
                        .accessibilityIdentifier("account.manageApple")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                }
            }
            .listStyle(.plain)
            .navigationTitle("Account")
            .sheet(isPresented: $showSettings) { SettingsView() }
            .confirmationDialog("Sign out of BibleAI?", isPresented: $showSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { appleAccount.signOut() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your saved reading stays on this device and in iCloud. Signing out does not cancel your App Store subscription.")
            }
            .confirmationDialog("Delete your BibleAI account?", isPresented: $showRemoveProfile, titleVisibility: .visible) {
                Button("Delete Account", role: .destructive) { appleAccount.removeProfile() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This deletes your BibleAI account: your Apple sign-in name, email and session. BibleAI keeps no account on a server, so nothing else is stored. Your saved reading stays, and your App Store subscription is not canceled. To stop using Sign in with Apple with BibleAI, also use Manage Sign in with Apple.")
            }
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
    @State private var restoreTakingLonger = false
    private var restoring: Bool { subscriptions.restoringPurchases }
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
                if restoreTakingLonger && restoring {
                    Text("The App Store hasn't finished restoring yet. You can keep reading; your access will update when it responds.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .accessibilityIdentifier("subscription.restorePending")
                }
            } footer: {
                Text("Purchases use your App Store account. Restore if you subscribed on another device or reinstalled the app.")
            }
            Section("Have I paid?") {
                Link("View Apple Purchase History", destination: URL(string: "https://reportaproblem.apple.com/")!)
                    .accessibilityIdentifier("subscription.history")
                Text("Apple's purchase history shows your charges and receipts. A free trial is not a paid subscription.")
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
        .task(id: restoring) {
            restoreTakingLonger = false
            guard restoring else { return }
            do {
                try await Task.sleep(for: .seconds(15))
                restoreTakingLonger = true
            } catch { /* Leaving this view cancels only the waiting-message timer. */ }
        }
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
