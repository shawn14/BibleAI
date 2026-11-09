import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Verse study runs on Apple Intelligence on the device: no API key, no server, nothing leaves the phone.
enum AppleStudy {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), case .available = SystemLanguageModel.default.availability { return true }
        #endif
        return false
    }

    static var unavailableReason: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return ""
            case .unavailable(let reason):
                switch reason {
                case .appleIntelligenceNotEnabled:
                    return "Turn on Apple Intelligence in Settings to use verse study. You can still read, save and share Scripture."
                case .modelNotReady:
                    return "Apple Intelligence is still getting ready on this iPhone. Try again in a few minutes."
                case .deviceNotEligible:
                    return "Verse study uses Apple Intelligence, which needs iPhone 15 Pro or newer. You can still read, save and share Scripture."
                @unknown default:
                    return "Verse study isn't available on this iPhone right now."
                }
            }
        }
        #endif
        return "Verse study uses Apple Intelligence, which needs iOS 26 on iPhone 15 Pro or newer. You can still read, save and share Scripture."
    }

    static func study(_ prompt: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession(instructions: """
                You are a careful, warm Bible study guide for everyday readers. Use the cited translation and the \
                text you are given. Write plain, concise prose with short paragraphs. Distinguish what the \
                text says from interpretation, and note where Christian traditions differ. Never invent \
                quotations, statistics, Strong's numbers or sources. Only cite Bible references you are sure of.
                """)
            let response = try await session.respond(to: prompt)
            return response.content
        }
        #endif
        throw StudyUnavailable()
    }

    struct StudyUnavailable: LocalizedError {
        var errorDescription: String? { AppleStudy.unavailableReason }
    }
}

struct VerseStudySheet: View {
    let verse: BibleVerse
    @Environment(\.dismiss) private var dismiss
    @State private var selected: StudyMode?
    @State private var answer: String?
    @State private var error: String?
    @State private var loading = false
    @State private var showPaywall = false

    private enum StudyMode: String, CaseIterable, Identifiable {
        case meaning = "Explain This Verse"
        case simpler = "Explain It Simply"
        case context = "Historical Context"
        case related = "Related Scripture"
        case language = "Original Language"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .meaning: return "text.alignleft"
            case .simpler: return "lightbulb"
            case .context: return "clock"
            case .related: return "link"
            case .language: return "character.book.closed"
            }
        }
        var instruction: String {
            switch self {
            case .meaning: return "Explain this verse in plain language, then give one reflection question."
            case .simpler: return "Explain this verse as simply as possible, as if to a new reader, in under 80 words. Then give one everyday way to live it out."
            case .context: return "Explain the historical and literary context. Distinguish established facts from disputed interpretations."
            case .related: return "Give three related Bible references and explain the connection. Do not invent quotations."
            case .language: return "Discuss key words in the original language. Clearly label uncertain meanings. Do not invent an interlinear text or Strong's numbers."
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(verse.text).font(.system(.title3, design: .serif)).lineSpacing(5)
                    Text(verse.fullReference).font(.subheadline).foregroundStyle(.secondary)
                    Divider()
                    if let guide = GospelTourGuide.study(for: verse) {
                        NavigationLink {
                            StudyDetailView(study: guide, canSave: true)
                        } label: { Label(guide.title, systemImage: "book.pages") }
                        .accessibilityIdentifier("study.guide")
                    }
                    ForEach(StudyMode.allCases) { mode in
                        Button { study(mode) } label: {
                            HStack {
                                Label(mode.rawValue, systemImage: mode.icon)
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                            }
                            .frame(minHeight: 44)
                        }
                        .disabled(loading)
                        .accessibilityIdentifier("study.\(mode.id)")
                    }
                    if loading { ProgressView("Preparing your study…") }
                    if let error {
                        Text(error).foregroundStyle(.secondary)
                        if let selected { Button("Try Again") { study(selected) } }
                    }
                    if let answer, let selected {
                        Divider()
                        Text(selected.rawValue).font(.title2.bold())
                        Text(.init(answer)).textSelection(.enabled).lineSpacing(4)
                            .accessibilityIdentifier("study.answer")
                        Text("Apple Intelligence study · Read alongside the chapter")
                            .font(.caption).foregroundStyle(.secondary)
                        StudySaveButton(study: SavedStudy(verse: verse, source: .generated,
                                                         title: selected.rawValue, body: answer))
                        Link(destination: reportURL(mode: selected, answer: answer)) {
                            Label("Report a problem with this study", systemImage: "flag")
                                .font(.footnote)
                        }
                        .accessibilityIdentifier("study.report")
                    }
                }
                .padding(24)
            }
            .navigationTitle("Verse Study")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .sheet(isPresented: $showPaywall) { PaywallView(isPresented: $showPaywall) }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func reportURL(mode: StudyMode, answer: String) -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "support@bibleaicompanion.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Study report: \(verse.fullReference)"),
            URLQueryItem(name: "body", value: "What's wrong with this study?\n\n\n---\n\(mode.rawValue) · \(verse.fullReference)\n\(answer.prefix(1500))")
        ]
        return components.url ?? URL(string: "mailto:support@bibleaicompanion.com")!
    }

    private func study(_ mode: StudyMode) {
        selected = mode
        answer = nil
        error = nil
        guard AppleStudy.isAvailable else {
            error = AppleStudy.unavailableReason
            return
        }
        let subscriptions = RevenueCatManager.shared
        guard subscriptions.canAskQuestion() else {
            error = "You've used today's \(subscriptions.freeQuestionsPerDay) free studies. Premium unlocks unlimited studies."
            showPaywall = true
            return
        }
        loading = true
        Task {
            do {
                answer = try await AppleStudy.study(
                    "Study \(verse.fullReference): \"\(verse.text)\"\n\(mode.instruction)")
                subscriptions.incrementQuestionCount()
            } catch {
                self.error = (error as? LocalizedError)?.errorDescription.flatMap { $0.isEmpty ? nil : $0 }
                    ?? "This study couldn't be prepared. Please try again or pick another study."
            }
            loading = false
        }
    }
}
