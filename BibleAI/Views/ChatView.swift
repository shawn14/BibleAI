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

            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.conversation.messages) { message in
                                MessageRow(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.conversation.messages.count) { _ in
                        if let lastMessage = viewModel.conversation.messages.last {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input Area with glass effect
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Ask about scripture...", text: $viewModel.currentMessage, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .focused($isInputFocused)
                        .lineLimit(1...6)
                        .tint(.white)

                    Button(action: {
                        viewModel.sendMessage()
                        isInputFocused = true
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(
                                viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? .gray
                                : .blue
                            )
                    }
                    .disabled(viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding()
                .background(.thinMaterial)
            }
        }
        .navigationTitle(viewModel.conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
                // AI Avatar with glass effect
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .overlay(
                        Image(systemName: "sparkles")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(.system(size: 18, weight: .semibold))
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                if message.isTyping {
                    TypingIndicator()
                } else {
                    Text(message.content)
                        .padding(16)
                        .background {
                            if message.role == .user {
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                Color.clear
                                    .background(.ultraThinMaterial)
                            }
                        }
                        .foregroundColor(message.role == .user ? .white : .primary)
                        .cornerRadius(20)
                        .textSelection(.enabled)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                // User Avatar with glass effect
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.blue.opacity(0.6), .cyan.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationAmount = 0.0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .cyan.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 10, height: 10)
                    .scaleEffect(animationAmount == Double(index) ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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
