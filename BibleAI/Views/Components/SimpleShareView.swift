//
//  SimpleShareView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct SimpleShareView: View {
    let shareText: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Share")
                .font(.headline)
                .padding(.top)

            ShareLink(item: shareText) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Verse")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.6, green: 0.4, blue: 0.2))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            Button("Cancel") {
                isPresented = false
            }
            .padding(.bottom)
        }
        .presentationDetents([.height(200)])
    }
}

// Helper to format shareable text
extension String {
    static func formatVerseShare(text: String, reference: String, note: String? = nil) -> String {
        var result = "\"\(text)\"\n\n— \(reference)"
        if let note = note, !note.isEmpty {
            result += "\n\n💭 \(note)"
        }
        result += "\n\n📖 Shared from BibleAI"
        return result
    }

    static func formatInsightShare(question: String, answer: String) -> String {
        var result = "💡 \(question)\n\n"
        // Truncate long answers
        if answer.count > 500 {
            result += "\(answer.prefix(497))..."
        } else {
            result += answer
        }
        result += "\n\n📖 Shared from BibleAI"
        return result
    }

    static func formatHighlightShare(verse: String, reference: String, note: String? = nil) -> String {
        var result = "✨ \"\(verse)\"\n\n— \(reference)"
        if let note = note, !note.isEmpty {
            result += "\n\n💭 \(note)"
        }
        result += "\n\n📖 Shared from BibleAI"
        return result
    }
}
