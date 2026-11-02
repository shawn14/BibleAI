import SwiftUI

/// Shows the real content before asking a recipient to personalize or subscribe.
struct InvitationLandingView: View {
    let invitation: SharedScriptureLink
    let onAccept: () -> Void
    @State private var verse: BibleVerse?
    @State private var loading = false
    @State private var error: String?

    private var plan: ReadingPlan? {
        ReadingPlanService.shared.availablePlans.first { $0.id == invitation.planID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(invitation.kind == .verse ? "A verse for you" : "An invitation to read")
                        .font(.largeTitle.bold())
                    if invitation.kind == .verse {
                        if let verse {
                            Text(verse.text).font(.system(.title2, design: .serif))
                                .lineSpacing(8).textSelection(.enabled)
                                .accessibilityIdentifier("invitation.verse")
                            Text(verse.fullReference).foregroundStyle(.secondary)
                        } else if loading {
                            ProgressView("Opening the shared verse…")
                        } else if let error {
                            Text(error).foregroundStyle(.secondary)
                            Button("Try Again") { Task { await loadVerse() } }
                                .accessibilityIdentifier("invitation.retry")
                        }
                    } else if let plan {
                        Text(plan.title).font(.title2.bold())
                            .accessibilityIdentifier("invitation.plan")
                        Text(plan.description).foregroundStyle(.secondary)
                        Text("\(plan.duration) days · Read at your own pace").font(.subheadline)
                        if let first = plan.dailyReadings.first {
                            Divider()
                            Text("Start with \(first.title)").font(.headline)
                            ForEach(first.readings) { reading in
                                Text(reading.displayText).font(.system(.body, design: .serif))
                            }
                        }
                        Text("Follow the same plan and talk about it together. Your notes and progress stay personal.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Button(action: onAccept) {
                        Label(invitation.kind == .verse ? "Keep Reading" : "Start This Plan", systemImage: "book")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(invitation.kind == .verse ? verse == nil : plan == nil)
                    .accessibilityIdentifier("invitation.accept")
                    Text("Read Scripture without an account.").font(.footnote).foregroundStyle(.secondary)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Bright Scroll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("Not Now") { GrowthStore.shared.dismissInvitation() }
                    .accessibilityIdentifier("invitation.dismiss")
            } }
            .task(id: invitation.id) {
                verse = nil
                if invitation.kind == .verse { await loadVerse() }
            }
        }
    }

    @MainActor private func loadVerse() async {
        guard let place = invitation.readingPlace else { return }
        loading = true
        error = nil
        defer { loading = false }
        do {
            let chapter = try await ScriptureChapterStore.shared.chapter(book: place.book, number: place.chapter)
            guard let found = chapter.first(where: { $0.verse == place.verse }) else {
                throw ScriptureError.invalidPassage
            }
            verse = found
        } catch { self.error = error.localizedDescription }
    }
}

/// Explicit paste supports links received before installation; never reads the clipboard automatically.
struct ImportInvitationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var link = ""
    @State private var invalid = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Paste your Bright Scroll invitation link", text: $link, axis: .vertical)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityIdentifier("invitation.link")
                    Button("Open Invitation") {
                        guard let url = URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
                              GrowthStore.shared.receive(url: url) else { invalid = true; return }
                        dismiss()
                    }
                    .disabled(link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("invitation.open")
                } footer: {
                    Text("You can also return to the message you received and tap Open in Bright Scroll after installing the app.")
                }
                if invalid {
                    Text("That link isn't a valid Bright Scroll invitation. Check that you copied the whole link.")
                        .foregroundStyle(.red).accessibilityIdentifier("invitation.invalid")
                }
            }
            .navigationTitle("Open Invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
