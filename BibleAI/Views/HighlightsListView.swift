//
//  HighlightsListView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct HighlightsListView: View {
    @StateObject private var highlightService = HighlightService.shared
    @State private var selectedHighlight: Highlight?
    @State private var showNoteEditor = false
    @State private var searchText = ""

    var filteredHighlights: [Highlight] {
        if searchText.isEmpty {
            return highlightService.highlights
        }
        return highlightService.highlights.filter { highlight in
            highlight.reference.localizedCaseInsensitiveContains(searchText) ||
            highlight.verseText.localizedCaseInsensitiveContains(searchText) ||
            (highlight.note?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if highlightService.highlights.isEmpty {
                    EmptyHighlightsView()
                } else {
                    List {
                        ForEach(filteredHighlights) { highlight in
                            HighlightRowView(highlight: highlight)
                                .onTapGesture {
                                    selectedHighlight = highlight
                                    showNoteEditor = true
                                }
                        }
                        .onDelete(perform: deleteHighlights)
                    }
                    .searchable(text: $searchText, prompt: "Search highlights")
                }
            }
            .navigationTitle("My Highlights")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showNoteEditor) {
                if let highlight = selectedHighlight {
                    NoteEditorView(
                        highlight: highlight,
                        book: highlight.book,
                        chapter: highlight.chapter,
                        verse: highlight.verse,
                        verseText: highlight.verseText,
                        isPresented: $showNoteEditor
                    )
                }
            }
        }
    }

    private func deleteHighlights(at offsets: IndexSet) {
        for index in offsets {
            let highlight = filteredHighlights[index]
            highlightService.removeHighlight(id: highlight.id)
        }
    }
}

struct EmptyHighlightsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "highlighter")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.6))

            VStack(spacing: 8) {
                Text("No Highlights Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Tap any verse while reading to highlight it and add notes")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }
}

struct HighlightRowView: View {
    let highlight: Highlight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Reference
            HStack {
                Text(highlight.reference)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                Spacer()

                Circle()
                    .fill(highlight.color.color)
                    .frame(width: 20, height: 20)
            }

            // Verse text
            Text(highlight.verseText)
                .font(.body)
                .lineLimit(3)
                .padding(8)
                .background(highlight.color.color)
                .cornerRadius(4)

            // Note if exists
            if let note = highlight.note, !note.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .lineLimit(2)
                }
            }

            // Date
            Text(highlight.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HighlightsListView()
}
