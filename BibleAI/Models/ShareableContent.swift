//
//  ShareableContent.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import Foundation
import SwiftUI

enum ShareableContent {
    case verse(text: String, reference: String, note: String?)
    case aiInsight(question: String, answer: String, verse: String?)
    case highlight(verse: String, reference: String, note: String?, color: HighlightColor)

    var title: String {
        switch self {
        case .verse(_, let reference, _):
            return reference
        case .aiInsight(let question, _, _):
            return question
        case .highlight(_, let reference, _, _):
            return reference
        }
    }
}

enum ShareTemplate: String, CaseIterable {
    case minimal = "Minimal"
    case elegant = "Elegant"
    case bold = "Bold"

    var icon: String {
        switch self {
        case .minimal: return "doc.plaintext"
        case .elegant: return "sparkles"
        case .bold: return "bold"
        }
    }

    var backgroundColor: [Color] {
        switch self {
        case .minimal:
            return [.white, .white]
        case .elegant:
            return [
                Color(red: 0.95, green: 0.92, blue: 0.88),
                Color(red: 0.98, green: 0.96, blue: 0.94)
            ]
        case .bold:
            return [
                Color(red: 0.6, green: 0.4, blue: 0.2),
                Color(red: 0.7, green: 0.5, blue: 0.3)
            ]
        }
    }

    var textColor: Color {
        switch self {
        case .minimal, .elegant:
            return Color(red: 0.2, green: 0.2, blue: 0.2)
        case .bold:
            return .white
        }
    }

    var accentColor: Color {
        switch self {
        case .minimal:
            return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .elegant:
            return Color(red: 0.5, green: 0.3, blue: 0.1)
        case .bold:
            return Color(red: 1.0, green: 0.95, blue: 0.85)
        }
    }
}
