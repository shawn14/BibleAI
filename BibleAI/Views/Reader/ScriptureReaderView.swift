import SwiftUI

struct ScriptureReaderView: View {
    @Binding var requestedPlace: ReadingPlace?
    var isActive = true
    var onChoosePlan: () -> Void
    @ObservedObject private var streak = StreakStore.shared
    @StateObject private var model = ScriptureFeedModel()
    @StateObject private var highlights = HighlightService.shared
    @AppStorage("reader.useSerif") private var useSerif = true
    @AppStorage("reader.textSize") private var textSize = 28.0
    @ScaledMetric(relativeTo: .title2) private var scaledSize = 28.0
    @ObservedObject private var plans = ReadingPlanService.shared
    @State private var today: ReadingPlanService.PlanReading?
    @State private var sheet: ReaderSheet?
    @State private var pickedPassage: ScriptureFeedModel.ScrollRequest?
    @State private var aligningJump: UUID?
    @State private var targetFrame: ReaderTargetFrame?
    @State private var showSettings = false
    @State private var pendingRemoval: Highlight?
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var padScale: CGFloat { sizeClass == .regular ? 1.6 : 1 }

    private enum ReaderSheet: String, Identifiable {
        case passage, study, note, chapter, share
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
            .safeAreaInset(edge: .bottom) {
                if model.isReadingSharedPassage {
                    Button("Return to my reading", systemImage: "arrow.uturn.backward") {
                        Task { await model.returnToReading() }
                    }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("reader.returnToPlace")
                } else {
                    let reading = plans.todaysReading
                    Button {
                        if let reading { today = reading } else { onChoosePlan() }
                    } label: {
                        HStack {
                            Image(systemName: "book.pages")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reading == nil ? "Choose a reading plan" : "Continue today’s reading")
                                    .font(.subheadline.weight(.semibold))
                                TimelineView(.periodic(from: .now, by: 60)) { time in
                                    let count = streak.currentStreak(asOf: time.date)
                                    let progress = reading.map { "\($0.plan.title) · Day \($0.day.day) · " } ?? ""
                                    Text("\(progress)\(count)-day streak")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption)
                        }
                        .padding(.horizontal, 20).frame(minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(reading == nil ? "reader.choosePlan" : "reader.today")
                }
            }
            .task(id: isActive) { if isActive { await openRequestedPassage() } }
            .onChange(of: requestedPlace) { _, _ in if isActive { Task { await openRequestedPassage() } } }
            .onChange(of: model.visibleID) { _, _ in
                if sheet != .passage && pickedPassage == nil && aligningJump == nil { Task { await model.didScroll() } }
            }
            .sheet(item: $sheet, onDismiss: {
                // Dismissing the search keyboard changes the usable page height on smaller phones.
                if let pickedPassage, model.scrollRequest == pickedPassage { model.focus(pickedPassage.place) }
                pickedPassage = nil
            }) { destination in
                switch destination {
                case .share:
                    if let verse = model.current { ScriptureShareView(verse: verse) }
                case .passage:
                    PassagePickerView(edition: model.edition) { place, isSearchResult in
                        let opened: Bool
                        if isSearchResult {
                            opened = await model.previewSearchResult(place)
                        } else {
                            opened = await model.open(place, asSharedPassage: model.isReadingSharedPassage)
                        }
                        guard opened else { return false }
                        pickedPassage = model.scrollRequest
                        return true
                    }
                case .study:
                    if let verse = model.current { VerseStudySheet(verse: verse) }
                case .note:
                    if let verse = model.current {
                        NoteEditorView(highlight: saved(verse), book: verse.book, chapter: verse.chapter,
                                       verse: verse.verse, verseText: verse.text, translation: verse.translation,
                                       isPresented: Binding(get: { sheet == .note }, set: { if !$0 { sheet = nil } }))
                    }
                case .chapter:
                    if let verse = model.current,
                       let book = BibleBookInfo.allBooks.first(where: { $0.name == verse.book }) {
                        NavigationStack {
                            ChapterReadingView(book: book, chapter: verse.chapter, edition: model.edition)
                                .toolbar { ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { sheet = nil }
                                } }
                        }
                    }
                }
            }
            .alert("Couldn't open this passage", isPresented: Binding(
                get: { model.error != nil && !model.verses.isEmpty && sheet == nil },
                set: { if !$0 { model.error = nil } }
            )) { Button("OK") { model.error = nil } } message: { Text(model.error ?? "") }
            .sheet(item: $today) { reading in
                TodayReadingView(reading: reading) { today = $0 }.id(reading.id)
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
            ScrollViewReader { proxy in
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
                                        .font(.system(size: scaledSize * textSize / 28 * padScale, design: useSerif ? .serif : .default))
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
                                .frame(maxWidth: sizeClass == .regular ? 820 : .infinity)
                                Text(model.edition.name).font(.caption).foregroundStyle(.tertiary)
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
                            .background {
                                if let jump = model.scrollRequest, jump.place.id == verse.passageID {
                                    GeometryReader { bounds in
                                        Color.clear.preference(key: ReaderTargetFrameKey.self,
                                            value: ReaderTargetFrame(revision: jump.revision,
                                                top: bounds.frame(in: .named("scriptureViewport")).minY))
                                    }
                                }
                            }
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
                .coordinateSpace(name: "scriptureViewport")
                .onPreferenceChange(ReaderTargetFrameKey.self) { targetFrame = $0 }
                .scrollPosition(id: Binding(get: { model.visibleID }, set: { value in
                    if aligningJump == nil { model.visibleID = value }
                }), anchor: .top)
                .simultaneousGesture(DragGesture(minimumDistance: 4).onChanged { _ in
                    // A swipe takes precedence over a programmatic jump.
                    if aligningJump != nil { aligningJump = nil }
                })
                .task(id: model.scrollRequest) {
                    guard let target = model.scrollRequest, sheet != .passage else { return }
                    aligningJump = target.revision
                    defer { if aligningJump == target.revision { aligningJump = nil } }
                    // A lazy stack estimates offsets before the destination row exists. Recheck its
                    // actual frame during keyboard dismissal; never save an intermediate neighbor.
                    var stable = 0
                    for _ in 0..<20 {
                        guard !Task.isCancelled, aligningJump == target.revision,
                              model.scrollRequest == target else { return }
                        if let targetFrame, targetFrame.revision == target.revision, abs(targetFrame.top) <= 2 {
                            stable += 1
                            if stable >= 5 { break }
                        } else {
                            stable = 0
                            proxy.scrollTo(target.place.id, anchor: .top)
                        }
                        do { try await Task.sleep(for: .milliseconds(55)) } catch { return }
                    }
                }
                .overlay { if model.loading { ProgressView("Opening passage…").padding().background(.regularMaterial) } }
                .accessibilityIdentifier("reader.feed")
            }
        }
    }

