//
//  VerseReferenceText.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI
import UIKit

struct VerseReferenceText: UIViewRepresentable {
    let content: String
    @Binding var selectedVerse: ParsedVerseReference?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = context.coordinator
        textView.isSelectable = true
        textView.dataDetectorTypes = []
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        let parser = VerseParser.shared
        let references = parser.findReferences(in: content)

        let attributedString = NSMutableAttributedString(string: content)

        // Set base font and color
        let baseFont = UIFont.systemFont(ofSize: 16)
        let baseColor = UIColor.label
        attributedString.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: content.count))
        attributedString.addAttribute(.foregroundColor, value: baseColor, range: NSRange(location: 0, length: content.count))

        // Style verse references as tappable links
        for (range, reference) in references {
            let linkColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
            attributedString.addAttribute(.foregroundColor, value: linkColor, range: range)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            attributedString.addAttribute(.link, value: "verse://\(reference.displayString)", range: range)

            // Store reference in context for later lookup
            context.coordinator.references[reference.displayString] = reference
        }

        textView.attributedText = attributedString
        textView.linkTextAttributes = [
            .foregroundColor: UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedVerse: $selectedVerse)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var selectedVerse: ParsedVerseReference?
        var references: [String: ParsedVerseReference] = [:]

        init(selectedVerse: Binding<ParsedVerseReference?>) {
            _selectedVerse = selectedVerse
        }

        @available(iOS 17.0, *)
        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            if case .link(let url) = textItem.content,
               url.scheme == "verse",
               let referenceKey = url.host {
                selectedVerse = references[referenceKey]
                return nil
            }
            return defaultAction
        }

        // Fallback for iOS 16 and earlier
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
            if URL.scheme == "verse", let referenceKey = URL.host {
                selectedVerse = references[referenceKey]
            }
            return false
        }
    }
}

struct VerseReferenceTextView: View {
    let content: String
    @State private var selectedVerse: ParsedVerseReference?
    @State private var showVersePopup = false

    var body: some View {
        VerseReferenceText(content: content, selectedVerse: $selectedVerse)
            .fixedSize(horizontal: false, vertical: true)
            .onChange(of: selectedVerse) { oldValue, newValue in
                if newValue != nil {
                    showVersePopup = true
                }
            }
            .sheet(isPresented: $showVersePopup) {
                selectedVerse = nil
            } content: {
                if let verse = selectedVerse {
                    VersePopupView(reference: verse, isPresented: $showVersePopup)
                }
            }
    }
}

struct VersePopupView: View {
    let reference: ParsedVerseReference
    @Binding var isPresented: Bool
    @StateObject private var bibleService = EnhancedBibleService.shared
    @State private var verses: [BibleVerse] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else if verses.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("Verse not found")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    } else {
                        Text(reference.displayString)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                            .padding(.horizontal)
                            .padding(.top)

                        ForEach(verses) { verse in
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
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Scripture")
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
        .task {
            await loadVerse()
        }
    }

    private func loadVerse() async {
        isLoading = true

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
            }
        } else {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    VerseReferenceTextView(content: "For God so loved the world (John 3:16), and we know that all things work together for good (Romans 8:28). See also Psalm 23:1-4 for more.")
}
