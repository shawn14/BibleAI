import SwiftUI
import RevenueCat

struct PaywallView: View {
    @EnvironmentObject private var subscriptions: RevenueCatManager
    @Binding var isPresented: Bool
    @State private var purchasing = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Go deeper with BibleAI")
                            .font(.system(.title, design: .serif))
                        Text("Unlimited AI questions for your Scripture study.")
                            .foregroundStyle(.secondary)
                    }.padding(.vertical, 12)
                }
                if subscriptions.isPremium {
                    Section { Label("Premium is active", systemImage: "checkmark") }
                } else {
                    Section("Choose a Subscription") {
                        if subscriptions.loadingOfferings {
                            ProgressView("Loading plans…")
                        } else if subscriptions.yearlyPackage == nil && subscriptions.monthlyPackage == nil {
                            Text(subscriptions.offeringsError ?? "Plans are currently unavailable.")
                                .foregroundStyle(.secondary)
                            Button("Try Again") { Task { await subscriptions.loadOfferings() } }
                        } else {
                            if let annual = subscriptions.yearlyPackage { packageRow(annual, period: "year") }
                            if let monthly = subscriptions.monthlyPackage { packageRow(monthly, period: "month") }
                        }
                    }
                    Section {
                        Text("Your subscription renews automatically unless cancelled. Apple shows the final price and any eligible introductory offer before you confirm.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Section {
                    Button("Restore Purchases") {
                        purchasing = true
                        Task {
                            do {
                                try await subscriptions.restorePurchases()
                                message = subscriptions.isPremium ? "Your Premium subscription is restored." : "No active subscription was found."
                            } catch { message = "Purchases couldn't be restored. Please try again." }
                            purchasing = false
                        }
                    }
                    Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                }
                Section {
                    Text("Reading, saved verses, notes, and reading plans remain available without a subscription.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Link("Privacy Policy", destination: URL(string: "https://www.bibleaicompanion.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://www.bibleaicompanion.com/terms")!)
                }
            }
            .listStyle(.plain)
            .disabled(purchasing)
            .overlay { if purchasing { ProgressView("Connecting to the App Store…") } }
            .navigationTitle("BibleAI Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { isPresented = false }.disabled(purchasing) } }
            .alert("Subscription", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK") { message = nil }
            } message: { Text(message ?? "") }
        }
    }

    private func packageRow(_ package: Package, period: String) -> some View {
        Button {
            purchasing = true
            Task {
                do {
                    if try await subscriptions.purchase(package: package) { isPresented = false }
                } catch { message = "The purchase wasn't completed. You haven't lost access to your Bible." }
                purchasing = false
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.storeProduct.localizedTitle).foregroundStyle(.primary)
                    Text("\(package.localizedPriceString) / \(period)").foregroundStyle(.secondary)
                }
                Spacer()
                Text("Subscribe").fontWeight(.semibold)
            }.padding(.vertical, 8)
        }
    }
}
