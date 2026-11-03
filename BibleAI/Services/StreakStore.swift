import Foundation

/// Days the reader finished a plan reading, stored on the device. A streak is consecutive calendar
/// days ending today (or yesterday, so it isn't lost before today's reading).
final class StreakStore: ObservableObject {
    static let shared = StreakStore()
    var currentStreakDescription: String {
        let days = currentStreak()
        return "\(days) " + (days == 1 ? "day" : "days")
    }

    private let key = "streak.readingDays"
    @Published private(set) var days: Set<String>

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init(defaults: UserDefaults = .standard) {
        days = Set(defaults.stringArray(forKey: key) ?? [])
        NotificationCenter.default.addObserver(forName: CloudSync.didChange, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.days = Set(UserDefaults.standard.stringArray(forKey: self.key) ?? [])
        }
    }

    static func dayKey(_ date: Date) -> String { formatter.string(from: date) }

    func recordReading(on date: Date = Date()) {
        days.insert(Self.dayKey(date))
        UserDefaults.standard.set(Array(days).sorted(), forKey: key)
        CloudSync.shared.push(.streak)
    }

    func didRead(on date: Date) -> Bool { days.contains(Self.dayKey(date)) }

    func currentStreak(asOf today: Date = Date(), calendar: Calendar = .current) -> Int {
        var day = calendar.startOfDay(for: today)
        if !didRead(on: day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day), didRead(on: yesterday) else { return 0 }
            day = yesterday
        }
        var count = 0
        while didRead(on: day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    /// The last seven days, oldest first, ending today.
    func lastSevenDays(asOf today: Date = Date(), calendar: Calendar = .current) -> [(date: Date, read: Bool)] {
        (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: today))
        }.map { ($0, didRead(on: $0)) }
    }
}
