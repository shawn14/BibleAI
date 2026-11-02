import Foundation
import Combine

/// Device-local diagnostics, not a cross-user referral database or a measured K-factor.
/// No contacts, notes, message recipients, network telemetry or automatic pasteboard access.
@MainActor
final class GrowthStore: ObservableObject {
    static let shared = GrowthStore()

    enum EventKind: String, Codable {
        case sharePresented, shareCompleted, shareCancelled, shareFailed
        case invitationOpened, invitationAccepted, firstReading
    }
    struct Event: Codable, Identifiable {
        let id: UUID
        let kind: EventKind
        let invitation: SharedScriptureLink
        let recordedAt: Date
    }
    struct Attribution: Codable {
        let invitation: SharedScriptureLink
        let openedAt: Date
        let isNewReader: Bool
        var acceptedAt: Date?
        var activatedAt: Date?
    }

    /// Random per installation, never a person/account ID. Reinstalling or clearing app data resets it.
    let installationID: UUID
    let firstSeenAt: Date
    @Published private(set) var readerActivatedAt: Date?
    @Published private(set) var pendingInvitation: SharedScriptureLink?
    @Published private(set) var acceptedInvitation: SharedScriptureLink?
    @Published private(set) var attribution: Attribution?
    @Published private(set) var events: [Event]

    static let eventLimit = 200
    private static let storageKey = "growth.local.v1"
    private let defaults: UserDefaults
    private let now: () -> Date
    private var openedInvitations: [SharedScriptureLink]
    private var acceptedInviteIDs: [UUID]
    private var eventTotals: [String: Int]

