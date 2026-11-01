import SwiftUI
import RevenueCat

/// Real App Store reviews only. Fill these from App Store Connect once BibleAI has them;
/// the reviews screen is skipped while the list is empty. Never invent ratings or reviews.
enum SocialProof {
    static let ratingSummary: String? = nil          // e.g. "4.8 · 1,204 ratings"
    static let reviews: [(title: String, body: String, author: String)] = []
}

private enum IntroStep: Int, CaseIterable {
    case hook, scroll, readingPlans, study, search, goal, familiarity, minutes, readingTime, commit,
         reviews, hooked, features, reminder, trialTimeline, choosePlan
}

/// Scroll-style introduction: white pages, serif headline, one black Continue button,
/// then a short paywall sequence. Closing the paywall keeps free reading available.
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var subscriptions: RevenueCatManager
    @State private var step: IntroStep = .hook
    @State private var trials: [String: Int] = [:]
    @State private var reminderDays = 2
    @State private var purchasing = false
    @State private var goal: Int?
    @State private var familiarity: Int?
    @State private var minutes: Int?
    @State private var readingTime: DailyReminder?

    private static let goals = ["Grow closer to God", "Understand the Bible better", "Build a daily habit", "Find peace and hope"]
    private static let familiarities = ["I'm new to the Bible", "I've read some of it", "I know it well"]
    private static let minuteChoices = [5, 10, 15]

    /// Starting plan picked from the answers.
    private var recommendedPlan: ReadingPlan? {
        let titles: String
        if familiarity == 0 { titles = "Gospel Tour" }
        else if goal == 3 { titles = "Psalms in a Month" }
        else if (minutes ?? 0) >= 15 { titles = "New Testament in 30 Days" }
        else { titles = "Proverbs Wisdom" }
        return ReadingPlanService.shared.availablePlans.first { $0.title == titles }
    }

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
                        .font(ScrollStyle.headline(UIDevice.current.userInterfaceIdiom == .pad ? 52 : 30))
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
        case .goal:
            IntroPage(title: "What brings you to the Bible?", subtitle: "We'll shape your reading around it.",
                      buttonEnabled: goal != nil, action: next) {
                ChoiceList(options: Self.goals.map { ($0, nil) }, selection: $goal)
            }
        case .familiarity:
            IntroPage(title: "How well do you know the Bible?", subtitle: "There's no wrong answer.",
                      buttonEnabled: familiarity != nil, action: next) {
                ChoiceList(options: Self.familiarities.map { ($0, nil) }, selection: $familiarity)
            }
        case .minutes:
            IntroPage(title: "How much time can you give each day?", subtitle: "Small and steady beats big and rare.",
                      buttonEnabled: minutes != nil, action: next) {
                ChoiceList(options: [("5 minutes", "A verse and a short study"), ("10 minutes", "A chapter a day"),
                                     ("15+ minutes", "Read through whole books")],
                           selection: Binding(get: { minutes.flatMap { Self.minuteChoices.firstIndex(of: $0) } },
                                              set: { minutes = $0.map { Self.minuteChoices[$0] } }))
            }
        case .readingTime:
            IntroPage(title: "When should we remind you to read?", subtitle: "One gentle nudge a day. Change it anytime in Settings.",
                      buttonEnabled: readingTime != nil,
                      action: { Task { await DailyReminder.set(readingTime ?? .off); next() } }) {
                ChoiceList(options: [DailyReminder.morning, .midday, .evening].map { ($0.title, $0.detail) },
                           selection: Binding(get: { readingTime.flatMap { [DailyReminder.morning, .midday, .evening].firstIndex(of: $0) } },
                                              set: { readingTime = $0.map { [DailyReminder.morning, .midday, .evening][$0] } }))
            }
        case .commit:
            CommitPage(plan: recommendedPlan, goal: goal.map { Self.goals[$0] }, minutes: minutes, reminder: readingTime) {
                if let plan = recommendedPlan, ReadingPlanService.shared.getProgress(for: plan.id) == nil {
                    ReadingPlanService.shared.startPlan(plan)
                }
                next()
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
            IntroPage(title: "How your free trial works", subtitle: nil,
                      brand: true, onClose: finish, noPaymentDue: true, footer: true,
                      buttonTitle: "Redeem \(annualTrial ?? 7) day trial for \(zeroPrice)",
                      buttonID: "paywall.redeemTrial",
                      priceLine: annualPrice.map { "\($0)/year" },
                      priceDetail: subscriptions.yearlyPackage?.storeProduct.localizedPricePerMonth.map { "(\($0)/mo)" },
                      secondary: (title: "View all plans", action: next),
                      action: redeemTrial) {
                TrialTimeline(days: annualTrial ?? 7, reminderDaysBefore: reminderDays, price: annualPrice)
            }
            .disabled(purchasing)
            .overlay { if purchasing { ProgressView().controlSize(.large) } }
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

    private var zeroPrice: String {
        let formatter = subscriptions.yearlyPackage?.storeProduct.priceFormatter ?? {
            let f = NumberFormatter(); f.numberStyle = .currency; return f
        }()
        return formatter.string(from: 0) ?? "$0.00"
    }

    /// Starts the yearly free trial straight from the timeline, then schedules the promised heads-up.
    private func redeemTrial() {
        guard let annual = subscriptions.yearlyPackage else { next(); return }
        purchasing = true
        Task {
            do {
                if try await subscriptions.purchase(package: annual) {
                    if let days = annualTrial { TrialReminder.schedule(trialDays: days, daysBefore: reminderDays) }
                    finish()
                }
            } catch { }
            purchasing = false
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        CloudSync.shared.push(.onboarded)
        isPresented = false
    }
}

// MARK: - Page template

private struct IntroPage<Visual: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let title: String?
    let subtitle: String?
    var brand = false
    var onClose: (() -> Void)? = nil
    var noPaymentDue = false
    var footer = false
    let action: () -> Void
    let visual: Visual
    var buttonTitle = "Continue"
    var buttonID = "onboarding.continue"
    var priceLine: String? = nil
    var priceDetail: String? = nil
    var secondary: (title: String, action: () -> Void)? = nil
    var buttonEnabled = true

    init(title: String?, subtitle: String?, brand: Bool = false, onClose: (() -> Void)? = nil,
         noPaymentDue: Bool = false, footer: Bool = false, buttonEnabled: Bool = true,
         buttonTitle: String = "Continue", buttonID: String = "onboarding.continue",
         priceLine: String? = nil, priceDetail: String? = nil,
         secondary: (title: String, action: () -> Void)? = nil,
         action: @escaping () -> Void,
         @ViewBuilder visual: () -> Visual) {
        self.title = title; self.subtitle = subtitle; self.brand = brand; self.onClose = onClose
        self.noPaymentDue = noPaymentDue; self.footer = footer; self.action = action; self.visual = visual()
        self.buttonTitle = buttonTitle; self.buttonID = buttonID
        self.priceLine = priceLine; self.priceDetail = priceDetail; self.secondary = secondary
        self.buttonEnabled = buttonEnabled
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
                        .font(ScrollStyle.headline(sizeClass == .regular ? 46 : 30))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("onboarding.title")
                    if let subtitle {
                        Text(subtitle).font(sizeClass == .regular ? .title3 : .footnote).foregroundStyle(ScrollStyle.muted)
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
                if let priceLine {
                    VStack(spacing: 2) {
                        Text(priceLine).font(.title3.weight(.bold))
                        if let priceDetail { Text(priceDetail).font(.subheadline).foregroundStyle(ScrollStyle.muted) }
                    }
                }
                PrimaryCapsuleButton(title: buttonTitle, identifier: buttonID, action: action)
                    .disabled(!buttonEnabled)
                    .opacity(buttonEnabled ? 1 : 0.35)
                if let secondary {
                    Button(action: secondary.action) {
                        Text(secondary.title).font(.subheadline.weight(.semibold)).underline()
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("onboarding.allPlans")
                }
                if footer { PaywallFooter(onRestored: onClose ?? {}) }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .frame(maxWidth: 560)
        }
        .frame(maxWidth: sizeClass == .regular ? 760 : .infinity)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Phone mockups (real KJV text, real BibleAI features)

private struct PhoneMock<Content: View>: View {
    let content: Content
    @Environment(\.horizontalSizeClass) private var sizeClass
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        mock.scaleEffect(sizeClass == .regular ? 1.55 : 1)
            .frame(width: sizeClass == .regular ? 310 : 200, height: sizeClass == .regular ? 605 : 390)
    }

    private var mock: some View {
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
    @Environment(\.horizontalSizeClass) private var sizeClass
    var body: some View {
        composition
            .environment(\.horizontalSizeClass, .compact)   // scale the whole picture, not each phone
            .scaleEffect(sizeClass == .regular ? 1.5 : 1)
    }

    private var composition: some View {
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
            ("lock.open", "Today", "Open the Bible like never before. Full access, everything unlocked.")
        ]
        if days - reminderDaysBefore > 0 {
            rows.append(("bell", "Day \(days - reminderDaysBefore)", "A reminder with your week in the Word, before your trial ends."))
        }
        rows.append(("checkmark", "Day \(days)", price.map { "Your plan starts at \($0)/year. Cancel anytime before then." }
                     ?? "Your plan starts. Cancel anytime before then."))
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


// MARK: - Personal questions

private struct ChoiceList: View {
    let options: [(String, String?)]
    @Binding var selection: Int?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    selection = index
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: selection == index ? "largecircle.fill.circle" : "circle").font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.0).font(.headline)
                            if let detail = option.1 { Text(detail).font(.subheadline).foregroundStyle(ScrollStyle.muted) }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.955), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(selection == index ? ScrollStyle.ink : .clear, lineWidth: 2))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == index ? .isSelected : [])
                .accessibilityIdentifier("onboarding.option.\(index)")
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 560)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 12)
    }
}

