//
//  AIService.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

enum AIServiceError: Error {
    case invalidURL
    case invalidResponse
    case apiKeyMissing
    case decodingError
    case networkError(Error)
    case rateLimitExceeded
    case dailyLimitExceeded

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .apiKeyMissing:
            return "API key is missing. Please configure in settings."
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment."
        case .dailyLimitExceeded:
            return "Daily usage limit reached. Please try again tomorrow."
        }
    }
}

struct AIRequest: Codable {
    let model: String
    let messages: [AIMessage]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

struct AIMessage: Codable {
    let role: String
    let content: String
}

struct AIResponse: Codable {
    let id: String
    let choices: [AIChoice]
    let usage: AIUsage?

    struct AIChoice: Codable {
        let message: AIMessage
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }

    struct AIUsage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

class AIService {
    static let shared = AIService()

    // Cost controls
    private let maxRequestsPerMinute = 10
    private let maxRequestsPerDay = 50
    private var requestTimestamps: [Date] = []
    private let requestHistoryKey = "ai_request_history"
    private let dailyUsageKey = "ai_daily_usage"
    private let lastResetDateKey = "ai_last_reset_date"

    private let defaultSystemPrompt = """
    You are a knowledgeable and compassionate AI Bible study assistant. Your role is to:

    1. Help users understand scripture in its historical, cultural, and theological context
    2. Provide insights from multiple Christian traditions (Catholic, Protestant, Orthodox) when relevant
    3. Ask thoughtful questions to deepen understanding
    4. Reference original Greek and Hebrew meanings when helpful
    5. Suggest related verses and cross-references
    6. Be respectful of different interpretations while maintaining biblical accuracy
    7. Encourage personal application and spiritual growth

    When discussing verses:
    - Always provide context (who wrote it, to whom, why)
    - Explain cultural background when relevant
    - Show how it connects to the broader biblical narrative
    - Suggest practical applications

    Be warm, encouraging, and accessible. Avoid overly academic language unless specifically requested.
    Keep responses concise and focused (under 300 words when possible).
    """

    private init() {
        resetDailyUsageIfNeeded()
    }

    private func resetDailyUsageIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date ?? Date.distantPast
        let calendar = Calendar.current

        if !calendar.isDateInToday(lastReset) {
            UserDefaults.standard.set(0, forKey: dailyUsageKey)
            UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
        }
    }

    private func checkRateLimits() throws {
        resetDailyUsageIfNeeded()

        // Check daily limit
        let dailyUsage = UserDefaults.standard.integer(forKey: dailyUsageKey)
        if dailyUsage >= maxRequestsPerDay {
            throw AIServiceError.dailyLimitExceeded
        }

        // Check per-minute limit
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)

        requestTimestamps.removeAll { $0 < oneMinuteAgo }

        if requestTimestamps.count >= maxRequestsPerMinute {
            throw AIServiceError.rateLimitExceeded
        }

        // Add current request
        requestTimestamps.append(now)
    }

    private func incrementDailyUsage() {
        let current = UserDefaults.standard.integer(forKey: dailyUsageKey)
        UserDefaults.standard.set(current + 1, forKey: dailyUsageKey)
    }

    func sendMessage(conversation: [Message], userMessage: String) async throws -> String {
        // Check subscription limits
        let subscriptionManager = await SubscriptionManager.shared
        guard await subscriptionManager.canAskQuestion() else {
            throw AIServiceError.dailyLimitExceeded
        }

        // Check rate limits BEFORE making request
        try checkRateLimits()

        // Get API key from UserDefaults
        guard let apiKey = UserDefaults.standard.string(forKey: "openai_api_key"),
              !apiKey.isEmpty else {
            throw AIServiceError.apiKeyMissing
        }

        // Prepare messages for API
        var apiMessages: [AIMessage] = [
            AIMessage(role: "system", content: defaultSystemPrompt)
        ]

        // Add conversation history (reduced to 5 messages to save costs)
        for msg in conversation.suffix(5) {
            apiMessages.append(AIMessage(
                role: msg.role.rawValue,
                content: msg.content
            ))
        }

        // Add new user message
        apiMessages.append(AIMessage(role: "user", content: userMessage))

        // Create request with CHEAPER MODEL
        let request = AIRequest(
            model: "gpt-4o-mini",  // Much cheaper than gpt-4! (~$0.15 per 1M tokens vs $30)
            messages: apiMessages,
            temperature: 0.7,
            maxTokens: 500  // Reduced from 1000 to save costs
        )

        // Make API call
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AIServiceError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30  // Add timeout

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            print("❌ Encoding error: \(error)")
            throw AIServiceError.decodingError
        }

        do {
            print("📡 Sending request to OpenAI...")
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw AIServiceError.invalidResponse
            }

            print("📥 Response status: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 429 {
                print("❌ Rate limited by OpenAI")
                throw AIServiceError.rateLimitExceeded
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ API Error: \(errorString)")
                }
                throw AIServiceError.invalidResponse
            }

            let aiResponse = try JSONDecoder().decode(AIResponse.self, from: data)

            // Log usage
            if let usage = aiResponse.usage {
                print("💰 Tokens used - Prompt: \(usage.promptTokens), Completion: \(usage.completionTokens), Total: \(usage.totalTokens)")
            }

            guard let responseMessage = aiResponse.choices.first?.message.content else {
                print("❌ No message in response")
                throw AIServiceError.invalidResponse
            }

            // Increment usage counters AFTER successful response
            incrementDailyUsage()
            await subscriptionManager.incrementQuestionCount()

            print("✅ Response received successfully")
            return responseMessage

        } catch let error as AIServiceError {
            print("❌ AIService error: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ Network error: \(error)")
            throw AIServiceError.networkError(error)
        }
    }

    func generateTitle(for firstMessage: String) async -> String {
        let words = firstMessage.components(separatedBy: .whitespacesAndNewlines)
        let title = words.prefix(6).joined(separator: " ")
        return title.isEmpty ? "New Conversation" : title
    }

    // Get remaining daily usage
    func getRemainingDailyRequests() -> Int {
        resetDailyUsageIfNeeded()
        let used = UserDefaults.standard.integer(forKey: dailyUsageKey)
        return max(0, maxRequestsPerDay - used)
    }
}
