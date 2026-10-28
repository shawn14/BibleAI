import SwiftUI

struct VerseStudySheet: View {
    let verse: BibleVerse
    @Environment(\.dismiss) private var dismiss
    @State private var selected: StudyMode?
    @State private var answer: String?
    @State private var error: String?
    @State private var loading = false

    private enum StudyMode: String, CaseIterable, Identifiable {
        case meaning = "Explain This Verse"
        case context = "Historical Context"
        case related = "Related Scripture"
        case language = "Original Language"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .meaning: return "text.alignleft"
            case .context: return "clock"
            case .related: return "link"
            case .language: return "character.book.closed"
            }
        }
        var instruction: String {
            switch self {
            case .meaning: return "Explain this verse in plain language, then give one reflection question."
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
                        Text("AI-assisted study · Read alongside the chapter")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Verse Study")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func study(_ mode: StudyMode) {
        selected = mode
        answer = nil
        error = nil
        guard AIService.shared.isConfigured else {
            error = "Verse study is currently unavailable. You can still read, save, and share Scripture."
            return
        }
        loading = true
        Task {
            do {
                answer = try await AIService.shared.sendMessage(conversation: [], userMessage:
                    "Study \(verse.fullReference): \(verse.text)\n\(mode.instruction)")
            } catch { self.error = error.localizedDescription }
            loading = false
        }
    }
}
