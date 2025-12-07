//
//  VerseSearchView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct VerseSearchView: View {
    @StateObject private var bibleService = EnhancedBibleService.shared
    @State private var searchText = ""
    @State private var searchResult: ParsedVerseReference?
    @State private var verses: [BibleVerse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))

                    TextField("e.g., John 3:16 or Genesis 1", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResult = nil
                            verses = []
                            errorMessage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                // Results
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else if verses.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                        VStack(spacing: 8) {
                            Text("Search for a Verse")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("Enter a reference like \"John 3:16\"\nor \"Genesis 1:1-3\"")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: 12) {
                            Text("Quick examples:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            VStack(spacing: 8) {
                                QuickSearchButton(text: "John 3:16") {
                                    searchText = "John 3:16"
                                    performSearch()
                                }

                                QuickSearchButton(text: "Psalm 23") {
                                    searchText = "Psalm 23"
                                    performSearch()
                                }

                                QuickSearchButton(text: "Romans 8:28") {
                                    searchText = "Romans 8:28"
                                    performSearch()
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let result = searchResult {
                                Text(result.displayString)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                                    .padding(.horizontal)
                                    .padding(.top)
                            }

                            ForEach(verses) { verse in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(verse.verse)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                                            .frame(width: 30, alignment: .trailing)

                                        Text(verse.text)
                                            .font(.system(size: 17))
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Search Bible")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                }
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        let parser = VerseParser.shared
        guard let reference = parser.parseReference(searchText) else {
            errorMessage = "Invalid verse reference. Try \"John 3:16\" or \"Psalm 23:1-3\""
            verses = []
            return
        }

        searchResult = reference
        isLoading = true
        errorMessage = nil

        Task {
            if let fetchedVerses = await bibleService.getChapter(book: reference.book, chapter: reference.chapter) {
                await MainActor.run {
                    // Filter to specific verses if specified
                    if let startVerse = reference.verse {
                        let endVerse = reference.endVerse ?? startVerse
                        verses = fetchedVerses.filter { verse in
                            verse.verse >= startVerse && verse.verse <= endVerse
                        }
                    } else {
                        // Show whole chapter
                        verses = fetchedVerses
                    }
                    isLoading = false

                    if verses.isEmpty {
                        errorMessage = "Verse not found"
                    }
                }
            } else {
                await MainActor.run {
                    errorMessage = "Failed to load verse. Please check your connection and try again."
                    isLoading = false
                }
            }
        }
    }
}

struct QuickSearchButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                    .frame(width: 20)

                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.6))
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VerseSearchView(isPresented: .constant(true))
}
