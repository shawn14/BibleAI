import Foundation
import UserNotifications

/// The daily "time to read" notification chosen in onboarding (and changeable in Settings).
enum DailyReminder: String, CaseIterable, Identifiable {
    case off, morning, midday, evening
    var id: String { rawValue }
    static let key = "dailyReminder.slot"
    private static let identifier = "bibleai.daily-reading"

    var title: String {
        switch self {
        case .off: return "Off"
        case .morning: return "Morning"
        case .midday: return "Midday"
        case .evening: return "Evening"
        }
    }
    var detail: String {
        switch self {
        case .off: return "No daily reminder"
        case .morning: return "8:00 AM, start the day in the Word"
        case .midday: return "12:30 PM, a pause in the middle of the day"
        case .evening: return "8:00 PM, end the day with Scripture"
        }
    }
    var time: (hour: Int, minute: Int)? {
        switch self {
        case .off: return nil
        case .morning: return (8, 0)
        case .midday: return (12, 30)
        case .evening: return (20, 0)
        }
    }

    static var current: DailyReminder {
        DailyReminder(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .off
    }

    /// Saves the choice and (re)schedules the repeating notification. Asks for permission if needed.
    static func set(_ slot: DailyReminder) async {
        UserDefaults.standard.set(slot.rawValue, forKey: key)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard let time = slot.time else { return }
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }
        let content = UNMutableNotificationContent()
        content.title = "Time for today's reading"
        content.body = "A few minutes in the Word. Keep your streak going."
        content.sound = .default
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        let request = UNNotificationRequest(identifier: identifier, content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
        try? await center.add(request)
    }
}
