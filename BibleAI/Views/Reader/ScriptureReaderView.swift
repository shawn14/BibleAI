import SwiftUI

struct ScriptureReaderView: View {
    @StateObject private var model = ScriptureFeedModel()
    @StateObject private var highlights = HighlightService.shared
    @AppStorage("reader.useSerif") private var useSerif = true
    @AppStorage("reader.textSize") private var textSize = 28.0
    @ScaledMetric(relativeTo: .title2) private var scaledSize = 28.0
    @State private var sheet: ReaderSheet?
    @State private var showSettings = false
    @State private var pendingRemoval: Highlight?

    private enum ReaderSheet: String, Identifiable {
        case passage, study, note, chapter
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Group {
                if model.verses.isEmpty {
                    if model.loading {
                        ProgressView("Opening Scripture…")
                    } else {
                        ContentUnavailableView {
                            Label("Couldn't open this chapter", systemImage: "wifi.exclamationmark")
                        } description: {
                            Text(model.error ?? "Connect to the internet to open a chapter for the first time.")
                        } actions: {
                            Button("Try Again") { Task { await model.start() } }
                                .buttonStyle(.borderedProminent)
                            Button("Choose a Passage") { sheet = .passage }
                        }
                    }
                } else {
                    reader
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Read")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button { sheet = .passage } label: {
                        HStack(spacing: 5) {
                            Text(model.current.map { "\($0.book) \($0.chapter)" } ?? "Choose a Passage")
                                .font(.headline)
                            Image(systemName: "chevron.down").font(.caption2.weight(.semibold))
                        }
                    }
                    .accessibilityIdentifier("reader.passage")
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { sheet = .passage } label: { Label("Find a Passage", systemImage: "magnifyingglass") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Read Full Chapter", systemImage: "text.alignleft") { sheet = .chapter }
                            .disabled(model.current == nil)
                        Button("Previous Chapter", systemImage: "arrow.up") { Task { await model.previousChapter() } }
                            .disabled(!model.hasPreviousChapter)
                        Button("Reading Settings", systemImage: "textformat.size") { showSettings = true }
                    } label: { Label("Reading Options", systemImage: "ellipsis.circle") }
                    .accessibilityIdentifier("reader.options")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let verse = model.current { actions(for: verse) }
            }
            .task { await model.start() }
            .onChange(of: model.visibleID) { _, _ in Task { await model.didScroll() } }
            .sheet(item: $sheet) { destination in
                switch destination {
                case .passage:
                    PassagePickerView { place in await model.open(place) }
                case .study:
                    if let verse = model.current { VerseStudySheet(verse: verse) }
                case .note:
                    if let verse = model.current {
                        NoteEditorView(highlight: saved(verse), book: verse.book, chapter: verse.chapter,
                                       verse: verse.verse, verseText: verse.text,
                                       isPresented: Binding(get: { sheet == .note }, set: { if !$0 { sheet = nil } }))
                    }
                case .chapter:
                    if let verse = model.current,
                       let book = BibleBookInfo.allBooks.first(where: { $0.name == verse.book }) {
                        NavigationStack {
                            ChapterReadingView(book: book, chapter: verse.chapter)
                                .toolbar { ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { sheet = nil }
                                } }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
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

    private var reader: some View {
        GeometryReader { geometry in
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(model.verses, id: \.passageID) { verse in
                    VStack(spacing: 24) {
                        Spacer(minLength: 20)
                        Text(verse.reference)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Button { sheet = .study } label: {
                            Text(verse.text)
                                .font(.system(size: scaledSize * textSize / 28, design: useSerif ? .serif : .default))
                                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                                .multilineTextAlignment(.center)
                                .lineSpacing(7)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(verse.reference). \(verse.text)")
                        .accessibilityHint("Opens verse study")
                        .accessibilityIdentifier("reader.verse.\(verse.passageID)")
                        Text("King James Version").font(.caption).foregroundStyle(.tertiary)
                        Spacer(minLength: 20)
                        Label("Swipe to keep reading", systemImage: "chevron.up")
                            .font(.caption).foregroundStyle(.secondary)
                            .padding(.bottom, 12)
                    }
                    .padding(.horizontal, 28)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                    .id(verse.passageID)
                }
                if let error = model.nextError {
                    VStack(spacing: 12) {
                        Text(error).font(.callout).foregroundStyle(.secondary)
                        Button("Load Next Chapter") { Task { await model.loadNext() } }
                    }.padding()
                } else if model.loadingNext {
                    ProgressView("Opening next chapter…").padding()
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $model.visibleID)
        .overlay { if model.loading { ProgressView("Opening passage…").padding().background(.regularMaterial) } }
        .accessibilityIdentifier("reader.feed")
        }
    }

    private func actions(for verse: BibleVerse) -> some View {
        HStack(spacing: 28) {
            Button {
                if let highlight = saved(verse) { pendingRemoval = highlight }
                else { highlights.addHighlight(book: verse.book, chapter: verse.chapter, verse: verse.verse,
                                               verseText: verse.text, color: .yellow) }
            } label: {
                Label(saved(verse) == nil ? "Save Verse" : "Remove Saved Verse",
                      systemImage: saved(verse) == nil ? "bookmark" : "bookmark.fill")
                    .labelStyle(.iconOnly)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityIdentifier("reader.save")
            Spacer(minLength: 0)
            Button("Study Verse", systemImage: "text.book.closed") { sheet = .study }
                .buttonStyle(.borderedProminent).controlSize(.regular)
                .accessibilityIdentifier("reader.study")
            Spacer(minLength: 0)
            Menu {
                Button("Add a Note", systemImage: "square.and.pencil") { sheet = .note }
                ShareLink(item: "\(verse.text)\n\n\(verse.fullReference)") {
                    Label("Share Verse", systemImage: "square.and.arrow.up")
                }
            } label: {
                Label("Verse Actions", systemImage: "square.and.arrow.up").labelStyle(.iconOnly)
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 8)
        .background(.bar)
    }

    private func saved(_ verse: BibleVerse) -> Highlight? {
        highlights.getHighlight(book: verse.book, chapter: verse.chapter, verse: verse.verse)
    }
}
