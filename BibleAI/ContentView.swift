//
//  ContentView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ConversationListView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(0)

            BibleReaderView()
                .tabItem {
                    Label("Read", systemImage: "book.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(Color(red: 0.6, green: 0.4, blue: 0.2))
    }
}

struct BibleReaderView: View {
    var body: some View {
        NavigationView {
            BibleBooksListView()
        }
    }
}

#Preview {
    ContentView()
}
