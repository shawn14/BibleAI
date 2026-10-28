import SwiftUI

struct ReadingPlansListView: View {
    @StateObject private var plans = ReadingPlanService.shared
    @State private var selected: ReadingPlan?

    private var started: [ReadingPlan] {
        plans.availablePlans.filter { plans.getProgress(for: $0.id) != nil }
    }
    private var available: [ReadingPlan] {
        plans.availablePlans.filter { plans.getProgress(for: $0.id) == nil }
    }

    var body: some View {
        NavigationStack {
            List {
                if !started.isEmpty {
                    Section("Continue Reading") {
                        ForEach(started) { plan in planRow(plan) }
                    }
                }
                Section("Explore Plans") {
                    ForEach(available) { plan in planRow(plan) }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Plans")
            .sheet(item: $selected) { plan in ReadingPlanDetailView(plan: plan, isPresented: $selected) }
        }
    }

    private func planRow(_ plan: ReadingPlan) -> some View {
        Button { selected = plan } label: {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: plan.category.icon)
                    .font(.title2).foregroundStyle(.tint).frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.title).font(.headline).foregroundStyle(.primary)
                    Text(plan.description).font(.subheadline).foregroundStyle(.secondary)
                    if let progress = plans.getProgress(for: plan.id) {
                        ProgressView(value: Double(progress.completedDays.count), total: Double(plan.duration))
                        Text("\(progress.completedDays.count) of \(plan.duration) readings complete")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("\(plan.duration) readings").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }.padding(.vertical, 12)
        }
        .accessibilityIdentifier("plans.open.\(plan.title)")
    }
}
