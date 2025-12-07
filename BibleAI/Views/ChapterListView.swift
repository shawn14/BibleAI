//
//  ChapterListView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct ChapterListView: View {
    let book: BibleBookInfo

    let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(1...book.chapterCount, id: \.self) { chapterNumber in
                    NavigationLink(destination: ChapterReadingView(book: book, chapter: chapterNumber)) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(book.testament == .old ? Color.brown.opacity(0.1) : Color.blue.opacity(0.1))
                                .frame(height: 60)

                            Text("\(chapterNumber)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(book.testament == .old ? .brown : .blue)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        ChapterListView(book: BibleBookInfo(name: "John", abbreviation: "John", testament: .new, chapterCount: 21))
    }
}
