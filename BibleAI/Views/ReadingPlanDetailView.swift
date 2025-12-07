//
//  ReadingPlanDetailView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct ReadingPlanDetailView: View {
    let plan: ReadingPlan
    @Binding var isPresented: ReadingPlan?

    @StateObject private var planService = ReadingPlanService.shared
    @State private var selectedReading: ReadingReference?
    @State private var showDeleteConfirmation = false

    var progress: UserPlanProgress? {
        planService.getProgress(for: plan.id)
    }

    var isStarted: Bool {
        progress != nil
    }

    var currentDay: Int {
        progress?.currentDay ?? 1
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: plan.category.icon)
                                .font(.system(size: 32))
                                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                            Spacer()

                            if isStarted {
                                Button(action: {
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        Text(plan.title)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(plan.description)
                            .font(.body)
                            .foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            Label("\(plan.duration) days", systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Label(plan.category.rawValue, systemImage: plan.category.icon)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Progress bar
                        if let progress = progress {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Progress")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Spacer()

                                    Text("\(progress.completedDays.count) of \(plan.duration) days")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(height: 8)
                                            .cornerRadius(4)

                                        Rectangle()
                                            .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                                            .frame(width: geometry.size.width * (progress.progressPercentage / 100.0), height: 8)
                                            .cornerRadius(4)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding(.top, 8)
                        }

                        // Start button
                        if !isStarted {
                            Button(action: {
                                planService.startPlan(plan)
                            }) {
                                Text("Start Plan")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(red: 0.6, green: 0.4, blue: 0.2))
                                    .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)

                    // Daily Readings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Readings")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        ForEach(plan.dailyReadings) { dailyReading in
                            DailyReadingRow(
                                dailyReading: dailyReading,
                                plan: plan,
                                isCompleted: planService.isDayComplete(planId: plan.id, day: dailyReading.day),
                                isCurrent: isStarted && dailyReading.day == currentDay,
                                onToggleComplete: {
                                    planService.markDayComplete(planId: plan.id, day: dailyReading.day)
                                },
                                onReadTapped: { reference in
                                    selectedReading = reference
                                }
                            )
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Plan Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = nil
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                }
            }
            .sheet(item: $selectedReading) { reference in
                ReadingReferenceSheet(reference: reference, isPresented: $selectedReading)
            }
            .alert("Delete Plan Progress", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    planService.deletePlanProgress(plan.id)
                    isPresented = nil
                }
            } message: {
                Text("Are you sure you want to delete your progress for this plan? This cannot be undone.")
            }
        }
    }
}

struct DailyReadingRow: View {
    let dailyReading: DailyReading
    let plan: ReadingPlan
    let isCompleted: Bool
    let isCurrent: Bool
    let onToggleComplete: () -> Void
    let onReadTapped: (ReadingReference) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Day indicator
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color(.systemGray5))
                        .frame(width: 36, height: 36)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(dailyReading.day)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(dailyReading.title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isCurrent {
                            Text("Today")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.6, green: 0.4, blue: 0.2))
                                .cornerRadius(4)
                        }
                    }

                    // Reading references
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(dailyReading.readings) { reference in
                            Button(action: {
                                onReadTapped(reference)
                            }) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.caption)
                                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                                    Text(reference.displayText)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Mark as complete button
                    if !isCompleted {
                        Button(action: onToggleComplete) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Mark as Complete")
                                    .font(.subheadline)
                            }
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        }
                    }
                }
            }
        }
        .padding()
        .background(isCurrent ? Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.05) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

struct ReadingReferenceSheet: View {
    let reference: ReadingReference
    @Binding var isPresented: ReadingReference?
    @State private var navigationPath = NavigationPath()

    var bookInfo: BibleBookInfo? {
        BibleBookInfo.allBooks.first { $0.name == reference.book }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                    Text(reference.displayText)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Ready to read?")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                if let book = bookInfo {
                    NavigationLink(value: book) {
                        Text("Start Reading")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: 300)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.6, green: 0.4, blue: 0.2))
                            .cornerRadius(12)
                    }
                } else {
                    Text("Book not found")
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = nil
                    }
                }
            }
            .navigationDestination(for: BibleBookInfo.self) { book in
                ChapterReadingView(
                    book: book,
                    chapter: reference.startChapter
                )
            }
        }
    }
}

#Preview {
    ReadingPlanDetailView(
        plan: ReadingPlan(
            title: "Gospel Tour",
            description: "Experience the life of Jesus",
            duration: 8,
            category: .overview,
            dailyReadings: []
        ),
        isPresented: .constant(nil)
    )
}
