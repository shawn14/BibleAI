//
//  SettingsView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("preferred_translation") private var preferredTranslation: String = "KJV"
    @State private var tapCount = 0
    @State private var showResetAlert = false

    let translations = ["KJV", "NIV", "ESV", "NASB", "NLT"]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Preferred Translation", selection: $preferredTranslation) {
                        ForEach(translations, id: \.self) { translation in
                            Text(translation).tag(translation)
                        }
                    }
                } header: {
                    Text("Bible Settings")
                }

                Section {
                    HStack {
                        Text("Requests Remaining Today")
                        Spacer()
                        Text("\(AIService.shared.getRemainingDailyRequests()) / 50")
                            .foregroundColor(AIService.shared.getRemainingDailyRequests() < 10 ? .orange : .secondary)
                    }
                } header: {
                    Text("Usage")
                } footer: {
                    Text("Daily limit resets at midnight.")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tapCount += 1
                        if tapCount >= 5 {
                            showResetAlert = true
                            tapCount = 0
                        }
                        // Reset tap count after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            tapCount = 0
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .alert("Reset App", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetApp()
                }
            } message: {
                Text("This will clear onboarding, question count, and all app data. The app will restart.")
            }
        }
    }

    private func resetApp() {
        // Clear onboarding flag
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        // Clear question counts
        UserDefaults.standard.removeObject(forKey: "daily_question_count")
        UserDefaults.standard.removeObject(forKey: "last_question_date")

        // Clear AI usage
        UserDefaults.standard.removeObject(forKey: "ai_daily_usage")
        UserDefaults.standard.removeObject(forKey: "ai_last_reset_date")

        // Exit the app (on simulator this will just close it, user needs to reopen)
        exit(0)
    }
}

#Preview {
    SettingsView()
}
