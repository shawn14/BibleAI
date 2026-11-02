import Foundation

struct ReadingPlace: Codable, Equatable {
    let book: String
    let chapter: Int
    let verse: Int

    var id: String { "\(book)|\(chapter)|\(verse)" }
    static let beginning = ReadingPlace(book: "Genesis", chapter: 1, verse: 1)
}
