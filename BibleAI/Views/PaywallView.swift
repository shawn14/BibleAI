//
//  PaywallView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Binding var isPresented: Bool
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                        Text("Unlock Premium")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Get unlimited AI Bible study")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Features
                    VStack(spacing: 20) {
                        FeatureRow(icon: "infinity", title: "Unlimited AI Questions", description: "Ask as many questions as you want")
                        FeatureRow(icon: "highlighter", title: "Unlimited Highlights", description: "Highlight and note every verse")
                        FeatureRow(icon: "book.fill", title: "All Reading Plans", description: "Access every reading plan")
                        FeatureRow(icon: "star.fill", title: "Future Features First", description: "Get new features before anyone else")
                    }
                    .padding(.horizontal)

                    // Pricing
                    VStack(spacing: 16) {
                        if let yearly = subscriptionManager.yearlyProduct {
                            SubscriptionButton(
                                product: yearly,
                                isPurchasing: $isPurchasing,
                                recommended: true,
                                savings: subscriptionManager.monthlySavings,
                                onPurchase: purchase
                            )
                        }

                        if let monthly = subscriptionManager.monthlyProduct {
                            SubscriptionButton(
                                product: monthly,
                                isPurchasing: $isPurchasing,
                                recommended: false,
                                savings: nil,
                                onPurchase: purchase
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Restore purchases
                    Button {
                        Task {
                            do {
                                try await subscriptionManager.restorePurchases()
                                if subscriptionManager.subscriptionStatus == .premium {
                                    isPresented = false
                                }
                            } catch {
                                errorMessage = "Failed to restore purchases"
                                showError = true
                            }
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    // Free tier info
                    VStack(spacing: 8) {
                        Text("Free Plan")
                            .font(.headline)
                        Text("5 AI questions per day • Limited highlights • Basic features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func purchase(_ product: Product) {
        Task {
            isPurchasing = true
            do {
                let success = try await subscriptionManager.purchase(product)
                if success {
                    isPresented = false
                }
            } catch {
                errorMessage = "Purchase failed. Please try again."
                showError = true
            }
            isPurchasing = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct SubscriptionButton: View {
    let product: Product
    @Binding var isPurchasing: Bool
    let recommended: Bool
    let savings: String?
    let onPurchase: (Product) -> Void

    var body: some View {
        Button {
            onPurchase(product)
        } label: {
            VStack(spacing: 8) {
                if recommended {
                    Text("BEST VALUE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if let savings = savings {
                            Text("Save \(savings)")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        }
                    }

                    Spacer()

                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(recommended ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color.gray.opacity(0.3), lineWidth: recommended ? 2 : 1)
            )
        }
        .disabled(isPurchasing)
        .opacity(isPurchasing ? 0.6 : 1)
    }
}

#Preview {
    PaywallView(isPresented: .constant(true))
}
