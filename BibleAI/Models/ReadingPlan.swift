//
//  ReadingPlan.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation

struct ReadingPlan: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let duration: Int // days
    let category: PlanCategory
    let dailyReadings: [DailyReading]

    init(id: UUID = UUID(), title: String, description: String, duration: Int, category: PlanCategory, dailyReadings: [DailyReading]) {
        self.id = id
        self.title = title
        self.description = description
        self.duration = duration
        self.category = category
        self.dailyReadings = dailyReadings
    }
}

enum PlanCategory: String, Codable, CaseIterable {
    case overview = "Overview"
    case devotional = "Devotional"
    case topical = "Topical"
    case sequential = "Sequential"

    var icon: String {
        switch self {
        case .overview: return "book.fill"
        case .devotional: return "heart.fill"
        case .topical: return "star.fill"
        case .sequential: return "list.number"
        }
    }
}

struct DailyReading: Identifiable, Codable {
    let id: UUID
    let day: Int
    let title: String
    let readings: [ReadingReference]

    init(id: UUID = UUID(), day: Int, title: String, readings: [ReadingReference]) {
        self.id = id
        self.day = day
        self.title = title
        self.readings = readings
    }
}

struct ReadingReference: Identifiable, Codable {
    let id: UUID
    let book: String
    let startChapter: Int
    let endChapter: Int?

    init(id: UUID = UUID(), book: String, startChapter: Int, endChapter: Int? = nil) {
        self.id = id
        self.book = book
        self.startChapter = startChapter
        self.endChapter = endChapter
    }

    var displayText: String {
        if let end = endChapter, end != startChapter {
            return "\(book) \(startChapter)-\(end)"
        } else {
            return "\(book) \(startChapter)"
        }
    }
}

struct UserPlanProgress: Identifiable, Codable {
    let id: UUID
    let planId: UUID
    let startedDate: Date
    var completedDays: Set<Int>
    var lastReadDate: Date?

    init(id: UUID = UUID(), planId: UUID, startedDate: Date = Date(), completedDays: Set<Int> = [], lastReadDate: Date? = nil) {
        self.id = id
        self.planId = planId
        self.startedDate = startedDate
        self.completedDays = completedDays
        self.lastReadDate = lastReadDate
    }

    var currentDay: Int {
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: startedDate, to: Date()).day ?? 0
        return daysSinceStart + 1
    }

    var progressPercentage: Double {
        guard !completedDays.isEmpty else { return 0.0 }
        return Double(completedDays.count) / Double(completedDays.max() ?? 1) * 100.0
    }
}
