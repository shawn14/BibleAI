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
    @State private var showSearch = false

    var oldTestamentBooks: [BibleBookInfo] {
        bibleService.getBooks(testament: .old)
    }

    var newTestamentBooks: [BibleBookInfo] {
        bibleService.getBooks(testament: .new)
    }

    var body: some View {
        List {
            Section {
                ForEach(oldTestamentBooks, id: \.name) { book in
                    NavigationLink(destination: ChapterListView(book: book)) {
                        HStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                                .font(.system(size: 20))
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("\(book.chapterCount) chapters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Old Testament")
            }

            Section {
                ForEach(newTestamentBooks, id: \.name) { book in
                    NavigationLink(destination: ChapterListView(book: book)) {
                        HStack(spacing: 12) {
                            Image(systemName: "book.closed.fill")
                                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                                .font(.system(size: 20))
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("\(book.chapterCount) chapters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("New Testament")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Bible")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                }
            }
        }
        .sheet(isPresented: $showSearch) {
            VerseSearchView(isPresented: $showSearch)
        }
    }
}

#Preview {
    NavigationView {
        BibleBooksListView()
    }
}
