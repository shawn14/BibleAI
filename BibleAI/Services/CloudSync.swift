import Foundation

/// Keeps saved verses, notes, reading-plan progress, the streak and the reading place in the user's
/// own iCloud (key-value store). There is no account: it follows the Apple ID, restores on a new
/// iPhone and syncs iPhone <-> iPad. Without iCloud it does nothing and the app stays device-only.
final class CloudSync {
    static let shared = CloudSync()
    /// Posted on the main thread when another device's data was merged into this device.
    static let didChange = Notification.Name("CloudSync.didChange")

    enum Key: String, CaseIterable {
        case highlights = "saved_highlights"
        case highlightsDeleted = "saved_highlights.deleted"
        case plans = "userReadingPlanProgress"
        case plansDeleted = "userReadingPlanProgress.deleted"
        case streak = "streak.readingDays"
        case place = "scripture.readingPlace.v1"
        case onboarded = "hasCompletedOnboarding"
    }

    private let cloud = NSUbiquitousKeyValueStore.default
    private let local = UserDefaults.standard
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        NotificationCenter.default.addObserver(self, selector: #selector(cloudChanged(_:)),
                                               name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud)
        cloud.synchronize()
        reconcile(Key.allCases, cloudWinsPlace: false)
    }

    /// Call after writing a synced key locally.
    func push(_ keys: Key...) { reconcile(keys, cloudWinsPlace: false, pushPlace: true) }

    /// Record a deletion so other devices drop the item instead of restoring it.
    func recordDeletion(_ key: Key, id: String) {
        var stones = tombstones(local.data(forKey: key.rawValue))
        stones[id] = Date().timeIntervalSince1970
        local.set(encode(stones), forKey: key.rawValue)
    }

    @objc private func cloudChanged(_ note: Notification) {
        let changed = (note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]) ?? []
        let keys = changed.compactMap(Key.init(rawValue:))
        DispatchQueue.main.async { self.reconcile(keys.isEmpty ? Key.allCases : keys, cloudWinsPlace: true) }
    }

    private func reconcile(_ keys: [Key], cloudWinsPlace: Bool, pushPlace: Bool = false) {
        var changedLocally = false
        let deletedHighlights = CloudSyncMerge.tombstones(tombstones(local.data(forKey: Key.highlightsDeleted.rawValue)),
                                                          tombstones(cloud.data(forKey: Key.highlightsDeleted.rawValue)))
        let deletedPlans = CloudSyncMerge.tombstones(tombstones(local.data(forKey: Key.plansDeleted.rawValue)),
                                                     tombstones(cloud.data(forKey: Key.plansDeleted.rawValue)))
        var all = Set(keys)
        if all.contains(.highlightsDeleted) { all.insert(.highlights) }
        if all.contains(.plansDeleted) { all.insert(.plans) }
        if all.contains(.highlights) { all.insert(.highlightsDeleted) }
        if all.contains(.plans) { all.insert(.plansDeleted) }
        for key in all {
            let name = key.rawValue
            switch key {
            case .highlightsDeleted, .plansDeleted:
                let merged = key == .highlightsDeleted ? deletedHighlights : deletedPlans
                if tombstones(local.data(forKey: name)) != merged { local.set(encode(merged), forKey: name) }
                if tombstones(cloud.data(forKey: name)) != merged { cloud.set(encode(merged), forKey: name) }
            case .highlights:
                let mine = decode([Highlight].self, local.data(forKey: name)), theirs = decode([Highlight].self, cloud.data(forKey: name))
                let merged = CloudSyncMerge.highlights(mine, theirs, deleted: deletedHighlights)
                let fp = CloudSyncMerge.fingerprint(merged)
                if CloudSyncMerge.fingerprint(mine) != fp { local.set(encode(merged), forKey: name); changedLocally = true }
                if CloudSyncMerge.fingerprint(theirs) != fp || cloud.data(forKey: name) == nil && !merged.isEmpty { cloud.set(encode(merged), forKey: name) }
            case .plans:
                let mine = decode([UserPlanProgress].self, local.data(forKey: name)), theirs = decode([UserPlanProgress].self, cloud.data(forKey: name))
                let merged = CloudSyncMerge.plans(mine, theirs, deleted: deletedPlans)
                let fp = CloudSyncMerge.fingerprint(merged)
                if CloudSyncMerge.fingerprint(mine) != fp { local.set(encode(merged), forKey: name); changedLocally = true }
                if CloudSyncMerge.fingerprint(theirs) != fp || cloud.data(forKey: name) == nil && !merged.isEmpty { cloud.set(encode(merged), forKey: name) }
            case .streak:
                let mine = local.stringArray(forKey: name) ?? [], theirs = (cloud.array(forKey: name) as? [String]) ?? []
                let merged = CloudSyncMerge.days(mine, theirs)
                if Set(mine) != Set(merged) { local.set(merged, forKey: name); changedLocally = true }
                if Set(theirs) != Set(merged) { cloud.set(merged, forKey: name) }
            case .place:
                // Last place read: this device's position is pushed as you read; another device's
                // newer position is taken when it arrives (the reader opens there next launch).
                let mine = local.data(forKey: name), theirs = cloud.data(forKey: name)
                if pushPlace, let mine, mine != theirs { cloud.set(mine, forKey: name) }
                else if let theirs, mine == nil || (cloudWinsPlace && theirs != mine) { local.set(theirs, forKey: name) }
                else if theirs == nil, let mine { cloud.set(mine, forKey: name) }
            case .onboarded:
                let merged = local.bool(forKey: name) || cloud.bool(forKey: name)
                if merged && !local.bool(forKey: name) { local.set(true, forKey: name) }
                if merged && !cloud.bool(forKey: name) { cloud.set(true, forKey: name) }
            }
        }
        if changedLocally { NotificationCenter.default.post(name: Self.didChange, object: nil) }
    }

    private func tombstones(_ data: Data?) -> CloudSyncMerge.Tombstones {
        data.flatMap { try? JSONDecoder().decode(CloudSyncMerge.Tombstones.self, from: $0) } ?? [:]
    }
    private func decode<T: Decodable>(_ type: [T].Type, _ data: Data?) -> [T] {
        data.flatMap { try? JSONDecoder().decode(type, from: $0) } ?? []
    }
    private func encode<T: Encodable>(_ value: T) -> Data { (try? JSONEncoder().encode(value)) ?? Data() }
}
