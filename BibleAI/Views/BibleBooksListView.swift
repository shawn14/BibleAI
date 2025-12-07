//
//  BibleBooksListView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct BibleBooksListView: View {
    @StateObject private var bibleService = EnhancedBibleService.shared
    @State private var selectedTestament: Testament? = nil

    var oldTestamentBooks: [BibleBookInfo] {
        bibleService.getBooks(testament: .old)
    }

    var newTestamentBooks: [BibleBookInfo] {
        bibleService.getBooks(testament: .new)
    }

    var body: some View {
        List {
            Section("Old Testament") {
                ForEach(oldTestamentBooks, id: \.name) { book in
                    NavigationLink(destination: ChapterListView(book: book)) {
                        HStack {
                            Image(systemName: "book.closed")
                                .foregroundColor(.brown)
                            VStack(alignment: .leading) {
                                Text(book.name)
                                    .font(.headline)
                                Text("\(book.chapterCount) chapters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Section("New Testament") {
                ForEach(newTestamentBooks, id: \.name) { book in
                    NavigationLink(destination: ChapterListView(book: book)) {
                        HStack {
                            Image(systemName: "book.closed.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(book.name)
                                    .font(.headline)
                                Text("\(book.chapterCount) chapters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Bible Books")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        BibleBooksListView()
    }
}
