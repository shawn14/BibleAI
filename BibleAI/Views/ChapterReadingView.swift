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

    @StateObject private var bibleService = EnhancedBibleService.shared
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

                    Text("This chapter is currently being loaded. Please try again.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(verses) { verse in
                        VerseRowView(
                            verse: verse,
                            book: book.name,
                            chapter: chapter,
                            fontSize: fontSize,
                            highlightService: highlightService
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("\(book.name) \(chapter)")
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
        verses = await bibleService.getChapter(book: book.name, chapter: chapter) ?? []
        isLoading = false
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
    @State private var showShareSheet = false

    private var existingHighlight: Highlight? {
        highlightService.getHighlight(book: book, chapter: chapter, verse: verse.verse)
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
                    .font(.system(size: fontSize))
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
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
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
            Button("Share Verse") {
                showShareSheet = true
            }

            if existingHighlight != nil {
                Button("Add/Edit Note") {
                    showNoteEditor = true
                }

                Button("Change Color") {
                    // Show color picker
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
                isPresented: $showNoteEditor
            )
        }
        .sheet(isPresented: $showShareSheet) {
            SimpleImageShareView(
                text: verse.text,
                reference: "\(book) \(chapter):\(verse.verse)",
                note: existingHighlight?.note,
                isPresented: $showShareSheet
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
                            .font(.system(size: fontSize))
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
