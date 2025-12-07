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
            // Main Chat View (opens directly like ChatGPT)
            ChatContainerView(currentConversation: $currentConversation)
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
        .onAppear {
            // Create or load the current conversation
            if currentConversation == nil {
                if let latest = conversationService.conversations.first {
                    currentConversation = latest
                } else {
                    currentConversation = conversationService.createConversation()
                }
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
            } else {
                EmptyChatView {
                    currentConversation = conversationService.createConversation()
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
