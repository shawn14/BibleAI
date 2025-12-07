//
//  ShareSheetView.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI

struct ShareSheetView: View {
    let content: ShareableContent
    @Binding var isPresented: Bool

    @State private var selectedTemplate: ShareTemplate = .elegant
    @State private var includeWatermark = true
    @State private var isGenerating = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Preview
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top)

                        // Template preview (scaled down)
                        ShareTemplateView(
                            content: content,
                            template: selectedTemplate,
                            includeWatermark: includeWatermark
                        )
                        .frame(width: 300, height: 300)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Template selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Style")
                                .font(.headline)
                                .padding(.horizontal)

                            HStack(spacing: 12) {
                                ForEach(ShareTemplate.allCases, id: \.self) { template in
                                    TemplateOptionButton(
                                        template: template,
                                        isSelected: selectedTemplate == template
                                    ) {
                                        selectedTemplate = template
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Options
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Options")
                                .font(.headline)
                                .padding(.horizontal)

                            Toggle(isOn: $includeWatermark) {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                                    Text("Include BibleAI branding")
                                        .font(.subheadline)
                                }
                            }
                            .padding(.horizontal)
                            .tint(Color(red: 0.6, green: 0.4, blue: 0.2))
                        }
                        .padding(.bottom, 24)
                    }
                }

                // Share button
                Button(action: generateAndShare) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Image")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.6, green: 0.4, blue: 0.2))
                    .cornerRadius(12)
                }
                .disabled(isGenerating)
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                }
            }
        }
    }

    private func generateAndShare() {
        isGenerating = true

        Task {
            // Small delay to show loading state
            try? await Task.sleep(nanoseconds: 300_000_000)

            if let image = await ShareImageRenderer.generateImage(
                content: content,
                template: selectedTemplate,
                includeWatermark: includeWatermark
            ) {
                await MainActor.run {
                    ShareImageRenderer.shareImage(image)
                    isPresented = false
                    isGenerating = false
                }
            } else {
                await MainActor.run {
                    isGenerating = false
                }
            }
        }
    }
}

struct TemplateOptionButton: View {
    let template: ShareTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: template.backgroundColor),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 80)

                    VStack(spacing: 4) {
                        Image(systemName: template.icon)
                            .font(.system(size: 24))
                            .foregroundColor(template.textColor)

                        Text("Aa")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(template.textColor)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color.clear,
                            lineWidth: 3
                        )
                )

                Text(template.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? Color(red: 0.6, green: 0.4, blue: 0.2) : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ShareSheetView(
        content: .verse(
            text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
            reference: "John 3:16",
            note: nil
        ),
        isPresented: .constant(true)
    )
}
