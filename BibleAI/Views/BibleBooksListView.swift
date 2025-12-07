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
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.3),
                    Color(red: 0.05, green: 0.1, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Old Testament Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "book.closed")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .brown],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.system(size: 24))
                            Text("Old Testament")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)

                        ForEach(oldTestamentBooks, id: \.name) { book in
                            NavigationLink(destination: ChapterListView(book: book)) {
                                BibleBookRow(book: book, testament: .old)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // New Testament Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "book.closed.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.system(size: 24))
                            Text("New Testament")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)

                        ForEach(newTestamentBooks, id: \.name) { book in
                            NavigationLink(destination: ChapterListView(book: book)) {
                                BibleBookRow(book: book, testament: .new)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Bible Books")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}

struct BibleBookRow: View {
    let book: BibleBookInfo
    let testament: Testament

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)

                Image(systemName: testament == .old ? "book.closed" : "book.closed.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: testament == .old ? [.orange, .brown] : [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(book.chapterCount) chapters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(0.5))
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationView {
        BibleBooksListView()
    }
}
