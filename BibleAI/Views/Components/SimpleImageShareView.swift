//
//  SimpleImageShareView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct SimpleImageShareView: View {
    let text: String
    let reference: String
    let note: String?
    @Binding var isPresented: Bool

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Share Verse")
                .font(.headline)
                .padding(.top)

            // Preview
            SimpleVerseImageView(text: text, reference: reference, note: note)
                .frame(width: 300, height: 300)
                .cornerRadius(12)
                .shadow(radius: 5)

            Button {
                generateAndShare()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Image")
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
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ActivityViewController(activityItems: [image])
            }
        }
    }

    @MainActor
    private func generateAndShare() {
        let view = SimpleVerseImageView(text: text, reference: reference, note: note)
            .frame(width: 1080, height: 1080)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            shareImage = image
            showShareSheet = true
        }
    }
}

struct SimpleVerseImageView: View {
    let text: String
    let reference: String
    let note: String?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Simple gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.92, blue: 0.88),
                        Color(red: 0.88, green: 0.82, blue: 0.75)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 0) {
                    // Top spacing
                    Spacer()
                        .frame(height: geometry.size.height * 0.15)

                    // Quote icon
                    Image(systemName: "quote.opening")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.4))
                        .padding(.bottom, 20)

                    // Verse text - with flexible container
                    ScrollView {
                        Text(text)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 100)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxHeight: geometry.size.height * 0.4)
                    .scrollDisabled(true)

                    // Reference
                    Text(reference)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        .padding(.top, 20)

                    // Note if exists
                    if let note = note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 16))
                            .italic()
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 120)
                            .padding(.top, 16)
                            .lineLimit(3)
                    }

                    // Bottom spacing
                    Spacer()
                        .frame(height: geometry.size.height * 0.15)

                    // Simple branding
                    Text("BibleAI")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.6))
                        .padding(.bottom, 40)
                }
            }
        }
    }
}

// UIKit wrapper for share sheet
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
