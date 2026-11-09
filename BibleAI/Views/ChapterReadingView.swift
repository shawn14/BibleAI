//
//  ChapterReadingView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct ChapterReadingView: View {
    let book: BibleBookInfo
    let chapter: Int
    var invitationPlanID: UUID? = nil
    var edition: ReaderEdition = .preferred()
    var verseRange: ClosedRange<Int>? = nil
    var reflection: String? = nil
    var onFinish: (() -> Void)? = nil
    var onRead: (() -> Void)? = nil

    @StateObject private var highlightService = HighlightService.shared
    @State private var verses: [BibleVerse] = []
    @State private var isLoading = true
    @State private var fontSize: CGFloat = 16
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading \(book.name) \(chapter)...")
                    .padding()
            } else if verses.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("Chapter not available")
                        .font(.headline)

                    Button("Try Again") { Task { await loadChapter() } }
                    Text("Connect to the internet to open this chapter for the first time.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text(edition.name).font(.caption).foregroundStyle(.secondary)
                    if verseRange == nil, let first = verses.first, let guide = GospelTourGuide.study(for: first) {
                        NavigationLink {
                            StudyDetailView(study: guide, canSave: true)
                        } label: { Label(guide.title, systemImage: "book.pages") }
                        .accessibilityIdentifier("chapter.guide")
                        .padding(.vertical, 8)
                    }
                    ForEach(verses) { verse in
                        VerseRowView(
                            verse: verse,
                            book: book.name,
                            chapter: chapter,
                            fontSize: fontSize,
                            highlightService: highlightService
                        )
                    }
                    if let reflection {
                        Divider()
                        Text("Reflect").font(.headline)
                        Text(reflection).font(.body).accessibilityIdentifier("chapter.reflection")
                    }
                }
                .padding()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let onFinish, !verses.isEmpty {
                Button("Finish today’s reading", action: onFinish)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(.bar)
                    .accessibilityIdentifier("chapter.finish")
            }
        }
        .navigationTitle(ReadingReference.label(book: book.name, chapter: chapter, range: verseRange))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "textformat.size")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ReadingSettingsView(fontSize: $fontSize)
        }
        .task {
            await loadChapter()
        }
    }

    private func loadChapter() async {
        isLoading = true
        let wholeChapter = (try? await ScriptureChapterStore.shared.chapter(book: book.name, number: chapter, edition: edition)) ?? []
        guard !Task.isCancelled else { return }
        if let verseRange {
            let excerpt = wholeChapter.filter { verseRange.contains($0.verse) }
            verses = excerpt.map(\.verse) == Array(verseRange) ? excerpt : []
        } else {
            verses = wholeChapter
        }
        isLoading = false
        if !verses.isEmpty {
            GrowthStore.shared.recordReaderActivation()
            onRead?()
        }
        if !verses.isEmpty, let planID = invitationPlanID,
           let invitation = GrowthStore.shared.acceptedInvitation, invitation.planID == planID,
           let plan = ReadingPlanService.shared.availablePlans.first(where: { $0.id == planID }),
           let first = plan.dailyReadings.first?.readings.first,
           first.book == book.name, first.startChapter == chapter {
            GrowthStore.shared.recordFirstReading(for: invitation)
        }
    }
}

struct VerseRowView: View {
    let verse: BibleVerse
    let book: String
    let chapter: Int
    let fontSize: CGFloat
    @ObservedObject var highlightService: HighlightService

    @State private var showHighlightMenu = false
    @State private var showNoteEditor = false

    private var existingHighlight: Highlight? {
        highlightService.getHighlight(book: book, chapter: chapter, verse: verse.verse, translation: verse.translation)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(verse.verse)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            VStack(alignment: .leading, spacing: 4) {
                Text(verse.text)
                    .font(.system(size: fontSize, design: .serif))
                    .textSelection(.enabled)
                    .padding(8)
                    .background(existingHighlight?.color.color ?? Color.clear)
                    .cornerRadius(4)
                    .onTapGesture {
                        showHighlightMenu = true
                    }

                if let highlight = existingHighlight, let note = highlight.note, !note.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(.tint)
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding(.leading, 8)
                    .onTapGesture {
                        showNoteEditor = true
                    }
                }
            }
        }
        .confirmationDialog("Highlight Options", isPresented: $showHighlightMenu, titleVisibility: .hidden) {
            if existingHighlight != nil {
                Button("Add/Edit Note") {
                    showNoteEditor = true
                }

                Button("Remove Highlight", role: .destructive) {
                    if let highlight = existingHighlight {
                        highlightService.removeHighlight(id: highlight.id)
                    }
                }
            } else {
                ForEach(HighlightColor.allCases, id: \.self) { color in
                    Button(color.displayName) {
                        highlightService.addHighlight(
                            book: book,
                            chapter: chapter,
                            verse: verse.verse,
                            verseText: verse.text,
                            translation: verse.translation,
                            color: color
                        )
                    }
                }
            }

            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showNoteEditor) {
            NoteEditorView(
                highlight: existingHighlight,
                book: book,
                chapter: chapter,
                verse: verse.verse,
                verseText: verse.text,
                translation: verse.translation,
                isPresented: $showNoteEditor
            )
        }
    }
}

struct ReadingSettingsView: View {
    @Binding var fontSize: CGFloat
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Font Size: \(Int(fontSize))pt")
                            .font(.headline)

                        Slider(value: $fontSize, in: 12...24, step: 1)

                        Text("Sample text at selected size")
                            .font(.system(size: fontSize, design: .serif))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                } header: {
                    Text("Text Settings")
                }
            }
            .navigationTitle("Reading Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ChapterReadingView(
            book: BibleBookInfo(name: "John", abbreviation: "John", testament: .new, chapterCount: 21),
            chapter: 3
        )
    }
}
