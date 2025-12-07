//
//  NoteEditorView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct NoteEditorView: View {
    let highlight: Highlight?
    let book: String
    let chapter: Int
    let verse: Int
    let verseText: String
    @Binding var isPresented: Bool

    @StateObject private var highlightService = HighlightService.shared
    @State private var noteText: String = ""
    @State private var selectedColor: HighlightColor = .yellow

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Verse reference
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(book) \(chapter):\(verse)")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                    Text(verseText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(selectedColor.color)
                        .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemGray6))

                Form {
                    Section {
                        HStack(spacing: 12) {
                            ForEach(HighlightColor.allCases, id: \.self) { color in
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Highlight Color")
                    }

                    Section {
                        TextEditor(text: $noteText)
                            .frame(minHeight: 150)
                    } header: {
                        Text("Note (Optional)")
                    } footer: {
                        Text("Add your thoughts, insights, or reflections about this verse")
                    }
                }
            }
            .navigationTitle("Edit Highlight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHighlight()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if let highlight = highlight {
                noteText = highlight.note ?? ""
                selectedColor = highlight.color
            }
        }
    }

    private func saveHighlight() {
        if let existing = highlight {
            highlightService.updateHighlight(
                id: existing.id,
                color: selectedColor,
                note: noteText.isEmpty ? nil : noteText
            )
        } else {
            highlightService.addHighlight(
                book: book,
                chapter: chapter,
                verse: verse,
                verseText: verseText,
                color: selectedColor,
                note: noteText.isEmpty ? nil : noteText
            )
        }
    }
}

#Preview {
    NoteEditorView(
        highlight: nil,
        book: "John",
        chapter: 3,
        verse: 16,
        verseText: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
        isPresented: .constant(true)
    )
}
