import SwiftUI

struct NoteEditorView: View {
    let highlight: Highlight?
    let book: String
    let chapter: Int
    let verse: Int
    let verseText: String
    @Binding var isPresented: Bool
    @StateObject private var highlights = HighlightService.shared
    @State private var note = ""
    @State private var color: HighlightColor = .yellow

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(verseText).font(.system(.body, design: .serif)).lineSpacing(4)
                        .textSelection(.enabled)
                    ShareLink(item: "\(verseText)\n\n\(book) \(chapter):\(verse) (KJV)") {
                        Label("Share Verse", systemImage: "square.and.arrow.up")
                    }
                }
                Section("Your Note") {
                    TextEditor(text: $note)
                        .frame(minHeight: 180)
                        .accessibilityLabel("Your Note")
                        .accessibilityIdentifier("note.text")
                }
                Section("Highlight") {
                    Picker("Color", selection: $color) {
                        ForEach(HighlightColor.allCases, id: \.self) { color in Text(color.displayName).tag(color) }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("\(book) \(chapter):\(verse)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isPresented = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let highlight {
                            highlights.updateHighlight(id: highlight.id, color: color, note: note)
                        } else {
                            highlights.addHighlight(book: book, chapter: chapter, verse: verse,
                                                    verseText: verseText, color: color, note: note)
                        }
                        isPresented = false
                    }.accessibilityIdentifier("note.save")
                }
            }
        }
        .onAppear {
            note = highlight?.note ?? ""
            color = highlight?.color ?? .yellow
        }
    }
}
