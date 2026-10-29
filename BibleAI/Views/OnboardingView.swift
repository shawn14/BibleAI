import SwiftUI
import RevenueCat

/// Real App Store reviews only. Fill these from App Store Connect once BibleAI has them;
/// the reviews screen is skipped while the list is empty. Never invent ratings or reviews.
enum SocialProof {
    static let ratingSummary: String? = nil          // e.g. "4.8 · 1,204 ratings"
    static let reviews: [(title: String, body: String, author: String)] = []
}

private enum IntroStep: Int, CaseIterable {
    case hook, scroll, readingPlans, study, search, reviews, hooked, features, reminder, trialTimeline, choosePlan
}

/// Scroll-style introduction: white pages, serif headline, one black Continue button,
/// then a short paywall sequence. Closing the paywall keeps free reading available.
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var subscriptions: RevenueCatManager
    @State private var step: IntroStep = .hook
    @State private var trials: [String: Int] = [:]
    @State private var reminderDays = 2

    private var annualTrial: Int? {
        subscriptions.yearlyPackage.flatMap { trials[$0.storeProduct.productIdentifier] }
    }
    private var annualPrice: String? { subscriptions.yearlyPackage?.localizedPriceString }

    private var steps: [IntroStep] {
        IntroStep.allCases.filter { step in
            switch step {
            case .reviews: return !SocialProof.reviews.isEmpty
            case .reminder, .trialTimeline: return annualTrial != nil && !subscriptions.isPremium
            case .hooked, .features, .choosePlan: return !subscriptions.isPremium
            default: return true
            }
        }
    }

    var body: some View {
        ZStack {
            ScrollStyle.paper.ignoresSafeArea()
            screen(step)
                .id(step)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
        }
        .foregroundStyle(ScrollStyle.ink)
        .animation(.easeInOut(duration: 0.3), value: step)
        .preferredColorScheme(.light)
        .interactiveDismissDisabled()
        .task(id: subscriptions.offerings?.current?.identifier) {
            let packages = [subscriptions.yearlyPackage, subscriptions.monthlyPackage].compactMap { $0 }
            trials = await TrialMath.eligibleTrials(packages)
        }
    }

    // MARK: Screens

    @ViewBuilder
    private func screen(_ step: IntroStep) -> some View {
        switch step {
        case .hook:
            IntroPage(title: nil, subtitle: nil, action: next) {
                VStack(spacing: 14) {
                    Text("The average person will spend **2+ hours today** scrolling social media.")
                        .font(ScrollStyle.headline(30))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("What if some of that time went to God's Word?")
                        .font(.footnote).foregroundStyle(ScrollStyle.muted)
                }
                .padding(.horizontal, 32)
            }
        case .scroll:
            IntroPage(title: "What if scrolling actually fed your soul?",
                      subtitle: "Just keep swiping, one verse at a time.", action: next) {
                PhoneMock { VerseMock() }
            }
        case .readingPlans:
            IntroPage(title: "Reading the whole Bible feels impossible, until now.",
                      subtitle: "Pick a reading plan and follow it, one day at a time.", action: next) {
                PhoneMock { PlansMock() }
            }
        case .study:
            IntroPage(title: "Every verse has a story you've never heard.",
                      subtitle: "Scroll verses and open a deep study on any of them.", action: next) {
                PhoneMock { StudyMock() }
            }
        case .search:
            IntroPage(title: "Search any verse and go deeper than ever before.",
                      subtitle: "Jump to any passage in all 66 books.", action: next) {
                PhoneMock { SearchMock() }
            }
        case .reviews:
            IntroPage(title: "Lives are being changed.",
                      subtitle: "Readers are discovering Scripture like never before.", action: next) {
                ReviewsList()
            }
        case .hooked:
            IntroPage(title: "Get hooked on the Bible instead",
                      subtitle: "The Bible app that keeps you coming back",
                      brand: true, onClose: finish, noPaymentDue: annualTrial != nil, footer: true, action: next) {
                HookedVisual()
            }
        case .features:
            IntroPage(title: "Everything you need to go deeper",
                      subtitle: "Unlock the full BibleAI experience",
                      brand: true, onClose: finish, noPaymentDue: annualTrial != nil, footer: true, action: next) {
                FeatureChecklist()
            }
        case .reminder:
            IntroPage(title: "We'll remind you, we promise",
                      subtitle: "Before your trial ends, we'll send a heads-up so you can decide with zero pressure.",
                      brand: true, onClose: finish, noPaymentDue: true, footer: true,
                      action: {
                          UserDefaults.standard.set(reminderDays, forKey: TrialReminder.daysBeforeKey)
                          Task { await TrialReminder.requestPermission(); next() }
                      }) {
                ReminderPicker(days: $reminderDays)
            }
        case .trialTimeline:
            IntroPage(title: "How your free trial works",
                      subtitle: "Cancel anytime in Settings. We'll remind you first.",
                      brand: true, onClose: finish, noPaymentDue: true, footer: true, action: next) {
                TrialTimeline(days: annualTrial ?? 7, reminderDaysBefore: reminderDays, price: annualPrice)
            }
        case .choosePlan:
            PlanPickerScreen(trials: trials, reminderDaysBefore: reminderDays,
                             onClose: finish, onPurchased: finish)
        }
    }

    private func next() {
        let order = steps
        if let index = order.firstIndex(of: step), index + 1 < order.count {
            step = order[index + 1]
        } else if let later = order.first(where: { $0.rawValue > step.rawValue }) {
            step = later
        } else {
            finish()
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isPresented = false
    }
}

