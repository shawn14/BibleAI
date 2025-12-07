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
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.15, blue: 0.3),
                        Color(red: 0.05, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Group {
                    if conversationService.conversations.isEmpty {
                        EmptyConversationsView(onCreateNew: createNewConversation)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(conversationService.conversations) { conversation in
                                    NavigationLink(destination: ChatView(conversation: conversation)) {
                                        ConversationRowView(conversation: conversation)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("AI Bible Chat")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createNewConversation) {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "message.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(size: 16))

                Text(conversation.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Text(conversation.preview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            Text(timeAgoString(from: conversation.updatedAt))
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct EmptyConversationsView: View {
    let onCreateNew: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                Text("No Conversations Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Start a conversation with your AI Bible study assistant")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onCreateNew) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Start New Conversation")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

#Preview {
    ConversationListView()
}
