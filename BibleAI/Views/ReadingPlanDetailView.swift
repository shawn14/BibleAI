import SwiftUI

struct ReadingPlanDetailView: View {
    let plan: ReadingPlan
    @Binding var isPresented: ReadingPlan?
    @StateObject private var plans = ReadingPlanService.shared
    @State private var showReset = false
    @State private var completedDay: DailyReading?

    private var progress: UserPlanProgress? { plans.getProgress(for: plan.id) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(plan.description).foregroundStyle(.secondary)
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
            .sheet(item: $completedDay) { day in dayComplete(day) }
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
                            ChapterReadingView(book: book, chapter: chapter)
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
                        plans.markDayComplete(planId: plan.id, day: day.day)
                        StreakStore.shared.recordReading()
                        completedDay = day
                    }
                    .accessibilityIdentifier("plan.complete.\(day.day)")
                }
            }
        }
    }

    private func dayComplete(_ day: DailyReading) -> some View {
        DayCompleteView(
            reading: readingSummary(day),
            hasNextDay: plan.dailyReadings.contains { !plans.isDayComplete(planId: plan.id, day: $0.day) },
            onDone: { completedDay = nil; isPresented = nil },
            onContinue: { completedDay = nil })
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func readingSummary(_ day: DailyReading) -> String {
        day.readings.map { ref in
            if let end = ref.endChapter, end != ref.startChapter { return "\(ref.book) \(ref.startChapter)–\(end)" }
            return "\(ref.book) \(ref.startChapter)"
        }.joined(separator: ", ")
    }
}
