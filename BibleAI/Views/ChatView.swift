//
//  ChatView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    init(conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.conversation.messages) { message in
                            MessageRow(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .onChange(of: viewModel.conversation.messages.count) { _ in
                    if let lastMessage = viewModel.conversation.messages.last {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input Area
            VStack(spacing: 0) {
                Divider()
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Ask about scripture...", text: $viewModel.currentMessage, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .focused($isInputFocused)
                        .lineLimit(1...6)

                    Button(action: {
                        viewModel.sendMessage()
                        isInputFocused = true
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(
                                viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? .gray
                                : Color(red: 0.6, green: 0.4, blue: 0.2)
                            )
                    }
                    .disabled(viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(viewModel.conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        viewModel.regenerateLastResponse()
                    }) {
                        Label("Regenerate Response", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.conversation.messages.isEmpty)

                    Button(role: .destructive, action: {
                        viewModel.clearConversation()
                    }) {
                        Label("Clear Conversation", systemImage: "trash")
                    }
                    .disabled(viewModel.conversation.messages.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
}

struct MessageRow: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                // AI Avatar - warm, biblical theme
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.8, green: 0.6, blue: 0.4),
                                Color(red: 0.6, green: 0.4, blue: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    )
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                if message.isTyping {
                    TypingIndicator()
                } else {
                    Text(message.content)
                        .font(.body)
                        .padding(14)
                        .background(
                            message.role == .user
                            ? Color(red: 0.6, green: 0.4, blue: 0.2)
                            : Color(.systemBackground)
                        )
                        .foregroundColor(message.role == .user ? .white : .primary)
                        .cornerRadius(18)
                        .textSelection(.enabled)
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                // User Avatar - simple and clean
                Circle()
                    .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    )
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationAmount = 0.0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount == Double(index) ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .onAppear {
            animationAmount = 1.0
        }
    }
}

#Preview {
    NavigationView {
        ChatView(conversation: Conversation(
            title: "Understanding John 3:16",
            messages: [
                Message(role: .user, content: "What does John 3:16 mean?"),
                Message(role: .assistant, content: "John 3:16 is one of the most beloved verses in the Bible! Let me help you understand its depth.\n\nThis verse comes from Jesus's conversation with Nicodemus, a Pharisee who came to Jesus at night. The context is crucial - Nicodemus represented the religious establishment, yet he recognized something special in Jesus.\n\nThe verse tells us:\n- God's motivation: LOVE\n- God's action: He GAVE His Son\n- The scope: The WORLD (everyone!)\n- The condition: BELIEF in Jesus\n- The promise: ETERNAL LIFE\n\nWould you like to explore the historical context, or discuss how this applies to your life today?")
            ]
        ))
    }
}
