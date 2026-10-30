import SwiftUI

struct PassagePickerView: View {
    let onSelect: (ReadingPlace) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var opening = false
    @State private var error: String?

    private var books: [BibleBookInfo] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return BibleBookInfo.allBooks.filter { term.isEmpty || $0.name.localizedCaseInsensitiveContains(term) }
    }

    var body: some View {
        NavigationStack {
            List {
                if let reference = VerseParser.shared.parseReference(query) {
                    Section("Passage") {
                        Button { open(ReadingPlace(book: reference.book, chapter: reference.chapter,
                                                   verse: reference.verse ?? 1)) } label: {
                            Label(reference.displayString, systemImage: "arrow.right.circle")
                        }
                        .accessibilityIdentifier("passage.openReference")
                    }
                }
                if query.isEmpty {
                    Section("Start Here") {
                        passage("The Beginning", subtitle: "Genesis 1", place: .beginning)
                        passage("The Life of Jesus", subtitle: "John 1",
                                place: ReadingPlace(book: "John", chapter: 1, verse: 1))
                        passage("A Moment of Peace", subtitle: "Psalm 23",
                                place: ReadingPlace(book: "Psalms", chapter: 23, verse: 1))
                    }
                }
                ForEach([Testament.old, Testament.new], id: \.self) { testament in
                    let matches = books.filter { $0.testament == testament }
                    if !matches.isEmpty {
                        Section(testament.rawValue) {
                            ForEach(matches, id: \.name) { book in
                                NavigationLink(book.name) {
                                    List(1...book.chapterCount, id: \.self) { chapter in
                                        Button("Chapter \(chapter)") {
                                            open(ReadingPlace(book: book.name, chapter: chapter, verse: 1))
                                        }
                                        .accessibilityIdentifier("passage.\(book.abbreviation).\(chapter)")
                                    }
                                    .listStyle(.plain)
                                    .navigationTitle(book.name)
                                }
                            }
                        }
                    }
                }
                if books.isEmpty && VerseParser.shared.parseReference(query) == nil {
                    ContentUnavailableView.search(text: query)
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Book or verse, such as John 3:16")
            .autocorrectionDisabled()
            .navigationTitle("Find a Passage")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .disabled(opening)
            .overlay { if opening { ProgressView("Opening passage…") } }
            .alert("Couldn't Open Passage", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
        }
    }

    private func passage(_ title: String, subtitle: String, place: ReadingPlace) -> some View {
        Button { open(place) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).foregroundStyle(.primary)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right").foregroundStyle(.secondary)
            }
        }
    }

    private func open(_ place: ReadingPlace) {
        opening = true
        Task {
            if await onSelect(place) { dismiss() }
            else { error = "Check this reference and your connection, then try again." }
            opening = false
        }
    }
}
