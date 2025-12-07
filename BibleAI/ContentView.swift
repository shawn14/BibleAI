//
//  ContentView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var conversationService = ConversationService.shared
    @State private var selectedTab = 0
    @State private var currentConversation: Conversation?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home - New conversation with suggestions
            ChatContainerView(currentConversation: $currentConversation)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // Bible Reader
            BibleReaderView()
                .tabItem {
                    Label("Read", systemImage: "book.fill")
                }
                .tag(1)

            // Highlights
            HighlightsListView()
                .tabItem {
                    Label("Highlights", systemImage: "highlighter")
                }
                .tag(2)

            // Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(Color(red: 0.6, green: 0.4, blue: 0.2))
        .onChange(of: selectedTab) { oldValue, newTab in
            // When user taps Home tab, always show a fresh empty conversation
            if newTab == 0 {
                // Always create a fresh temporary conversation (not saved until first message)
                currentConversation = Conversation()
            }
        }
        .onAppear {
            // Start with an empty conversation on launch
            if currentConversation == nil {
                currentConversation = Conversation()
            }
        }
    }
}

struct ChatContainerView: View {
    @StateObject private var conversationService = ConversationService.shared
    @Binding var currentConversation: Conversation?
    @State private var showConversationsList = false

    var body: some View {
        NavigationView {
            if let conversation = currentConversation {
                ChatView(conversation: conversation)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                showConversationsList = true
                            }) {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showConversationsList) {
            NavigationView {
                ConversationListSheet(currentConversation: $currentConversation, isPresented: $showConversationsList)
            }
        }
    }
}

struct EmptyChatView: View {
    let onNewChat: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                VStack(spacing: 8) {
                    Text("Bible AI")
                        .font(.title)
                        .fontWeight(.semibold)

                    Text("Your AI-powered Bible study companion")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button(action: onNewChat) {
                Text("Start Conversation")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.6, green: 0.4, blue: 0.2))
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ConversationListSheet: View {
    @StateObject private var conversationService = ConversationService.shared
    @Binding var currentConversation: Conversation?
    @Binding var isPresented: Bool

    var body: some View {
        List {
            // New Chat button at the top
            Section {
                Button(action: {
                    let newConversation = conversationService.createConversation()
                    currentConversation = newConversation
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        Text("New Chat")
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                    }
                }
            }

            // Existing conversations
            Section {
                ForEach(conversationService.conversations) { conversation in
                    Button(action: {
                        currentConversation = conversation
                        isPresented = false
                    }) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(conversation.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(conversation.preview)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteConversations)
            } header: {
                Text("Recent")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Conversations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    isPresented = false
                }
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
            }
        }
    }

    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = conversationService.conversations[index]
            conversationService.deleteConversation(conversation)

            // If we deleted the current conversation, create a new one
            if currentConversation?.id == conversation.id {
                currentConversation = conversationService.createConversation()
            }
        }
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