    /// Minimal top chrome: translation pill, passage button, options.
    private var topBar: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(ReaderEdition.allCases, id: \.self) { edition in
                    Button {
                        Task { await model.switchEdition(edition) }
                    } label: {
                        if model.edition == edition { Label(edition.name, systemImage: "checkmark") }
                        else { Text(edition.name) }
                    }
                }
            } label: {
                Label(model.edition.rawValue, systemImage: "chevron.down")
                    .labelStyle(.titleAndIcon).font(.caption.weight(.semibold))
                    .frame(minHeight: 44)
            }
            .accessibilityLabel("Translation, \(model.edition.name)")
            .accessibilityIdentifier("reader.translation")
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
                                               verseText: verse.text, translation: verse.translation, color: .yellow) }
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
            Button { sheet = .share } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share Verse")
            .accessibilityIdentifier("reader.share")
        }
        .font(.system(size: sizeClass == .regular ? 28 : 22, weight: .regular))
        .foregroundStyle(.primary)
        .frame(width: 44)
        .padding(.trailing, 10)
    }

    private func openRequestedPassage() async {
        if let place = requestedPlace {
            if await model.open(place, asSharedPassage: true, edition: .kjv) {
                requestedPlace = nil
                if let invite = GrowthStore.shared.acceptedInvitation, invite.readingPlace == place {
                    GrowthStore.shared.recordFirstReading(for: invite)
                }
            }
        } else { await model.start() }
        if model.current != nil { GrowthStore.shared.recordReaderActivation() }
    }

    private func saved(_ verse: BibleVerse) -> Highlight? {
        highlights.getHighlight(book: verse.book, chapter: verse.chapter, verse: verse.verse, translation: verse.translation)
    }
}

private struct ReaderTargetFrame: Equatable {
    let revision: UUID
    let top: CGFloat
}

private struct ReaderTargetFrameKey: PreferenceKey {
    static let defaultValue: ReaderTargetFrame? = nil
    static func reduce(value: inout ReaderTargetFrame?, nextValue: () -> ReaderTargetFrame?) {
        if let next = nextValue() { value = next }
    }
}
