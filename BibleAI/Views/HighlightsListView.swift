import SwiftUI

struct HighlightsListView: View {
    @StateObject private var highlights = HighlightService.shared
    @State private var selected: Highlight?
    @State private var pendingRemoval: Highlight?
    @State private var query = ""

    private var filtered: [Highlight] {
        highlights.highlights.filter {
            query.isEmpty || $0.reference.localizedCaseInsensitiveContains(query)
                || $0.verseText.localizedCaseInsensitiveContains(query)
                || ($0.note?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if highlights.highlights.isEmpty {
                    ContentUnavailableView("Your Verses, Kept Close", systemImage: "bookmark",
                                           description: Text("Tap the bookmark while reading to keep a verse here."))
                } else {
                    List {
                        ForEach(filtered) { highlight in
                            Button { selected = highlight } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(highlight.reference).font(.headline).foregroundStyle(.primary)
                                    Text(highlight.verseText).font(.system(.body, design: .serif))
                                        .foregroundStyle(.primary).lineLimit(3)
                                    if let note = highlight.note, !note.isEmpty {
                                        Label(note, systemImage: "note.text")
                                            .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                }.padding(.vertical, 8)
                            }
                            .accessibilityIdentifier("saved.verse.\(highlight.book)|\(highlight.chapter)|\(highlight.verse)")
                            .swipeActions {
                                Button("Remove", role: .destructive) { pendingRemoval = highlight }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .overlay { if filtered.isEmpty { ContentUnavailableView.search(text: query) } }
                }
            }
            .navigationTitle("Saved")
            .searchable(text: $query, prompt: "Search verses and notes")
            .sheet(item: $selected) { highlight in
                NoteEditorView(highlight: highlight, book: highlight.book, chapter: highlight.chapter,
                               verse: highlight.verse, verseText: highlight.verseText,
                               isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } }))
            }
            .confirmationDialog("Remove this saved verse and its note?",
                                isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } }),
                                titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    if let pendingRemoval { highlights.removeHighlight(id: pendingRemoval.id) }
                    pendingRemoval = nil
                }
                Button("Cancel", role: .cancel) { pendingRemoval = nil }
            }
        }
    }
}