/// "Your plan is ready": a summary of the answers and a press-and-hold commitment to 7 days.
private struct CommitPage: View {
    let plan: ReadingPlan?
    let goal: String?
    let minutes: Int?
    let reminder: DailyReminder?
    let onCommit: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var progress: CGFloat = 0
    @State private var holding = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    Image("BrandMark").resizable().scaledToFit().frame(width: 44, height: 44).padding(.top, 20)
                        .accessibilityHidden(true)
                    Text("Your plan is ready").font(ScrollStyle.headline(sizeClass == .regular ? 46 : 32))
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("onboarding.title")
                    VStack(alignment: .leading, spacing: 16) {
                        if let plan { row("book", "Start with", "\(plan.title) · \(plan.duration) days") }
                        if let goal { row("heart", "Your goal", goal) }
                        if let minutes { row("clock", "Each day", minutes >= 15 ? "15+ minutes" : "\(minutes) minutes") }
                        if let reminder, reminder != .off { row("bell", "Reminder", reminder.detail) }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                    Text("People who read 7 days in a row are far more likely to keep going. Will you commit to the next 7 days?")
                        .font(.subheadline).foregroundStyle(ScrollStyle.muted).multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
            }
            VStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    Capsule().fill(ScrollStyle.ink)
                    GeometryReader { geo in
                        Capsule().fill(Color.orange).frame(width: geo.size.width * progress)
                    }
                    Text(progress >= 1 ? "Committed" : "Hold to commit to 7 days")
                        .font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity)
                }
                .frame(height: 56)
                .clipShape(Capsule())
                .contentShape(Capsule())
                .onLongPressGesture(minimumDuration: 1.2, maximumDistance: 40) {
                    progress = 1
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onCommit() }
                } onPressingChanged: { pressing in
                    if pressing { withAnimation(.linear(duration: 1.2)) { progress = 1 } }
                    else if progress < 1 { withAnimation(.easeOut(duration: 0.2)) { progress = 0 } }
                }
                .accessibilityElement()
                .accessibilityLabel("Commit to 7 days")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onCommit() }
                .accessibilityIdentifier("onboarding.commit")
                Text("Press and hold").font(.caption).foregroundStyle(ScrollStyle.muted)
            }
            .padding(.horizontal, 24).padding(.bottom, 8)
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }

    private func row(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.body.weight(.semibold)).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption.weight(.semibold)).foregroundStyle(ScrollStyle.muted)
                Text(value).font(.body.weight(.medium))
            }
        }
    }
}
