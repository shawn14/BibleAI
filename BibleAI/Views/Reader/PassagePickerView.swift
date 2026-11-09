import SwiftUI

struct PassagePickerView: View {
    let edition: ReaderEdition
    let onSelect: (ReadingPlace, Bool) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var page = 0
    @State private var response: (request: Request, result: Result<ScriptureIndex.Page, Error>)?
    @State private var opening = false
    @State private var error: String?

    private struct Request: Equatable {
        let term: String
        let edition: ReaderEdition
        let page: Int
    }

    private var searchRequest: Request? {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty, VerseParser.shared.parseReference(term) == nil else { return nil }
        return Request(term: term, edition: edition, page: page)
    }

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
                if let searchRequest { scriptureResults(searchRequest) }
            }
            .listStyle(.plain)
            .searchable(text: Binding(get: { query }, set: { query = $0; page = 0 }),
                        placement: .navigationBarDrawer(displayMode: .always), prompt: "Book, reference, word or phrase")
            .task(id: searchRequest) { await findVerses(searchRequest) }
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

    @ViewBuilder
    private func scriptureResults(_ request: Request) -> some View {
        Section("Verses in \(edition.rawValue)") {
            if let response, response.request == request {
                switch response.result {
                case .failure(let error):
                    Text(error.localizedDescription).foregroundStyle(.secondary)
                case .success(let matches):
                    if matches.verses.isEmpty {
                        Text("No matching verses").foregroundStyle(.secondary)
                    } else {
                        if page > 0 {
                            Button("Previous results") { page -= 1 }
                        }
                        ForEach(matches.verses, id: \.passageID) { verse in
                            Button { open(verse.place, isSearchResult: true) } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(verse.reference).font(.headline)
                                    Text(verse.text).font(.body).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("passage.result.\(verse.passageID)")
                        }
                        if matches.hasNext {
                            Button("Next results") { page += 1 }
                        }
                    }
                }
            } else {
                ProgressView("Searching Scripture…")
            }
        }
    }

    @MainActor private func findVerses(_ request: Request?) async {
        guard let request else { response = nil; return }
        do {
            try await Task.sleep(for: .milliseconds(180))
            let matches = try await ScriptureIndex.shared.search(request.term, edition: request.edition, page: request.page)
            try Task.checkCancellation()
            response = (request, .success(matches))
        } catch is CancellationError {
            return
        } catch {
            if !Task.isCancelled { response = (request, .failure(error)) }
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
        .accessibilityIdentifier("passage.shortcut.\(place.id)")
    }

    private func open(_ place: ReadingPlace, isSearchResult: Bool = false) {
        opening = true
        Task {
            if await onSelect(place, isSearchResult) { dismiss() }
            else { error = "Check this reference and your connection, then try again." }
            opening = false
        }
    }
}
