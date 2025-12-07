//
//  Conversation.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [Message]
    let createdAt: Date
    var updatedAt: Date
    var tags: [String]

    init(id: UUID = UUID(), title: String = "New Conversation", messages: [Message] = [], createdAt: Date = Date(), updatedAt: Date = Date(), tags: [String] = []) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
    }

    var lastMessage: Message? {
        messages.last
    }

    var preview: String {
        guard let lastMsg = lastMessage else {
            return "No messages yet"
        }
        return lastMsg.content.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    mutating func addMessage(_ message: Message) {
        messages.append(message)
        updatedAt = Date()

        // Auto-generate title from first user message
        if title == "New Conversation" && message.role == .user && !message.content.isEmpty {
            title = String(message.content.prefix(50))
        }
    }
}
