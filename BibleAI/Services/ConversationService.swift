//
//  ConversationService.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

class ConversationService: ObservableObject {
    static let shared = ConversationService()

    @Published var conversations: [Conversation] = []

    private let conversationsKey = "saved_conversations"

    private init() {
        loadConversations()
    }

    func createConversation() -> Conversation {
        let conversation = Conversation()
        conversations.insert(conversation, at: 0)
        saveConversations()
        return conversation
    }

    func updateConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
            saveConversations()
        }
    }

    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        saveConversations()
    }

    func addMessage(to conversationId: UUID, message: Message) {
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].addMessage(message)
            saveConversations()
        }
    }

    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: conversationsKey)
        }
    }

    private func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: conversationsKey),
           let decoded = try? JSONDecoder().decode([Conversation].self, from: data) {
            conversations = decoded
        }
    }
}
