//
//  ShareImageRenderer.swift
//  BibleAI
//
//  Created on 2025-12-06.
//

import SwiftUI
import UIKit

@MainActor
class ShareImageRenderer {
    static func generateImage(
        content: ShareableContent,
        template: ShareTemplate,
        includeWatermark: Bool = true
    ) -> UIImage? {
        let view = ShareTemplateView(
            content: content,
            template: template,
            includeWatermark: includeWatermark
        )

        let renderer = ImageRenderer(content: view)

        // Set scale for high quality
        renderer.scale = 3.0

        // Generate UIImage
        return renderer.uiImage
    }

    static func shareImage(_ image: UIImage, from viewController: UIViewController? = nil) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
            }
        }

        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            topVC.present(activityVC, animated: true)
        }
    }
}
