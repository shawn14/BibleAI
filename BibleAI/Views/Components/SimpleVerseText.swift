//
//  SimpleVerseText.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct SimpleVerseText: View {
    let content: String
    @State private var selectedReference: ParsedVerseReference?
    @State private var showVersePopup = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(content)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sheet(isPresented: $showVersePopup) {
            selectedReference = nil
        } content: {
            if let reference = selectedReference {
                VersePopupView(reference: reference, isPresented: $showVersePopup)
            }
        }
    }
}

#Preview {
    SimpleVerseText(content: "For God so loved the world (John 3:16), and we know that all things work together for good (Romans 8:28). See also Psalm 23:1-4 for more.")
        .padding()
}
