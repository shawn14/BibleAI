import SwiftUI

/// Shown after marking a plan day complete: the reading, an encouraging verse and the reading streak.
struct DayCompleteView: View {
    let reading: String
    let hasNextDay: Bool
    let onDone: () -> Void
    let onContinue: () -> Void
    @ObservedObject private var streaks = StreakStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private static let verses: [(text: String, reference: String)] = [
        ("As newborn babes, desire the sincere milk of the word, that ye may grow thereby.", "1 Peter 2:2"),
        ("Thy word is a lamp unto my feet, and a light unto my path.", "Psalm 119:105"),
        ("Thy word have I hid in mine heart, that I might not sin against thee.", "Psalm 119:11"),
        ("Man shall not live by bread alone, but by every word that proceedeth out of the mouth of God.", "Matthew 4:4"),
        ("His compassions fail not. They are new every morning: great is thy faithfulness.", "Lamentations 3:22–23"),
        ("Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.", "Joshua 1:9"),
        ("Draw nigh to God, and he will draw nigh to you.", "James 4:8")
    ]
    private var verse: (text: String, reference: String) {
        let index = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return Self.verses[index % Self.verses.count]
    }
    private var streak: Int { streaks.currentStreak() }
    private var caption: String {
        switch streak {
        case 0...1: return "Every journey starts with a single day."
        case 2...6: return "You're building the habit. Keep showing up."
        case 7...29: return "A full week and counting. Well done."
        default: return "Faithful, day after day."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.primary)
                        .scaleEffect(appeared || reduceMotion ? 1 : 0.6)
                        .opacity(appeared || reduceMotion ? 1 : 0)
                        .padding(.top, 36)
                        .accessibilityHidden(true)
                    VStack(spacing: 6) {
                        Text("Well done.").font(.largeTitle.bold()).accessibilityIdentifier("streak.title")
                        Text("Today's reading is complete.").font(.headline)
                        Text(reading).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "quote.opening").font(.title3.bold()).accessibilityHidden(true)
                        Text(verse.text).font(.system(.body, design: .serif))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(verse.reference).font(.footnote).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 14) {
                            Image(systemName: "flame.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(streak)").font(.largeTitle.bold()).monospacedDigit()
                                    .accessibilityIdentifier("streak.count")
                                Text("DAY STREAK")
                                    .font(.caption.weight(.semibold)).kerning(1.2).foregroundStyle(.secondary)
                            }
                        }
                        Text(caption).font(.subheadline).foregroundStyle(.secondary)
                        HStack(spacing: 0) {
                            ForEach(streaks.lastSevenDays(), id: \.date) { day in
                                VStack(spacing: 8) {
                                    Text(day.date.formatted(.dateTime.weekday(.narrow)))
                                        .font(.caption2).foregroundStyle(.secondary)
                                    ZStack {
                                        Circle().fill(day.read ? Color.orange : Color(.tertiarySystemFill))
                                        if day.read {
                                            Image(systemName: "flame.fill").font(.caption).foregroundStyle(.white)
                                        }
                                        if Calendar.current.isDateInToday(day.date) {
                                            Circle().stroke(Color.primary, lineWidth: 2).padding(-3)
                                        }
                                    }
                                    .frame(width: 30, height: 30)
                                }
                                .frame(maxWidth: .infinity)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("\(day.date.formatted(.dateTime.weekday(.wide))), \(day.read ? "read" : "not read")")
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            VStack(spacing: 10) {
                Button(action: onDone) {
                    Text("Done for today").font(.headline).foregroundStyle(Color(.systemBackground))
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Color.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("streak.done")
                if hasNextDay {
                    Button(action: onContinue) {
                        Label("Continue Reading", systemImage: "arrow.right").labelStyle(TrailingIconLabelStyle())
                            .font(.headline).foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("streak.continue")
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 12)
            .frame(maxWidth: 560)
        }
        .onAppear {
            if reduceMotion { appeared = true } else { withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { appeared = true } }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) { configuration.title; configuration.icon }
    }
}
