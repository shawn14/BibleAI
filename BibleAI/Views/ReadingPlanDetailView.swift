import SwiftUI

struct ReadingPlanDetailView: View {
    let plan: ReadingPlan
    @Binding var isPresented: ReadingPlan?
    @StateObject private var plans = ReadingPlanService.shared
    @State private var showReset = false

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
                ForEach(plan.dailyReadings) { day in
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
                                }
                                .accessibilityIdentifier("plan.complete.\(day.day)")
                            }
                        }
                    }
                }
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
            .confirmationDialog("Reset this plan's progress?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Reset Progress", role: .destructive) { plans.deletePlanProgress(plan.id) }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
}
