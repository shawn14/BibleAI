//
//  BibleAIApp.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

@main
struct BibleAIApp: App {
    @StateObject private var revenueCatManager = RevenueCatManager.shared

    init() {
        // Set API key from Config if not already set
        if UserDefaults.standard.string(forKey: "openai_api_key") == nil {
            UserDefaults.standard.set(Config.openAIAPIKey, forKey: "openai_api_key")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(revenueCatManager)
        }
    }
}
