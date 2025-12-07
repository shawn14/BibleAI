//
//  SettingsView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("preferred_translation") private var preferredTranslation: String = "KJV"

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
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
