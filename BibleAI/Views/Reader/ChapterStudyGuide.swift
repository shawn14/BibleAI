import SwiftUI

enum GospelTourGuide {
    static func study(for verse: BibleVerse) -> SavedStudy? {
        let title: String
        let body: String
        switch (verse.book, verse.chapter) {
        case ("Matthew", 1):
            title = "Why Matthew starts with a family tree"
            body = """
                Matthew introduces Jesus through Abraham and David, then traces the family down to Joseph and Mary. Look for David and the exile as landmarks in the list (Matthew 1:1–17).

                Read alongside Luke 1:26–33. Where does David appear in the angel’s words to Mary?
                """
        case ("Matthew", 2):
            title = "Two responses to a new king"
            body = """
                When visitors ask about the newborn king, Herod seeks information and the visitors bring gifts. Follow what each does after hearing about Bethlehem (Matthew 2:1–12).

                Read alongside Micah 5:2. Notice why Bethlehem enters the conversation in Matthew 2:4–6.
                """
        case ("Luke", 1):
            title = "Mary hears the news"
            body = """
                Gabriel tells Mary about the child she will bear. Notice Mary’s question and her response after the angel answers (Luke 1:26–38).

                Read alongside Matthew 1:18–25. What does Joseph learn about the same child?
                """
        case ("Luke", 2):
            title = "Who hears the birth announcement?"
            body = """
                The shepherds hear the news while watching their flock. Follow them to Bethlehem, then notice what they tell others and what Mary keeps in mind (Luke 2:8–20).

                Read alongside Luke 1:46–55. What connections do you see between Mary’s song and the people who first hear this news?
                """
        default: return nil
        }
        return SavedStudy(verse: verse, source: .guide, title: title, body: body)
    }
}

struct StudySaveButton: View {
    let study: SavedStudy
    @ObservedObject private var library = StudyLibrary.shared
    @State private var error: String?

    var body: some View {
        let saved = library.studies.contains { $0.matches(study) }
        Button(saved ? "Study saved" : "Save study", systemImage: saved ? "bookmark.fill" : "bookmark") {
            do { try library.save(study); error = nil }
            catch { self.error = "Couldn’t save this study. Try again." }
        }
        .disabled(saved)
        .accessibilityIdentifier("study.save")
        if let error { Text(error).font(.footnote).foregroundStyle(.secondary) }
    }
}

struct StudyDetailView: View {
    let study: SavedStudy
    var canSave = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(study.title).font(.title2.bold())
                Text(study.verse.text).font(.system(.title3, design: .serif))
                Text(study.verse.fullReference).foregroundStyle(.secondary)
                Divider()
                Text(study.body).textSelection(.enabled).lineSpacing(4)
                    .accessibilityIdentifier("study.body")
                Text(study.source.rawValue).font(.footnote).foregroundStyle(.secondary)
                if canSave { StudySaveButton(study: study) }
            }.frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .navigationTitle(canSave ? "Reading guide" : "Saved study")
        .navigationBarTitleDisplayMode(.inline)
    }
}
