//
//  ReadingPlansListView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct ReadingPlansListView: View {
    @StateObject private var planService = ReadingPlanService.shared
    @State private var selectedPlan: ReadingPlan?

    var activePlans: [ReadingPlan] {
        planService.availablePlans.filter { plan in
            planService.userProgress.contains(where: { $0.planId == plan.id })
        }
    }

    var availablePlans: [ReadingPlan] {
        planService.availablePlans.filter { plan in
            !planService.userProgress.contains(where: { $0.planId == plan.id })
        }
    }

    var body: some View {
        NavigationView {
            List {
                // Active Plans
                if !activePlans.isEmpty {
                    Section {
                        ForEach(activePlans) { plan in
                            Button(action: {
                                selectedPlan = plan
                            }) {
                                ActivePlanRow(plan: plan)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } header: {
                        Text("My Plans")
                    }
                }

                // Available Plans
                Section {
                    ForEach(availablePlans) { plan in
                        Button(action: {
                            selectedPlan = plan
                        }) {
                            AvailablePlanRow(plan: plan)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: {
                    Text(activePlans.isEmpty ? "Available Plans" : "Explore More")
                }
            }
            .navigationTitle("Reading Plans")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedPlan) { plan in
                ReadingPlanDetailView(plan: plan, isPresented: $selectedPlan)
            }
        }
    }
}

struct ActivePlanRow: View {
    let plan: ReadingPlan
    @StateObject private var planService = ReadingPlanService.shared

    var progress: UserPlanProgress? {
        planService.getProgress(for: plan.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(plan.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            // Progress bar
            if let progress = progress {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(progress.completedDays.count) of \(plan.duration) days")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(Int(progress.progressPercentage))%")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                            .fontWeight(.medium)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 6)
                                .cornerRadius(3)

                            Rectangle()
                                .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                                .frame(width: geometry.size.width * (progress.progressPercentage / 100.0), height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct AvailablePlanRow: View {
    let plan: ReadingPlan

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: plan.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(plan.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label("\(plan.duration) days", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(plan.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ReadingPlansListView()
}