// MARK: - Page template

private struct IntroPage<Visual: View>: View {
    let title: String?
    let subtitle: String?
    var brand = false
    var onClose: (() -> Void)? = nil
    var noPaymentDue = false
    var footer = false
    let action: () -> Void
    let visual: Visual

    init(title: String?, subtitle: String?, brand: Bool = false, onClose: (() -> Void)? = nil,
         noPaymentDue: Bool = false, footer: Bool = false, action: @escaping () -> Void,
         @ViewBuilder visual: () -> Visual) {
        self.title = title; self.subtitle = subtitle; self.brand = brand; self.onClose = onClose
        self.noPaymentDue = noPaymentDue; self.footer = footer; self.action = action; self.visual = visual()
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if brand { BrandMark() }
                if let onClose {
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "xmark").font(.body.weight(.medium))
                                .foregroundStyle(ScrollStyle.muted).frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Close")
                        .accessibilityIdentifier("onboarding.close")
                        Spacer()
                    }
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 12)

            if let title {
                VStack(spacing: 10) {
                    Text(title)
                        .font(ScrollStyle.headline(30))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("onboarding.title")
                    if let subtitle {
                        Text(subtitle).font(.footnote).foregroundStyle(ScrollStyle.muted)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)
            }

            visual
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 16)

            VStack(spacing: 12) {
                if noPaymentDue {
                    Label("No payment due now", systemImage: "checkmark").font(.footnote.weight(.semibold))
                }
                PrimaryCapsuleButton(title: "Continue", action: action)
                if footer { PaywallFooter(onRestored: onClose ?? {}) }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Phone mockups (real KJV text, real BibleAI features)

private struct PhoneMock<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .frame(width: 200, height: 390)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.black, lineWidth: 6))
            .overlay(alignment: .top) { Capsule().fill(Color.black).frame(width: 62, height: 18).padding(.top, 10) }
            .shadow(color: .black.opacity(0.15), radius: 18, y: 10)
            .accessibilityHidden(true)
    }
}

private struct VerseMock: View {
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                Text("For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.")
                    .font(.system(size: 13, design: .serif))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                Text("John 3:16").font(.system(size: 9)).foregroundStyle(ScrollStyle.muted)
            }
            .padding(.horizontal, 30)
            VStack {
                HStack {
                    Text("KJV").font(.system(size: 8, weight: .semibold))
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .overlay(Capsule().stroke(ScrollStyle.hairline))
                    Spacer()
                }
                .padding(.top, 36).padding(.horizontal, 14)
                Spacer()
            }
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                    Image(systemName: "text.book.closed")
                    Image(systemName: "square.and.pencil")
                    Image(systemName: "square.and.arrow.up")
                }
                .font(.system(size: 12))
                .padding(.trailing, 8)
                .padding(.top, 140)
            }
        }
    }
}

private struct PlansMock: View {
    private let plans = [("Gospel Tour", "8 days"), ("Psalms in a Month", "30 days"),
                         ("New Testament in 30 Days", "30 days"), ("Proverbs Wisdom", "31 days")]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Plans").font(.system(size: 16, weight: .bold)).padding(.top, 40).padding(.bottom, 10)
            ForEach(plans, id: \.0) { plan in
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.0).font(.system(size: 11, weight: .semibold))
                    Text(plan.1).font(.system(size: 9)).foregroundStyle(ScrollStyle.muted)
                }
                .padding(.vertical, 9)
                Divider()
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

