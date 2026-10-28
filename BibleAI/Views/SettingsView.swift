import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptions: RevenueCatManager
    @AppStorage("reader.useSerif") private var useSerif = true
    @AppStorage("reader.textSize") private var textSize = 28.0
    @State private var showPremium = false
    @State private var showIntroduction = false

    var body: some View {
        NavigationStack {
            List {
                Section("Reading") {
                    Toggle("Serif Type", isOn: $useSerif)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Text Size")
                        Slider(value: $textSize, in: 20...38, step: 2) {
                            Text("Text Size")
                        } minimumValueLabel: {
                            Image(systemName: "textformat.size.smaller")
                        } maximumValueLabel: {
                            Image(systemName: "textformat.size.larger")
                        }
                        .accessibilityIdentifier("settings.textSize")
                    }
                    LabeledContent("Translation", value: "King James Version")
                }
                Section {
                    Text("Opened chapters are cached on this iPhone. New chapters need a connection.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("BibleAI") {
                    Button(subscriptions.isPremium ? "Your Subscription" : "Explore Premium") { showPremium = true }
                    Button("Show Introduction") { showIntroduction = true }
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                }
            }
            .listStyle(.plain)
            .navigationTitle("Reading Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showPremium) { PaywallView(isPresented: $showPremium) }
            .fullScreenCover(isPresented: $showIntroduction) { OnboardingView(isPresented: $showIntroduction) }
        }
    }
}
