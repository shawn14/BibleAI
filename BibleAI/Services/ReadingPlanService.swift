//
//  ReadingPlanService.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation
import Combine

class ReadingPlanService: ObservableObject {
    static let shared = ReadingPlanService()

    @Published var availablePlans: [ReadingPlan] = []
    @Published var userProgress: [UserPlanProgress] = []

    private let userDefaultsKey = "userReadingPlanProgress"

    private init() {
        loadAvailablePlans()
        loadUserProgress()
    }

    // MARK: - Available Plans

    private func loadAvailablePlans() {
        availablePlans = [
            createGospelTourPlan(),
            createPsalmsMonthPlan(),
            createNewTestamentPlan(),
            createProverbsWisdomPlan()
        ]
    }

    // MARK: - User Progress

    private func loadUserProgress() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([UserPlanProgress].self, from: data) {
            userProgress = decoded
        }
    }

    private func saveUserProgress() {
        if let encoded = try? JSONEncoder().encode(userProgress) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func startPlan(_ plan: ReadingPlan) {
        // Check if already started
        if userProgress.contains(where: { $0.planId == plan.id }) {
            return
        }

        let progress = UserPlanProgress(planId: plan.id)
        userProgress.append(progress)
        saveUserProgress()
    }

    func markDayComplete(planId: UUID, day: Int) {
        guard let index = userProgress.firstIndex(where: { $0.planId == planId }) else {
            return
        }

        userProgress[index].completedDays.insert(day)
        userProgress[index].lastReadDate = Date()
        saveUserProgress()
    }

    func isDayComplete(planId: UUID, day: Int) -> Bool {
        guard let progress = userProgress.first(where: { $0.planId == planId }) else {
            return false
        }
        return progress.completedDays.contains(day)
    }

    func getProgress(for planId: UUID) -> UserPlanProgress? {
        return userProgress.first(where: { $0.planId == planId })
    }

    func deletePlanProgress(_ planId: UUID) {
        userProgress.removeAll(where: { $0.planId == planId })
        saveUserProgress()
    }

    // MARK: - Pre-built Plans

    private func createGospelTourPlan() -> ReadingPlan {
        let readings: [DailyReading] = [
            DailyReading(day: 1, title: "The Birth of Jesus", readings: [
                ReadingReference(book: "Matthew", startChapter: 1, endChapter: 2),
                ReadingReference(book: "Luke", startChapter: 1, endChapter: 2)
            ]),
            DailyReading(day: 2, title: "Jesus Begins His Ministry", readings: [
                ReadingReference(book: "Matthew", startChapter: 3, endChapter: 4),
                ReadingReference(book: "Mark", startChapter: 1)
            ]),
            DailyReading(day: 3, title: "The Sermon on the Mount", readings: [
                ReadingReference(book: "Matthew", startChapter: 5, endChapter: 7)
            ]),
            DailyReading(day: 4, title: "Miracles and Parables", readings: [
                ReadingReference(book: "Matthew", startChapter: 8, endChapter: 9),
                ReadingReference(book: "Luke", startChapter: 8)
            ]),
            DailyReading(day: 5, title: "The Good Shepherd", readings: [
                ReadingReference(book: "John", startChapter: 10),
                ReadingReference(book: "Luke", startChapter: 15)
            ]),
            DailyReading(day: 6, title: "The Last Supper", readings: [
                ReadingReference(book: "John", startChapter: 13, endChapter: 14),
                ReadingReference(book: "Matthew", startChapter: 26)
            ]),
            DailyReading(day: 7, title: "The Crucifixion", readings: [
                ReadingReference(book: "Luke", startChapter: 23),
                ReadingReference(book: "John", startChapter: 19)
            ]),
            DailyReading(day: 8, title: "The Resurrection", readings: [
                ReadingReference(book: "Matthew", startChapter: 28),
                ReadingReference(book: "John", startChapter: 20, endChapter: 21)
            ])
        ]

        return ReadingPlan(
            title: "Gospel Tour",
            description: "Experience the life of Jesus through key moments in the four Gospels",
            duration: 8,
            category: .overview,
            dailyReadings: readings
        )
    }

    private func createPsalmsMonthPlan() -> ReadingPlan {
        var readings: [DailyReading] = []

        for day in 1...30 {
            let psalm = (day - 1) * 5 + 1
            let endPsalm = min(psalm + 4, 150)

            readings.append(DailyReading(
                day: day,
                title: "Day \(day)",
                readings: [
                    ReadingReference(book: "Psalms", startChapter: psalm, endChapter: endPsalm)
                ]
            ))
        }

        return ReadingPlan(
            title: "Psalms in a Month",
            description: "Read through all 150 Psalms in 30 days of worship and reflection",
            duration: 30,
            category: .devotional,
            dailyReadings: readings
        )
    }

    private func createNewTestamentPlan() -> ReadingPlan {
        let readings: [DailyReading] = [
            // Gospels
            DailyReading(day: 1, title: "Matthew 1-7", readings: [ReadingReference(book: "Matthew", startChapter: 1, endChapter: 7)]),
            DailyReading(day: 2, title: "Matthew 8-14", readings: [ReadingReference(book: "Matthew", startChapter: 8, endChapter: 14)]),
            DailyReading(day: 3, title: "Matthew 15-21", readings: [ReadingReference(book: "Matthew", startChapter: 15, endChapter: 21)]),
            DailyReading(day: 4, title: "Matthew 22-28", readings: [ReadingReference(book: "Matthew", startChapter: 22, endChapter: 28)]),
            DailyReading(day: 5, title: "Mark 1-8", readings: [ReadingReference(book: "Mark", startChapter: 1, endChapter: 8)]),
            DailyReading(day: 6, title: "Mark 9-16", readings: [ReadingReference(book: "Mark", startChapter: 9, endChapter: 16)]),
            DailyReading(day: 7, title: "Luke 1-6", readings: [ReadingReference(book: "Luke", startChapter: 1, endChapter: 6)]),
            DailyReading(day: 8, title: "Luke 7-12", readings: [ReadingReference(book: "Luke", startChapter: 7, endChapter: 12)]),
            DailyReading(day: 9, title: "Luke 13-18", readings: [ReadingReference(book: "Luke", startChapter: 13, endChapter: 18)]),
            DailyReading(day: 10, title: "Luke 19-24", readings: [ReadingReference(book: "Luke", startChapter: 19, endChapter: 24)]),
            DailyReading(day: 11, title: "John 1-7", readings: [ReadingReference(book: "John", startChapter: 1, endChapter: 7)]),
            DailyReading(day: 12, title: "John 8-14", readings: [ReadingReference(book: "John", startChapter: 8, endChapter: 14)]),
            DailyReading(day: 13, title: "John 15-21", readings: [ReadingReference(book: "John", startChapter: 15, endChapter: 21)]),
            // Acts
            DailyReading(day: 14, title: "Acts 1-7", readings: [ReadingReference(book: "Acts", startChapter: 1, endChapter: 7)]),
            DailyReading(day: 15, title: "Acts 8-14", readings: [ReadingReference(book: "Acts", startChapter: 8, endChapter: 14)]),
            DailyReading(day: 16, title: "Acts 15-21", readings: [ReadingReference(book: "Acts", startChapter: 15, endChapter: 21)]),
            DailyReading(day: 17, title: "Acts 22-28", readings: [ReadingReference(book: "Acts", startChapter: 22, endChapter: 28)]),
            // Paul's Letters
            DailyReading(day: 18, title: "Romans 1-8", readings: [ReadingReference(book: "Romans", startChapter: 1, endChapter: 8)]),
            DailyReading(day: 19, title: "Romans 9-16", readings: [ReadingReference(book: "Romans", startChapter: 9, endChapter: 16)]),
            DailyReading(day: 20, title: "1 Corinthians", readings: [ReadingReference(book: "1 Corinthians", startChapter: 1, endChapter: 16)]),
            DailyReading(day: 21, title: "2 Corinthians", readings: [ReadingReference(book: "2 Corinthians", startChapter: 1, endChapter: 13)]),
            DailyReading(day: 22, title: "Galatians & Ephesians", readings: [
                ReadingReference(book: "Galatians", startChapter: 1, endChapter: 6),
                ReadingReference(book: "Ephesians", startChapter: 1, endChapter: 6)
            ]),
            DailyReading(day: 23, title: "Philippians & Colossians", readings: [
                ReadingReference(book: "Philippians", startChapter: 1, endChapter: 4),
                ReadingReference(book: "Colossians", startChapter: 1, endChapter: 4)
            ]),
            DailyReading(day: 24, title: "1 & 2 Thessalonians", readings: [
                ReadingReference(book: "1 Thessalonians", startChapter: 1, endChapter: 5),
                ReadingReference(book: "2 Thessalonians", startChapter: 1, endChapter: 3)
            ]),
            DailyReading(day: 25, title: "1 & 2 Timothy", readings: [
                ReadingReference(book: "1 Timothy", startChapter: 1, endChapter: 6),
                ReadingReference(book: "2 Timothy", startChapter: 1, endChapter: 4)
            ]),
            DailyReading(day: 26, title: "Titus & Philemon & Hebrews 1-7", readings: [
                ReadingReference(book: "Titus", startChapter: 1, endChapter: 3),
                ReadingReference(book: "Philemon", startChapter: 1),
                ReadingReference(book: "Hebrews", startChapter: 1, endChapter: 7)
            ]),
            DailyReading(day: 27, title: "Hebrews 8-13 & James", readings: [
                ReadingReference(book: "Hebrews", startChapter: 8, endChapter: 13),
                ReadingReference(book: "James", startChapter: 1, endChapter: 5)
            ]),
            DailyReading(day: 28, title: "1 & 2 Peter", readings: [
                ReadingReference(book: "1 Peter", startChapter: 1, endChapter: 5),
                ReadingReference(book: "2 Peter", startChapter: 1, endChapter: 3)
            ]),
            DailyReading(day: 29, title: "1, 2, 3 John & Jude", readings: [
                ReadingReference(book: "1 John", startChapter: 1, endChapter: 5),
                ReadingReference(book: "2 John", startChapter: 1),
                ReadingReference(book: "3 John", startChapter: 1),
                ReadingReference(book: "Jude", startChapter: 1)
            ]),
            DailyReading(day: 30, title: "Revelation", readings: [ReadingReference(book: "Revelation", startChapter: 1, endChapter: 22)])
        ]

        return ReadingPlan(
            title: "New Testament in 30 Days",
            description: "Read the entire New Testament in one month",
            duration: 30,
            category: .sequential,
            dailyReadings: readings
        )
    }

    private func createProverbsWisdomPlan() -> ReadingPlan {
        var readings: [DailyReading] = []

        for day in 1...31 {
            readings.append(DailyReading(
                day: day,
                title: "Day \(day) - Proverbs \(day)",
                readings: [
                    ReadingReference(book: "Proverbs", startChapter: day)
                ]
            ))
        }

        return ReadingPlan(
            title: "Proverbs Wisdom",
            description: "One chapter of Proverbs each day for a month of wisdom",
            duration: 31,
            category: .devotional,
            dailyReadings: readings
        )
    }
}
