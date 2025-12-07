//
//  ChatViewModel.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversation: Conversation
    @Published var currentMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    private let aiService = AIService.shared
    private let conversationService = ConversationService.shared

    init(conversation: Conversation) {
        self.conversation = conversation
    }

    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let userMessageText = currentMessage
        currentMessage = ""

        // Create and add user message
        let userMessage = Message(
            role: .user,
            content: userMessageText
        )

        conversation.addMessage(userMessage)
        conversationService.updateConversation(conversation)

        // Add typing indicator
        let typingMessage = Message(
            role: .assistant,
            content: "",
            isTyping: true
        )
        conversation.addMessage(typingMessage)

        isLoading = true

        Task {
            do {
                // Get AI response
                let response = try await aiService.sendMessage(
                    conversation: conversation.messages.filter { !$0.isTyping },
                    userMessage: userMessageText
                )

                // Remove typing indicator
                conversation.messages.removeAll { $0.isTyping }

                // Add AI response
                let assistantMessage = Message(
                    role: .assistant,
                    content: response
                )

                conversation.addMessage(assistantMessage)
                conversationService.updateConversation(conversation)

                isLoading = false

            } catch let error as AIServiceError {
                // Remove typing indicator
                conversation.messages.removeAll { $0.isTyping }

                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            } catch {
                // Remove typing indicator
                conversation.messages.removeAll { $0.isTyping }

                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }

    func deleteMessage(_ message: Message) {
        conversation.messages.removeAll { $0.id == message.id }
        conversationService.updateConversation(conversation)
    }

    func regenerateLastResponse() {
        // Find the last user message
        guard let lastUserMessage = conversation.messages.last(where: { $0.role == .user }) else {
            return
        }

        // Remove the last assistant message
        if let lastAssistantIndex = conversation.messages.lastIndex(where: { $0.role == .assistant }) {
            conversation.messages.remove(at: lastAssistantIndex)
        }

        // Resend the last user message
        currentMessage = lastUserMessage.content
        sendMessage()
    }

    func clearConversation() {
        conversation.messages.removeAll()
        conversationService.updateConversation(conversation)
    }
}
