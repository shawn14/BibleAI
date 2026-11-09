import Foundation

/// Merge rules for iCloud sync. Every device keeps a full copy; merges are unions so two devices
/// never drop each other's additions. Deletions travel as tombstones (key -> deletion time) so a
/// removed verse or plan does not come back from another device's older copy.
enum CloudSyncMerge {
    typealias Tombstones = [String: Double]

    static func verseKey(_ h: Highlight) -> String {
        let passage = "\(h.book)|\(h.chapter)|\(h.verse)"
        return h.citationEdition == "KJV" ? passage : "\(passage)|\(h.citationEdition)"
    }

    /// One saved verse per reference; the most recently edited copy wins (its note and color).
    static func highlights(_ a: [Highlight], _ b: [Highlight], deleted: Tombstones) -> [Highlight] {
        var byKey: [String: Highlight] = [:]
        for h in a + b {
            let k = verseKey(h)
            if let current = byKey[k], current.updatedAt >= h.updatedAt { continue }
            byKey[k] = h
        }
        return byKey.values
            .filter { h in deleted[verseKey(h)].map { $0 < h.updatedAt.timeIntervalSince1970 } ?? true }
            .sorted { ($0.createdAt, verseKey($0)) > ($1.createdAt, verseKey($1)) }
    }

    /// One progress record per plan: completed days are unioned, the earliest start and latest read kept.
    static func plans(_ a: [UserPlanProgress], _ b: [UserPlanProgress], deleted: Tombstones) -> [UserPlanProgress] {
        var byPlan: [UUID: UserPlanProgress] = [:]
        var order: [UUID] = []
        for p in a + b {
            guard let current = byPlan[p.planId] else { byPlan[p.planId] = p; order.append(p.planId); continue }
            byPlan[p.planId] = UserPlanProgress(
                id: current.id, planId: current.planId,
                startedDate: min(current.startedDate, p.startedDate),
                completedDays: current.completedDays.union(p.completedDays),
                lastReadDate: [current.lastReadDate, p.lastReadDate].compactMap { $0 }.max())
        }
        return order.compactMap { byPlan[$0] }.filter { p in
            guard let removed = deleted[p.planId.uuidString] else { return true }
            return max(p.startedDate, p.lastReadDate ?? p.startedDate).timeIntervalSince1970 > removed
        }
    }

    static func tombstones(_ a: Tombstones, _ b: Tombstones) -> Tombstones { a.merging(b, uniquingKeysWith: max) }

    static func days(_ a: [String], _ b: [String]) -> [String] { Array(Set(a).union(b)).sorted() }

    /// Order-independent fingerprints, so re-encoding the same data never counts as a change.
    static func fingerprint(_ highlights: [Highlight]) -> [String] {
        highlights.map { "\(verseKey($0))|\($0.color.rawValue)|\($0.note ?? "")|\($0.updatedAt.timeIntervalSince1970)" }.sorted()
    }
    static func fingerprint(_ plans: [UserPlanProgress]) -> [String] {
        plans.map { "\($0.planId)|\($0.startedDate.timeIntervalSince1970)|\($0.completedDays.sorted())|\($0.lastReadDate?.timeIntervalSince1970 ?? 0)" }.sorted()
    }
}
