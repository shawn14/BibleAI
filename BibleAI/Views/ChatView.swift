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
    @State private var verseOfTheDay: DailyVerse?

    init(conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages List - ChatGPT style centered layout
            ScrollViewReader { proxy in
                ScrollView {
                    if viewModel.conversation.messages.isEmpty {
                        // Empty state with verse suggestions
                        VStack(spacing: 40) {
                            Spacer()
                                .frame(height: 60)

                            VStack(spacing: 12) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                                Text("Bible AI")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }

                            // Verse of the Day
                            if let dailyVerse = verseOfTheDay {
                                VerseOfTheDayCard(verse: dailyVerse) {
                                    viewModel.currentMessage = "Tell me more about \(dailyVerse.reference)"
                                    viewModel.sendMessage()
                                }
                                .padding(.horizontal, 20)
                            }

                            VStack(spacing: 12) {
                                Text("Try asking about...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                VStack(spacing: 10) {
                                    SuggestionCard(text: "Explain John 3:16", icon: "heart.fill") {
                                        viewModel.currentMessage = "Explain John 3:16"
                                        viewModel.sendMessage()
                                    }

                                    SuggestionCard(text: "What does Psalm 23 teach about trust?", icon: "leaf.fill") {
                                        viewModel.currentMessage = "What does Psalm 23 teach about trust?"
                                        viewModel.sendMessage()
                                    }

                                    SuggestionCard(text: "Context of Romans 8:28", icon: "book.fill") {
                                        viewModel.currentMessage = "Context of Romans 8:28"
                                        viewModel.sendMessage()
                                    }

                                    SuggestionCard(text: "Meaning of the Beatitudes", icon: "sparkles") {
                                        viewModel.currentMessage = "Meaning of the Beatitudes"
                                        viewModel.sendMessage()
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.conversation.messages) { message in
                                MessageRow(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
                .onChange(of: viewModel.conversation.messages.count) { oldValue, newValue in
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
        .navigationTitle("Bible AI")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .task {
            // Load verse of the day when view appears
            if verseOfTheDay == nil {
                verseOfTheDay = await VerseOfTheDayService.shared.getVerseOfTheDay()
            }
        }
    }
}

struct MessageRow: View {
    let message: Message
    @State private var showShareSheet = false
    @State private var userQuestion: String = ""

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
                                .contextMenu {
                                    if message.role == .assistant {
                                        Button {
                                            showShareSheet = true
                                        } label: {
                                            Label("Share Insight", systemImage: "square.and.arrow.up")
                                        }
                                    }
                                }
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
        .sheet(isPresented: $showShareSheet) {
            SimpleShareView(
                shareText: .formatInsightShare(
                    question: userQuestion,
                    answer: message.content
                ),
                isPresented: $showShareSheet
            )
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

struct SuggestionCard: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                    .frame(width: 24)

                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.6))
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VerseOfTheDayCard: View {
    let verse: DailyVerse
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sunrise.fill")
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        .font(.system(size: 18))

                    Text("Verse of the Day")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("\"\(verse.text)\"")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)

                    Text(verse.reference)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.1),
                        Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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
