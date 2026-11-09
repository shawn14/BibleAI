import SwiftUI

struct HighlightsListView: View {
    @StateObject private var highlights = HighlightService.shared
    @ObservedObject private var library = StudyLibrary.shared
    @State private var studyToRemove: SavedStudy?
    @State private var removalError = false
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

    private var matchingStudies: [SavedStudy] {
        library.studies.filter { study in
            query.isEmpty || [study.title, study.verse.fullReference, study.body].contains {
                $0.localizedCaseInsensitiveContains(query)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if highlights.highlights.isEmpty && library.studies.isEmpty && library.readError == nil {
                    ContentUnavailableView("Saved verses and studies", systemImage: "bookmark",
                                           description: Text("Tap the heart on a verse or choose Save study in a reading guide or verse study."))
                } else {
                    List {
                        if let error = library.readError {
                            Text(error)
                            Button("Try Again") { library.reload() }
                        }
                        if !matchingStudies.isEmpty {
                            Section {
                                ForEach(matchingStudies) { study in
                                    NavigationLink {
                                        StudyDetailView(study: study)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(study.title).font(.headline)
                                            Text(study.verse.fullReference).font(.subheadline).foregroundStyle(.secondary)
                                        }
                                    }
                                    .accessibilityIdentifier("saved.study.\(study.verse.passageID)")
                                    .swipeActions {
                                        Button("Remove", role: .destructive) { studyToRemove = study }
                                    }
                                }
                            } header: { Text("Studies") } footer: { Text("Studies are saved on this device.") }
                        }
                        ForEach(filtered) { highlight in
                            Button { selected = highlight } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("\(highlight.reference) (\(highlight.citationEdition))").font(.headline).foregroundStyle(.primary)
                                    Text(highlight.verseText).font(.system(.body, design: .serif))
                                        .foregroundStyle(.primary).lineLimit(3)
                                    if let note = highlight.note, !note.isEmpty {
                                        Label(note, systemImage: "note.text")
                                            .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                }.padding(.vertical, 8)
                            }
                            .accessibilityIdentifier("saved.verse.\(CloudSyncMerge.verseKey(highlight))")
                            .swipeActions {
                                Button("Remove", role: .destructive) { pendingRemoval = highlight }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .overlay { if filtered.isEmpty && matchingStudies.isEmpty && library.readError == nil { ContentUnavailableView.search(text: query) } }
                }
            }
            .navigationTitle("Saved")
            .searchable(text: $query, prompt: "Search verses, notes and studies")
            .confirmationDialog("Remove this saved study?",
                                isPresented: Binding(get: { studyToRemove != nil }, set: { if !$0 { studyToRemove = nil } }),
                                titleVisibility: .visible, presenting: studyToRemove) { study in
                Button("Remove", role: .destructive) {
                    do { try library.remove(study.id) } catch { removalError = true }
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Couldn’t remove this study. Try again.", isPresented: $removalError) { Button("OK") {} }
            .sheet(item: $selected) { highlight in
                NoteEditorView(highlight: highlight, book: highlight.book, chapter: highlight.chapter,
                               verse: highlight.verse, verseText: highlight.verseText, translation: highlight.citationEdition,
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
