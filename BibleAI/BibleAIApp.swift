//
//  BibleAIApp.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

@main
struct BibleAIApp: App {
    @StateObject private var appleAccount = AppleAccount()
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var revenueCatManager = RevenueCatManager.shared

    init() {
        CloudSync.shared.start()
        // Set API key from Config if not already set
        if UserDefaults.standard.string(forKey: "openai_api_key") == nil,
           !Config.openAIAPIKey.isEmpty, Config.openAIAPIKey != "YOUR_API_KEY_HERE" {
            UserDefaults.standard.set(Config.openAIAPIKey, forKey: "openai_api_key")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(revenueCatManager)
                .environmentObject(appleAccount)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await appleAccount.refreshCredential() } }
                }
        }
    }
}
