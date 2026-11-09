import SwiftUI
import UIKit

/// The artwork uses natural height so the whole verse survives both preview and export.
struct ScriptureShareView: View {
    let verse: BibleVerse
    @Environment(\.dismiss) private var dismiss
    @State private var night = false
    @State private var activity: ShareActivity?
    @State private var message: String?
    @State private var link: SharedScriptureLink?
    @State private var handledActivity: UUID?

    init(verse: BibleVerse) {
        self.verse = verse
        _link = State(initialValue: SharedScriptureLink(verse: verse))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("A little light for someone you love.").font(.title2.weight(.semibold))
                    VerseShareArtwork(verse: verse, night: night).accessibilityIdentifier("share.preview")
                    Picker("Appearance", selection: $night) {
                        Text("Paper").tag(false)
                        Text("Night").tag(true)
                    }.pickerStyle(.segmented).accessibilityIdentifier("share.theme")
                    Text(verse.translation == "KJV"
                         ? "Includes this verse, its reference, and a link to read it in BibleAI. Your notes stay private."
                         : "Shares the \(verse.translation) text and image. The BibleAI invitation opens the same passage in KJV.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(24)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    if let message {
                        Text(message).font(.footnote).foregroundStyle(.secondary)
                            .accessibilityIdentifier("share.status")
                    }
                    Button(action: share) {
                        Label("Share Verse", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity).padding(.vertical, 7)
                    }.buttonStyle(.borderedProminent).accessibilityIdentifier("share.send")
                }.padding().background(Color(.systemBackground))
            }
            .navigationTitle("Share a Verse").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("share.close") }
            }
            .sheet(item: $activity) { item in
                ActivityShareView(items: item.items) { outcome in finish(outcome, id: item.id) }
                    .interactiveDismissDisabled()
            }
        }
    }

    @MainActor private func share() {
        message = nil
        var items: [Any] = []
        let renderer = ImageRenderer(content: VerseShareArtwork(verse: verse, night: night)
            .frame(width: 360).environment(\.dynamicTypeSize, .large))
        renderer.scale = 3
        renderer.isOpaque = true
        if let image = renderer.uiImage { items.append(image) }
        else { message = "The artwork could not be created. You can still share the verse as text." }
        var text = "\(verse.text)\n\n\(verse.fullReference)\n\nBibleAI"
        if let link {
            if verse.translation != "KJV" { text += "\nRead this passage in KJV:" }
            text += "\n\(link.webURL.absoluteString)"
        }
        else { message = "A reading link is unavailable for this passage. The verse can still be shared." }
        items.append(text)
        if let link { GrowthStore.shared.record(.sharePresented, for: link) }
        handledActivity = nil
        activity = ShareActivity(items: items)
    }

    private func finish(_ outcome: ShareActivityOutcome, id: UUID) {
        guard handledActivity == nil else { return }
        handledActivity = id
        if let link { recordShareOutcome(outcome, link: link) }
        message = outcome.message
        activity = nil
    }


}

struct PlanInvitationShareView: View {
    let plan: ReadingPlan
    @Environment(\.dismiss) private var dismiss
    @State private var activity: ShareActivity?
    @State private var link: SharedScriptureLink?
    @State private var handledActivity: UUID?
    @State private var message: String?

    init(plan: ReadingPlan) {
        self.plan = plan
        _link = State(initialValue: SharedScriptureLink(plan: plan))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "book.pages").font(.largeTitle).foregroundStyle(.tint)
                    Text("Read this with someone.").font(.system(.largeTitle, design: .serif))
                    Text(plan.title).font(.title2.weight(.semibold))
                    Text("\(plan.duration) days · A shared rhythm, at your own pace").font(.subheadline).foregroundStyle(.secondary)
                    Text(plan.description)
                    if let first = plan.dailyReadings.first {
                        Divider()
                        Text("Start with \(first.title)").font(.headline)
                        Text(first.readings.map(\.displayText).joined(separator: ", "))
                    }
                    Text("Send the plan to someone you’d like to read with. Each person keeps their own progress; notes and activity are not shared.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(24)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    if let message {
                        Text(message).font(.footnote).foregroundStyle(.secondary)
                            .accessibilityIdentifier("share.status")
                    }
                    Button(action: share) {
                        Label("Invite Someone", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity).padding(.vertical, 7)
                    }.buttonStyle(.borderedProminent).accessibilityIdentifier("share.send")
                }.padding().background(Color(.systemBackground))
            }
            .navigationTitle("Share a Plan").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("share.close") }
            }
            .sheet(item: $activity) { item in
                ActivityShareView(items: item.items) { outcome in
                    guard handledActivity == nil else { return }
                    handledActivity = item.id
                    if let link { recordShareOutcome(outcome, link: link) }
                    message = outcome.message
                    activity = nil
                }
                .interactiveDismissDisabled()
            }
        }
    }

    private func share() {
        guard let link else { message = "This plan's reading link is unavailable."; return }
        let text = "Read \(plan.title) with me on BibleAI. \(plan.duration) days of Scripture, at your own pace.\n\n\(link.webURL.absoluteString)"
        GrowthStore.shared.record(.sharePresented, for: link)
        handledActivity = nil
        message = nil
        activity = ShareActivity(items: [text])
    }
}

private struct VerseShareArtwork: View {
    let verse: BibleVerse
    let night: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("BIBLEAI").font(.system(size: 11, weight: .semibold)).tracking(3)
            Text(verse.text).font(.system(size: 27, weight: .regular, design: .serif))
                .lineSpacing(6).minimumScaleFactor(0.85).fixedSize(horizontal: false, vertical: true)
            Text(verse.fullReference).font(.system(size: 13, weight: .medium))
            Spacer(minLength: 8)
            Text("A moment in Scripture.").font(.system(size: 11)).opacity(0.7)
        }
        .padding(32).frame(maxWidth: .infinity, minHeight: 440, alignment: .topLeading)
        .foregroundStyle(night ? Color(red: 0.95, green: 0.91, blue: 0.82) : Color(red: 0.16, green: 0.20, blue: 0.17))
        .background(night ? Color(red: 0.10, green: 0.15, blue: 0.13) : Color(red: 0.97, green: 0.95, blue: 0.89))
        .accessibilityElement(children: .combine)
    }
}

private struct ShareActivity: Identifiable {
    let id = UUID()
    let items: [Any]
}

enum ShareActivityOutcome {
    case completed, cancelled, failed(String)
    var message: String? {
        switch self {
        case .completed: return "Share activity completed."
        case .cancelled: return nil
        case .failed: return "Sharing did not finish. Please try again."
        }
    }
}

@MainActor private func recordShareOutcome(_ outcome: ShareActivityOutcome, link: SharedScriptureLink) {
    switch outcome {
    case .completed: GrowthStore.shared.record(.shareCompleted, for: link)
    case .cancelled: GrowthStore.shared.record(.shareCancelled, for: link)
    case .failed: GrowthStore.shared.record(.shareFailed, for: link)
    }
}

/// UIKit supplies the outcome after dismissal. SwiftUI onDismiss must not preempt it with
/// a cancellation; its sheet teardown can occur before the MainActor callback is delivered.
/// Interactive outer-sheet dismissal is disabled; the system share sheet's Close remains available.
struct ActivityShareView: UIViewControllerRepresentable {
    let items: [Any]
    let completion: @MainActor (ShareActivityOutcome) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        controller.completionWithItemsHandler = { _, completed, _, error in
            let outcome: ShareActivityOutcome = error.map { .failed($0.localizedDescription) } ?? (completed ? .completed : .cancelled)
            Task { @MainActor in completion(outcome) }
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}