    private struct Snapshot: Codable {
        var installationID: UUID?
        var firstSeenAt: Date?
        var readerActivatedAt: Date?
        var eventTotals: [String: Int]?
        var pendingInvitation: SharedScriptureLink?
        var acceptedInvitation: SharedScriptureLink?
        var attribution: Attribution?
        var events: [Event]
        var openedInvitations: [SharedScriptureLink]
        var acceptedInviteIDs: [UUID]
    }

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        let snapshot = defaults.data(forKey: Self.storageKey)
            .flatMap { try? JSONDecoder().decode(Snapshot.self, from: $0) }
        installationID = snapshot?.installationID ?? UUID()
        firstSeenAt = snapshot?.firstSeenAt ?? now()
        readerActivatedAt = snapshot?.readerActivatedAt
        var totals = snapshot?.eventTotals ?? [:]
        if snapshot?.eventTotals == nil {
            for event in snapshot?.events ?? [] { totals[event.kind.rawValue, default: 0] += 1 }
        }
        eventTotals = totals
        pendingInvitation = snapshot?.pendingInvitation
        acceptedInvitation = snapshot?.acceptedInvitation
        attribution = snapshot?.attribution
        events = Array((snapshot?.events ?? []).suffix(Self.eventLimit))
        openedInvitations = Array((snapshot?.openedInvitations ?? []).suffix(Self.eventLimit))
        acceptedInviteIDs = Array((snapshot?.acceptedInviteIDs ?? []).suffix(Self.eventLimit))
        persist()
    }

    /// Called after real Scripture is visible, even for organic readers who never share. This supplies
    /// the eligible-installation baseline; receiving a link or merely launching the app is insufficient.
    @discardableResult
    func recordReaderActivation() -> Bool {
        guard readerActivatedAt == nil else { return false }
        readerActivatedAt = now()
        persist()
        return true
    }

    /// Explicit export only. No upload is triggered. Identical state produces identical JSON bytes.
    /// These are installation diagnostics: they cannot establish distinct people or delivered invites.
    func exportSnapshotData() throws -> Data {
        struct Export: Encodable {
            let schemaVersion: Int
            let installationID: UUID
            let firstSeenAt: Date
            let readerActivatedAt: Date?
            let attribution: Attribution?
            let pendingInvitation: SharedScriptureLink?
            let acceptedInvitation: SharedScriptureLink?
            let events: [Event]
            let counters: [String: Int]
            let retainedEventLimit: Int
            let measurementLimit: String
        }
        var counters = eventTotals
        counters["readerActivated"] = readerActivatedAt == nil ? 0 : 1
        let export = Export(schemaVersion: 1, installationID: installationID, firstSeenAt: firstSeenAt,
                            readerActivatedAt: readerActivatedAt, attribution: attribution,
                            pendingInvitation: pendingInvitation, acceptedInvitation: acceptedInvitation,
                            events: events, counters: counters, retainedEventLimit: Self.eventLimit,
                            measurementLimit: "Local installation diagnostics, not people or measured K. Reinstalling resets identity. Share completion does not prove delivery. Raw event history is bounded.")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }

    /// Receiving a link presents an invitation; it never silently starts a plan or changes reading place.
    @discardableResult
    func receive(url: URL) -> Bool {
        guard let invitation = SharedScriptureLink(url: url) else { return false }
        // A reused invitation ID cannot change its target after we have observed it.
        let known = openedInvitations + [attribution?.invitation, acceptedInvitation].compactMap { $0 }
        guard !known.contains(where: { $0.inviteID == invitation.inviteID && $0 != invitation }) else { return false }
        pendingInvitation = invitation
        let isFirstAttribution = attribution == nil
        if isFirstAttribution {
            attribution = Attribution(invitation: invitation, openedAt: now(),
                                      isNewReader: !defaults.bool(forKey: "hasCompletedOnboarding") && readerActivatedAt == nil)
        }
        if isFirstAttribution || (!openedInvitations.contains(invitation) && attribution?.invitation != invitation) {
            append(.invitationOpened, for: invitation)
        }
        if !openedInvitations.contains(invitation) {
            openedInvitations.append(invitation)
            openedInvitations = Array(openedInvitations.suffix(Self.eventLimit))
        }
        persist()
        return true
    }

    func dismissInvitation() {
        pendingInvitation = nil
        persist()
    }

    /// Explicitly accepts the presented content. The caller still needs to open the real reading.
    func completeInvitation() {
        guard let invitation = pendingInvitation else { return }
        acceptedInvitation = invitation
        pendingInvitation = nil
        if !acceptedInviteIDs.contains(invitation.inviteID)
            && !(attribution?.invitation == invitation && attribution?.acceptedAt != nil) {
            append(.invitationAccepted, for: invitation)
            acceptedInviteIDs.append(invitation.inviteID)
            acceptedInviteIDs = Array(acceptedInviteIDs.suffix(Self.eventLimit))
        }
        if attribution?.invitation == invitation, attribution?.acceptedAt == nil {
            attribution?.acceptedAt = now()
        }
        persist()
    }

    /// Call only after the exact accepted passage or an actual chapter of the accepted plan appears.
    /// At most one first acquisition activation is recorded on this device. Existing readers do not
    /// become new referrals; later invitations cannot claim the first invitation's acquisition.
    @discardableResult
    func recordFirstReading(for invitation: SharedScriptureLink) -> Bool {
        guard acceptedInvitation == invitation, attribution?.invitation == invitation,
              attribution?.isNewReader == true, attribution?.acceptedAt != nil,
              attribution?.activatedAt == nil else { return false }
        attribution?.activatedAt = now()
        append(.firstReading, for: invitation)
        persist()
        return true
    }

    /// A completed UIKit activity is not proof that a person received or read an invitation.
    func record(_ kind: EventKind, for invitation: SharedScriptureLink) {
        // Acquisition events must pass their stateful APIs; a view cannot manufacture activation.
        guard [.sharePresented, .shareCompleted, .shareCancelled, .shareFailed].contains(kind) else { return }
        append(kind, for: invitation)
        persist()
    }

    private func append(_ kind: EventKind, for invitation: SharedScriptureLink) {
        eventTotals[kind.rawValue, default: 0] += 1
        events.append(Event(id: UUID(), kind: kind, invitation: invitation, recordedAt: now()))
        events = Array(events.suffix(Self.eventLimit))
    }

    private func persist() {
        let snapshot = Snapshot(installationID: installationID, firstSeenAt: firstSeenAt,
                                readerActivatedAt: readerActivatedAt, eventTotals: eventTotals,
                                pendingInvitation: pendingInvitation, acceptedInvitation: acceptedInvitation,
                                attribution: attribution, events: events,
                                openedInvitations: openedInvitations, acceptedInviteIDs: acceptedInviteIDs)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
