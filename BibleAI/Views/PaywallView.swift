//
//  PaywallView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallView: View {
    @EnvironmentObject var revenueCatManager: RevenueCatManager
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
                        if revenueCatManager.offerings?.current != nil {
                            // Yearly package (recommended)
                            if let yearlyPackage = revenueCatManager.yearlyPackage {
                                PackageButton(
                                    package: yearlyPackage,
                                    isPurchasing: $isPurchasing,
                                    recommended: true,
                                    onPurchase: purchase
                                )
                            }

                            // Monthly package
                            if let monthlyPackage = revenueCatManager.monthlyPackage {
                                PackageButton(
                                    package: monthlyPackage,
                                    isPurchasing: $isPurchasing,
                                    recommended: false,
                                    onPurchase: purchase
                                )
                            }
                        } else {
                            ProgressView("Loading...")
                                .padding()
                        }
                    }
                    .padding(.horizontal)

                    // Restore purchases
                    Button {
                        Task {
                            do {
                                try await revenueCatManager.restorePurchases()
                                if revenueCatManager.isPremium {
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
                        Text("\(revenueCatManager.freeQuestionsPerDay) AI questions per day • Limited highlights • Basic features")
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

    private func purchase(_ package: Package) {
        Task {
            isPurchasing = true
            do {
                let success = try await revenueCatManager.purchase(package: package)
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

struct PackageButton: View {
    let package: Package
    @Binding var isPurchasing: Bool
    let recommended: Bool
    let onPurchase: (Package) -> Void

    var body: some View {
        Button {
            onPurchase(package)
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
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if recommended {
                            Text("Save 40%")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        }
                    }

                    Spacer()

                    Text(package.localizedPriceString)
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
        .environmentObject(RevenueCatManager.shared)
}
