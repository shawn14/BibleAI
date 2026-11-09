// swiftc BibleAI/Models/Highlight.swift BibleAI/Models/ReadingPlan.swift BibleAI/Services/CloudSyncMerge.swift scripts/tests/cloudsync/main.swift
import Foundation
var failures = 0
func check(_ ok: Bool, _ what: String) { print(ok ? "PASS" : "FAIL", what); if !ok { failures += 1 } }
let t0 = Date(timeIntervalSince1970: 1_000), t1 = Date(timeIntervalSince1970: 2_000), t2 = Date(timeIntervalSince1970: 3_000)
func h(_ v: Int, note: String? = nil, at: Date) -> Highlight {
    Highlight(book: "John", chapter: 3, verse: v, verseText: "x", color: .yellow, note: note, createdAt: at, updatedAt: at)
}
// iPhone saved John 3:16, iPad saved John 3:17: both kept.
var m = CloudSyncMerge.highlights([h(16, at: t0)], [h(17, at: t1)], deleted: [:])
check(Set(m.map { $0.verse }) == [16, 17], "two devices' saved verses are unioned")
// Same verse on both; newer note wins.
m = CloudSyncMerge.highlights([h(16, note: "old", at: t0)], [h(16, note: "new", at: t1)], deleted: [:])
check(m.count == 1 && m[0].note == "new", "newer note on the same verse wins")
// Removed on one device after the other saved it: stays removed.
m = CloudSyncMerge.highlights([], [h(16, at: t0)], deleted: ["John|3|16": t1.timeIntervalSince1970])
check(m.isEmpty, "deleted verse is not restored by the other device's older copy")
// Saved again after deleting: comes back.
m = CloudSyncMerge.highlights([h(16, at: t2)], [], deleted: ["John|3|16": t1.timeIntervalSince1970])
check(m.count == 1, "re-saved after delete survives the tombstone")
// Plans: completed days unioned, earliest start, latest read.
let plan = UUID()
let a = UserPlanProgress(planId: plan, startedDate: t1, completedDays: [1, 2], lastReadDate: t1)
let b = UserPlanProgress(planId: plan, startedDate: t0, completedDays: [2, 3], lastReadDate: t2)
let p = CloudSyncMerge.plans([a], [b], deleted: [:])
check(p.count == 1 && p[0].completedDays == [1, 2, 3] && p[0].startedDate == t0 && p[0].lastReadDate == t2, "plan progress merges days, start and last read")
check(CloudSyncMerge.plans([a], [b], deleted: [plan.uuidString: t2.timeIntervalSince1970 + 1]).isEmpty, "deleted plan stays deleted")
check(CloudSyncMerge.plans([UserPlanProgress(planId: plan, startedDate: t2)], [], deleted: [plan.uuidString: t1.timeIntervalSince1970]).count == 1, "plan restarted after delete survives")
check(CloudSyncMerge.days(["2026-10-29"], ["2026-10-30", "2026-10-29"]) == ["2026-10-29", "2026-10-30"], "streak days union")
check(CloudSyncMerge.fingerprint([a]) == CloudSyncMerge.fingerprint([UserPlanProgress(id: a.id, planId: plan, startedDate: t1, completedDays: [2, 1], lastReadDate: t1)]), "fingerprint ignores set order")
check(CloudSyncMerge.tombstones(["x": 1], ["x": 5, "y": 2]) == ["x": 5, "y": 2], "tombstones keep latest deletion")
let readings = (1...3).map { DailyReading(day: $0, title: "Day \($0)", readings: []) }
let shortPlan = ReadingPlan(id: plan, title: "Plan", description: "", duration: 3, category: .sequential, dailyReadings: readings)
check(shortPlan.nextReading(completed: [])?.day == 1, "new plan starts on day one")
check(shortPlan.nextReading(completed: [1, 3])?.day == 2, "resume fills the first unfinished day")
check(shortPlan.nextReading(completed: [1, 2, 3]) == nil, "finished plan has no next day")
print(failures == 0 ? "ALL PASS" : "\(failures) FAILED"); exit(failures == 0 ? 0 : 1)
