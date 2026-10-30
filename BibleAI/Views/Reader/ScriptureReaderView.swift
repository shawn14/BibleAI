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
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .top) { topBar }
            .overlay(alignment: .trailing) {
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
                        // Only on the first verse: on later pages it peeked in under the status bar.
                        Label("Swipe to keep reading", systemImage: "chevron.up")
                            .font(.caption).foregroundStyle(.secondary)
                            .padding(.bottom, 12)
                            .opacity(verse.passageID == model.verses.first?.passageID ? 1 : 0)
                    }
                    .padding(.leading, 28).padding(.trailing, 60)
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
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollPosition(id: $model.visibleID)
        .overlay { if model.loading { ProgressView("Opening passage…").padding().background(.regularMaterial) } }
        .accessibilityIdentifier("reader.feed")
        }
    }

    /// Minimal top chrome: translation pill, passage button, options.
    private var topBar: some View {
        HStack(spacing: 10) {
            Text("KJV")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .overlay(Capsule().stroke(Color.primary.opacity(0.15)))
                .accessibilityLabel("King James Version")
            Spacer(minLength: 0)
            Button { sheet = .passage } label: {
                HStack(spacing: 5) {
                    Text(model.current.map { "\($0.book) \($0.chapter)" } ?? "Choose a Passage")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "chevron.down").font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.primary)
            }
            .accessibilityIdentifier("reader.passage")
            Spacer(minLength: 0)
            Button { sheet = .passage } label: {
                Image(systemName: "magnifyingglass").frame(width: 36, height: 36)
            }
            .accessibilityLabel("Find a Passage")
            Menu {
                Button("Read Full Chapter", systemImage: "text.alignleft") { sheet = .chapter }
                    .disabled(model.current == nil)
                Button("Previous Chapter", systemImage: "arrow.up") { Task { await model.previousChapter() } }
                    .disabled(!model.hasPreviousChapter)
                Button("Reading Settings", systemImage: "textformat.size") { showSettings = true }
            } label: {
                Image(systemName: "ellipsis").frame(width: 36, height: 36)
            }
            .accessibilityLabel("Reading Options")
            .accessibilityIdentifier("reader.options")
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    /// TikTok-style action rail on the right edge.
    private func actions(for verse: BibleVerse) -> some View {
        VStack(spacing: 22) {
            Button {
                if let highlight = saved(verse) { pendingRemoval = highlight }
                else { highlights.addHighlight(book: verse.book, chapter: verse.chapter, verse: verse.verse,
                                               verseText: verse.text, color: .yellow) }
            } label: {
                Image(systemName: saved(verse) == nil ? "heart" : "heart.fill")
                    .foregroundStyle(saved(verse) == nil ? Color.primary : Color.red)
            }
            .accessibilityLabel(saved(verse) == nil ? "Save Verse" : "Remove Saved Verse")
            .accessibilityIdentifier("reader.save")
            Button { sheet = .study } label: { Image(systemName: "text.book.closed") }
                .accessibilityLabel("Study Verse")
                .accessibilityIdentifier("reader.study")
            Button { sheet = .note } label: { Image(systemName: "square.and.pencil") }
                .accessibilityLabel("Add a Note")
            ShareLink(item: "\(verse.text)\n\n\(verse.fullReference)") {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share Verse")
        }
        .font(.system(size: 22, weight: .regular))
        .foregroundStyle(.primary)
        .frame(width: 44)
        .padding(.trailing, 10)
    }

    private func saved(_ verse: BibleVerse) -> Highlight? {
        highlights.getHighlight(book: verse.book, chapter: verse.chapter, verse: verse.verse)
    }
}
