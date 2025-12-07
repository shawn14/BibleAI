//
//  ShareTemplateView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct ShareTemplateView: View {
    let content: ShareableContent
    let template: ShareTemplate
    let includeWatermark: Bool

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: template.backgroundColor),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 24) {
                Spacer()

                // Content based on type
                switch content {
                case .verse(let text, let reference, let note):
                    VerseShareContent(
                        text: text,
                        reference: reference,
                        note: note,
                        template: template
                    )

                case .aiInsight(let question, let answer, let verse):
                    AIInsightShareContent(
                        question: question,
                        answer: answer,
                        verse: verse,
                        template: template
                    )

                case .highlight(let verse, let reference, let note, let color):
                    HighlightShareContent(
                        verse: verse,
                        reference: reference,
                        note: note,
                        color: color,
                        template: template
                    )
                }

                Spacer()

                // Watermark
                if includeWatermark {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 14))
                            Text("BibleAI")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(template.accentColor)

                        Text("AI-Powered Bible Study")
                            .font(.system(size: 12))
                            .foregroundColor(template.textColor.opacity(0.6))
                    }
                    .padding(.bottom, 32)
                }
            }
            .padding(40)
        }
        .frame(width: 1080, height: 1080) // Instagram square format
    }
}

// MARK: - Verse Share Content

struct VerseShareContent: View {
    let text: String
    let reference: String
    let note: String?
    let template: ShareTemplate

    var body: some View {
        VStack(spacing: 24) {
            // Decorative element
            Image(systemName: "quote.opening")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(template.accentColor.opacity(0.3))

            // Verse text
            Text(text)
                .font(template == .bold ? .system(size: 34, weight: .bold) : .system(size: 30, weight: .regular))
                .foregroundColor(template.textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 60)
                .fixedSize(horizontal: false, vertical: true)

            // Reference
            Text(reference)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(template.accentColor)
                .padding(.top, 8)

            // Personal note
            if let note = note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 18))
                    .italic()
                    .foregroundColor(template.textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                    .padding(.top, 16)
            }
        }
    }
}

// MARK: - AI Insight Share Content

struct AIInsightShareContent: View {
    let question: String
    let answer: String
    let verse: String?
    let template: ShareTemplate

    var body: some View {
        VStack(spacing: 24) {
            // Question
            VStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 32))
                    .foregroundColor(template.accentColor)

                Text(question)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(template.textColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Divider()
                .frame(width: 100)
                .background(template.accentColor.opacity(0.3))

            // Answer (truncated if too long)
            Text(answer.prefix(280) + (answer.count > 280 ? "..." : ""))
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(template.textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 60)
                .fixedSize(horizontal: false, vertical: true)

            // Related verse if available
            if let verse = verse {
                Text(verse)
                    .font(.system(size: 18))
                    .italic()
                    .foregroundColor(template.accentColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Highlight Share Content

struct HighlightShareContent: View {
    let verse: String
    let reference: String
    let note: String?
    let color: HighlightColor
    let template: ShareTemplate

    var body: some View {
        VStack(spacing: 24) {
            // Highlighter icon
            Image(systemName: "highlighter")
                .font(.system(size: 36))
                .foregroundColor(template.accentColor)

            // Verse with highlight background
            Text(verse)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(template.textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.color.opacity(template == .bold ? 0.3 : 0.6))
                )
                .padding(.horizontal, 50)
                .fixedSize(horizontal: false, vertical: true)

            // Reference
            Text(reference)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(template.accentColor)

            // Personal note
            if let note = note, !note.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.system(size: 16))
                        .foregroundColor(template.textColor.opacity(0.5))

                    Text(note)
                        .font(.system(size: 20))
                        .italic()
                        .foregroundColor(template.textColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                }
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    ShareTemplateView(
        content: .verse(
            text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
            reference: "John 3:16",
            note: "My favorite verse about God's love"
        ),
        template: .elegant,
        includeWatermark: true
    )
}
