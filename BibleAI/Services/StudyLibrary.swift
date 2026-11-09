import Foundation
import Combine

struct SavedStudy: Identifiable, Codable {
    enum Source: String, Codable {
        case guide = "Gospel Tour reading guide"
        case generated = "Apple Intelligence study"
    }

    let id: UUID
    let verse: BibleVerse
    let source: Source
    let title: String
    let body: String

    init(verse: BibleVerse, source: Source, title: String, body: String) {
        self.id = UUID()
        self.verse = verse
        self.source = source
        self.title = title
        self.body = body
    }

    func matches(_ other: SavedStudy) -> Bool {
        verse.fullReference == other.verse.fullReference && verse.text == other.verse.text &&
            source == other.source && title == other.title && body == other.body
    }
}

@MainActor
final class StudyLibrary: ObservableObject {
    static let shared = StudyLibrary()
    @Published private(set) var studies: [SavedStudy] = []
    @Published private(set) var readError: String?
    private let file: URL

    init(file: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("saved-studies.json")) {
        self.file = file
        reload()
    }

    func reload() {
        do {
            studies = try JSONDecoder().decode([SavedStudy].self, from: Data(contentsOf: file))
            readError = nil
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            studies = []
            readError = nil
        } catch {
            readError = "Your saved studies couldn’t be opened. Try again."
        }
    }

    func save(_ study: SavedStudy) throws {
        guard !studies.contains(where: { $0.matches(study) }) else { return }
        try write([study] + studies)
    }

    func remove(_ id: UUID) throws {
        try write(studies.filter { $0.id != id })
    }

    private func write(_ updated: [SavedStudy]) throws {
        guard readError == nil else { throw CocoaError(.fileReadCorruptFile) }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(updated).write(to: file, options: .atomic)
        studies = updated
    }
}
