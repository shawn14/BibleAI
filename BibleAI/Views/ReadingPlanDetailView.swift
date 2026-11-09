import SwiftUI

struct ReadingPlanDetailView: View {
    let plan: ReadingPlan
    @Binding var isPresented: ReadingPlan?
    @StateObject private var plans = ReadingPlanService.shared
    @State private var showReset = false
    @State private var showInvite = false
    @State private var completedDay: DailyReading?

    private var progress: UserPlanProgress? { plans.getProgress(for: plan.id) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(plan.description).foregroundStyle(.secondary)
                    Button("Read with Someone", systemImage: "person.badge.plus") { showInvite = true }
                        .accessibilityIdentifier("plan.invite")
                    if let progress {
                        ProgressView(value: Double(progress.completedDays.count), total: Double(plan.duration)) {
                            Text("\(progress.completedDays.count) of \(plan.duration) complete")
                        }
                    } else {
                        Button("Start Plan", systemImage: "play.fill") { plans.startPlan(plan) }
                            .accessibilityIdentifier("plan.start")
                    }
                }
                ForEach(plan.dailyReadings) { day in daySection(day) }
            }
            .listStyle(.plain)
            .navigationTitle(plan.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { isPresented = nil } }
                if progress != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button("Reset Progress", role: .destructive) { showReset = true }
                        } label: { Label("Plan Options", systemImage: "ellipsis.circle") }
                    }
                }
            }
            // iPad: this view is already a form sheet, and a nested sheet is too short for the day-complete card.
            .sheet(item: isPad ? .constant(nil) : $completedDay) { day in dayComplete(day) }
            .fullScreenCover(item: isPad ? $completedDay : .constant(nil)) { day in dayComplete(day) }
            .sheet(isPresented: $showInvite) { PlanInvitationShareView(plan: plan) }
            .confirmationDialog("Reset this plan's progress?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Reset Progress", role: .destructive) { plans.deletePlanProgress(plan.id) }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    @ViewBuilder
    private func daySection(_ day: DailyReading) -> some View {
        Section("Day \(day.day) · \(day.title)") {
            ForEach(day.readings) { reference in
                if let book = BibleBookInfo.allBooks.first(where: { $0.name == reference.book }) {
                    ForEach(reference.startChapter...(reference.endChapter ?? reference.startChapter), id: \.self) { chapter in
                        NavigationLink {
                            ChapterReadingView(book: book, chapter: chapter, invitationPlanID: plan.id)
                        } label: {
                            Label("\(book.name) \(chapter)", systemImage: "book")
                        }
                    }
                }
            }
            if progress != nil {
                if plans.isDayComplete(planId: plan.id, day: day.day) {
                    Label("Completed", systemImage: "checkmark").foregroundStyle(.secondary)
                } else {
                    Button("Mark Complete", systemImage: "checkmark.circle") {
                        if plans.markDayComplete(planId: plan.id, day: day.day) { completedDay = day }
                    }
                    .accessibilityIdentifier("plan.complete.\(day.day)")
                }
            }
        }
    }

    private func dayComplete(_ day: DailyReading) -> some View {
        DayCompleteView(
            reading: readingSummary(day),
            plan: plan,
            hasNextDay: plan.dailyReadings.contains { !plans.isDayComplete(planId: plan.id, day: $0.day) },
            onDone: { completedDay = nil; isPresented = nil },
            onContinue: { completedDay = nil })
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private func readingSummary(_ day: DailyReading) -> String {
        day.readings.map { ref in
            if let end = ref.endChapter, end != ref.startChapter { return "\(ref.book) \(ref.startChapter)–\(end)" }
            return "\(ref.book) \(ref.startChapter)"
        }.joined(separator: ", ")
    }
}

struct TodayReadingView: View {
    let reading: ReadingPlanService.PlanReading
    @ObservedObject private var plans = ReadingPlanService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var chapterIndex: Int
    @State private var loaded = false
    @State private var finished = false
    var onContinue: (ReadingPlanService.PlanReading) -> Void

    init(reading: ReadingPlanService.PlanReading, onContinue: @escaping (ReadingPlanService.PlanReading) -> Void) {
        self.reading = reading
        self.onContinue = onContinue
        let saved = UserDefaults.standard.integer(forKey: "today.chapter.\(reading.id)")
        _chapterIndex = State(initialValue: max(0, min(saved, reading.day.readings.reduce(0) {
            $0 + ($1.endChapter ?? $1.startChapter) - $1.startChapter + 1
        } - 1)))
    }

    private var chapters: [(book: BibleBookInfo, number: Int)] {
        reading.day.readings.flatMap { reference -> [(BibleBookInfo, Int)] in
            guard let book = BibleBookInfo.allBooks.first(where: { $0.name == reference.book }) else { return [] }
            return (reference.startChapter...(reference.endChapter ?? reference.startChapter)).map { (book, $0) }
        }
    }

    var body: some View {
        if finished {
            DayCompleteView(reading: reading.day.readings.map(\.displayText).joined(separator: ", "),
                            plan: reading.plan, hasNextDay: plans.nextReading(for: reading.plan) != nil,
                            onDone: { dismiss() }, onContinue: {
                if let next = plans.nextReading(for: reading.plan) { onContinue(next) }
                else { dismiss() }
            })
        } else {
            NavigationStack {
                if chapters.indices.contains(chapterIndex) {
                    let chapter = chapters[chapterIndex]
                    ChapterReadingView(book: chapter.book, chapter: chapter.number, invitationPlanID: reading.plan.id) {
                        loaded = true
                        UserDefaults.standard.set(chapterIndex, forKey: "today.chapter.\(reading.id)")
                    }
                    .id(chapterIndex)
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 6) {
                            Text("\(reading.plan.title) · Day \(reading.day.day) · \(chapterIndex + 1) of \(chapters.count) chapters")
                                .font(.footnote).foregroundStyle(.secondary)
                            HStack {
                                if chapterIndex > 0 {
                                    Button("Previous") { loaded = false; chapterIndex -= 1 }
                                }
                                Spacer()
                                if chapterIndex + 1 < chapters.count {
                                    Button("Next chapter") { loaded = false; chapterIndex += 1 }
                                        .disabled(!loaded)
                                } else {
                                    Button("Mark Complete") {
                                        if plans.markDayComplete(planId: reading.plan.id, day: reading.day.day) {
                                            finished = true
                                            UserDefaults.standard.removeObject(forKey: "today.chapter.\(reading.id)")
                                        } else { dismiss() }
                                    }
                                    .disabled(!loaded)
                                    .accessibilityIdentifier("today.finish")
                                }
                            }.frame(minHeight: 44)
                        }.padding(.horizontal).background(.bar)
                    }
                    .toolbar { ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }.accessibilityIdentifier("today.close")
                    } }
                }
            }
        }
    }
}

