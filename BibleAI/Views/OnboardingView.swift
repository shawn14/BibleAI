//
//  OnboardingView.swift
//  BibleAI
//
//  Created on 2025-12-07.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var revenueCatManager: RevenueCatManager
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                OnboardingPage(
                    icon: "book.fill",
                    iconColor: Color(red: 0.6, green: 0.4, blue: 0.2),
                    title: "Welcome to Bible AI Companion",
                    subtitle: "Your personal AI-powered Bible study assistant",
                    description: "Explore scripture with deeper understanding through AI-guided insights and thoughtful questions."
                )
                .tag(0)

                // Page 2: AI Questions
                OnboardingPage(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconColor: Color(red: 0.6, green: 0.4, blue: 0.2),
                    title: "Ask Any Question",
                    subtitle: "Get instant, thoughtful answers",
                    description: "From historical context to theological insights, get AI-powered answers to deepen your Bible study."
                )
                .tag(1)

                // Page 3: Highlights & Notes
                OnboardingPage(
                    icon: "highlighter",
                    iconColor: Color(red: 0.6, green: 0.4, blue: 0.2),
                    title: "Highlight & Remember",
                    subtitle: "Keep track of meaningful verses",
                    description: "Highlight important passages and add personal notes to build your spiritual journey."
                )
                .tag(2)

                // Page 4: Reading Plans
                OnboardingPage(
                    icon: "calendar",
                    iconColor: Color(red: 0.6, green: 0.4, blue: 0.2),
                    title: "Guided Reading Plans",
                    subtitle: "Stay consistent in your study",
                    description: "Follow curated reading plans designed to help you explore the Bible systematically."
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Bottom buttons
            VStack {
                Spacer()

                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    if currentPage < 3 {
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                    } else {
                        Button("Get Started") {
                            showPaywall = true
                        }
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.6, green: 0.4, blue: 0.2))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
                .environmentObject(revenueCatManager)
                .onDisappear {
                    // When paywall is dismissed, dismiss onboarding too
                    isPresented = false
                }
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(iconColor)
                .padding(.bottom, 16)

            // Title
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Subtitle
            Text(subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Description
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .padding(.top, 8)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(RevenueCatManager.shared)
}
