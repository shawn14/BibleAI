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
            // Messages List - ChatGPT style centered layout
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.conversation.messages) { message in
                            MessageRow(message: message)
                                .id(message.id)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .onChange(of: viewModel.conversation.messages.count) { _ in
                    if let lastMessage = viewModel.conversation.messages.last {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input Area - ChatGPT style
            VStack(spacing: 0) {
                Divider()
                    .background(Color(.separator))

                HStack(alignment: .bottom, spacing: 8) {
                    HStack(spacing: 8) {
                        TextField("Message", text: $viewModel.currentMessage, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .focused($isInputFocused)
                            .lineLimit(1...10)
                            .padding(.vertical, 10)
                            .padding(.leading, 12)

                        Button(action: {
                            viewModel.sendMessage()
                            isInputFocused = true
                        }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(
                                    viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color(.systemGray4)
                                    : Color(red: 0.6, green: 0.4, blue: 0.2)
                                )
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                        .padding(.trailing, 8)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(24)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Content container - max width like ChatGPT
                HStack(alignment: .top, spacing: 16) {
                    // Avatar
                    if message.role == .assistant {
                        Circle()
                            .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "book.closed.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .semibold))
                            )
                    } else {
                        Circle()
                            .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            )
                    }

                    // Message content
                    VStack(alignment: .leading, spacing: 4) {
                        if message.isTyping {
                            TypingIndicator()
                        } else {
                            Text(message.content)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: 768) // ChatGPT-style max width
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity)
            .background(message.role == .assistant ? Color(.systemGray6).opacity(0.3) : Color(.systemBackground))
        }
    }
}

struct TypingIndicator: View {
    @State private var animationAmount = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationAmount == Double(index) ? 1.0 : 0.6)
                    .opacity(animationAmount == Double(index) ? 1.0 : 0.4)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .padding(.vertical, 4)
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
