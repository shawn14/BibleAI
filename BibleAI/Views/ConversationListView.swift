//
//  ConversationListView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct ConversationListView: View {
    @StateObject private var conversationService = ConversationService.shared
    @State private var showingNewConversation = false

    var body: some View {
        NavigationView {
            Group {
                if conversationService.conversations.isEmpty {
                    EmptyConversationsView(onCreateNew: createNewConversation)
                } else {
                    List {
                        ForEach(conversationService.conversations) { conversation in
                            NavigationLink(destination: ChatView(conversation: conversation)) {
                                ConversationRowView(conversation: conversation)
                            }
                        }
                        .onDelete(perform: deleteConversations)
                    }
                }
            }
            .navigationTitle("AI Bible Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createNewConversation) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewConversation) {
                if let newConversation = conversationService.conversations.first {
                    NavigationView {
                        ChatView(conversation: newConversation)
                    }
                }
            }
        }
    }

    private func createNewConversation() {
        let _ = conversationService.createConversation()
        showingNewConversation = true
    }

    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            conversationService.deleteConversation(conversationService.conversations[index])
        }
    }
}

struct ConversationRowView: View {
    let conversation: Conversation

    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 min ago" : "\(minutes) min ago"
        } else {
            return "Just now"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(1)

            Text(conversation.preview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            Text(timeAgoString(from: conversation.updatedAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyConversationsView: View {
    let onCreateNew: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Conversations Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start a conversation with your AI Bible study assistant")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onCreateNew) {
                Label("Start New Conversation", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .padding()
    }
}

#Preview {
    ConversationListView()
}
