import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var page = 0
    private let pages: [(symbol: String, title: String, detail: String)] = [
        ("book.pages", "A little Scripture.\nA little more often.",
         "Make room for the Bible in the moments you already have. One verse, then the next."),
        ("hand.draw", "Keep reading.\nWe'll keep your place.",
         "Swipe through verses, jump to a familiar passage, or follow a reading plan. Come back where you left off."),
        ("bookmark", "Make it personal.",
         "Save a verse, write a note, or open a study when you want to go deeper. Start with the Word.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Image(systemName: pages[page].symbol)
                        .font(.system(size: 64, weight: .light))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                        .padding(.top, 64)
                        .accessibilityHidden(true)
                    Text(pages[page].title)
                        .font(.system(.largeTitle, design: .serif).weight(.medium))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("onboarding.title")
                    Text(pages[page].detail)
                        .font(.body).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    Text("\(page + 1) of \(pages.count)")
                        .font(.caption).foregroundStyle(.secondary)
                        .accessibilityLabel("Introduction, page \(page + 1) of \(pages.count)")
                }
                .padding(.horizontal, 28).padding(.bottom, 32)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                Button(page == pages.count - 1 ? "Start Reading" : "Continue") {
                    if page == pages.count - 1 { finish() }
                    else { withAnimation { page += 1 } }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .buttonBorderShape(.capsule)
                .frame(maxWidth: .infinity)
                .padding(24)
                .accessibilityIdentifier("onboarding.continue")
            }
            .navigationTitle("BibleAI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if page > 0 { Button("Back") { withAnimation { page -= 1 } } }
                }
                ToolbarItem(placement: .topBarTrailing) { Button("Skip") { finish() } }
            }
        }
        .interactiveDismissDisabled()
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isPresented = false
    }
}