private struct StudyMock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("John 3:16").font(.system(size: 15, weight: .bold, design: .serif)).padding(.top, 40)
            ForEach(["Explain This Verse", "Historical Context", "Related Scripture", "Original Language"], id: \.self) { item in
                HStack {
                    Text(item).font(.system(size: 10))
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 8))
                }
                Divider()
            }
            Text("Meaning").font(.system(size: 11, weight: .semibold)).padding(.top, 4)
            ForEach(0..<5, id: \.self) { line in
                RoundedRectangle(cornerRadius: 2).fill(Color.black.opacity(0.08))
                    .frame(width: line == 4 ? 90 : nil, height: 6)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

private struct SearchMock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.system(size: 10))
                Text("Psalm 23").font(.system(size: 11))
                Spacer()
            }
            .padding(8)
            .background(Color.black.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            .padding(.top, 40)
            ForEach([("Psalm 23:1", "The LORD is my shepherd; I shall not want."),
                     ("Psalm 23:4", "Yea, though I walk through the valley of the shadow of death, I will fear no evil…")], id: \.0) { row in
                VStack(alignment: .leading, spacing: 3) {
                    Text(row.0).font(.system(size: 10, weight: .semibold))
                    Text(row.1).font(.system(size: 10, design: .serif)).foregroundStyle(ScrollStyle.muted)
                }
                Divider()
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

private struct HookedVisual: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color.black).frame(width: 250, height: 210).offset(y: 50)
            PhoneMock { ChapterMock() }.scaleEffect(0.78).rotationEffect(.degrees(-6)).offset(x: -46, y: -6)
            PhoneMock { VerseMock() }.scaleEffect(0.72).offset(x: 58, y: 34)
        }
    }
}

private struct ChapterMock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("John 3").font(.system(size: 14, weight: .bold, design: .serif)).padding(.top, 40)
            ForEach(0..<16, id: \.self) { line in
                RoundedRectangle(cornerRadius: 2).fill(Color.black.opacity(0.1))
                    .frame(width: line % 5 == 4 ? 100 : nil, height: 5)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

private struct ReviewsList: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let summary = SocialProof.ratingSummary {
                    HStack(spacing: 6) {
                        Text(summary).font(.subheadline.weight(.semibold))
                        Text("★★★★★").foregroundStyle(.orange)
                    }
                }
                ForEach(Array(SocialProof.reviews.enumerated()), id: \.offset) { _, review in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("★★★★★").font(.caption).foregroundStyle(.orange)
                        Text(review.title).font(.subheadline.weight(.bold))
                        Text(review.body).font(.footnote)
                        Text(review.author).font(.caption2).foregroundStyle(ScrollStyle.muted)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .leading) { Rectangle().fill(Color.orange.opacity(0.6)).frame(width: 3) }
                    .background(Color.black.opacity(0.03))
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct FeatureChecklist: View {
    private let sections: [(String, [String])] = [
        ("STUDY TOOLS", ["Verse-by-verse deep studies", "\u{201C}Explain it simply\u{201D} studies", "Related Scripture and reference search"]),
        ("LANGUAGE & CONTEXT", ["Greek & Hebrew key words", "Historical and cultural context", "AI-assisted, read alongside the chapter"]),
        ("YOUR EXPERIENCE", ["Save your favorite verses and notes", "Guided reading plans", "Pick up right where you left off"])
    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(sections, id: \.0) { section in
                    VStack(alignment: .leading, spacing: 9) {
                        Text(section.0).font(.caption.weight(.bold)).foregroundStyle(ScrollStyle.muted)
                        ForEach(section.1, id: \.self) { item in
                            Label {
                                Text(item).font(.subheadline)
                            } icon: {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
        }
    }
}

private struct ReminderPicker: View {
    @Binding var days: Int
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell").font(.system(size: 92, weight: .ultraLight))
                Circle().fill(Color.red).frame(width: 20, height: 20).offset(x: -4, y: 6)
            }
            .accessibilityHidden(true)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 18) {
                option(2, "Recommended time to reflect")
                option(3, "Extra peace of mind")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
        }
    }

    private func option(_ value: Int, _ note: String) -> some View {
        Button { days = value } label: {
            HStack(spacing: 14) {
                Image(systemName: days == value ? "largecircle.fill.circle" : "circle").font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(value) days before").font(.subheadline.weight(.semibold))
                    Text(note).font(.caption).foregroundStyle(ScrollStyle.muted)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(days == value ? .isSelected : [])
        .accessibilityIdentifier("reminder.\(value)")
    }
}

private struct TrialTimeline: View {
    let days: Int
    let reminderDaysBefore: Int
    let price: String?

    private var rows: [(icon: String, title: String, detail: String)] {
        var rows: [(icon: String, title: String, detail: String)] = [
            ("lock.open", "Today", "Unlock every study tool. No payment due now.")
        ]
        if days - reminderDaysBefore > 0 {
            rows.append(("bell", "Day \(days - reminderDaysBefore)", "We'll remind you that your trial is ending soon."))
        }
        rows.append(("star", "Day \(days)", price.map { "Your subscription starts at \($0)/year. Cancel anytime before." }
                     ?? "Your subscription starts. Cancel anytime before."))
        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        Image(systemName: row.icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 38, height: 38).background(Color.black, in: Circle())
                        if index < rows.count - 1 {
                            Rectangle().fill(ScrollStyle.hairline).frame(width: 2, height: 46)
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(row.title).font(.headline)
                        Text(row.detail).font(.subheadline).foregroundStyle(ScrollStyle.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 32)
    }
}
