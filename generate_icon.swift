#!/usr/bin/env swift

import AppKit
import Foundation

// Create a 1024x1024 app icon for BibleAI
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

// Background gradient (deep blue to lighter blue)
let gradient = NSGradient(colors: [
    NSColor(red: 0.2, green: 0.3, blue: 0.6, alpha: 1.0),
    NSColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
])
gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 135)

// Draw a book shape
let context = NSGraphicsContext.current?.cgContext

// Book background (lighter color)
context?.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
let bookRect = NSRect(x: 212, y: 212, width: 600, height: 600)
let bookPath = NSBezierPath(roundedRect: bookRect, xRadius: 40, yRadius: 40)
bookPath.fill()

// Book spine shadow
context?.setFillColor(NSColor.black.withAlphaComponent(0.1).cgColor)
let spineRect = NSRect(x: 512, y: 212, width: 20, height: 600)
NSBezierPath(rect: spineRect).fill()

// Left page
context?.setFillColor(NSColor.white.withAlphaComponent(0.98).cgColor)
let leftPageRect = NSRect(x: 232, y: 232, width: 260, height: 560)
let leftPagePath = NSBezierPath(roundedRect: leftPageRect, xRadius: 20, yRadius: 20)
leftPagePath.fill()

// Right page
let rightPageRect = NSRect(x: 532, y: 232, width: 260, height: 560)
let rightPagePath = NSBezierPath(roundedRect: rightPageRect, xRadius: 20, yRadius: 20)
rightPagePath.fill()

// Draw AI sparkle/stars
context?.setFillColor(NSColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0).cgColor)

// Function to draw a sparkle
func drawSparkle(at point: NSPoint, size: CGFloat) {
    let sparkle = NSBezierPath()
    sparkle.move(to: NSPoint(x: point.x, y: point.y - size))
    sparkle.line(to: NSPoint(x: point.x + size * 0.3, y: point.y - size * 0.3))
    sparkle.line(to: NSPoint(x: point.x + size, y: point.y))
    sparkle.line(to: NSPoint(x: point.x + size * 0.3, y: point.y + size * 0.3))
    sparkle.line(to: NSPoint(x: point.x, y: point.y + size))
    sparkle.line(to: NSPoint(x: point.x - size * 0.3, y: point.y + size * 0.3))
    sparkle.line(to: NSPoint(x: point.x - size, y: point.y))
    sparkle.line(to: NSPoint(x: point.x - size * 0.3, y: point.y - size * 0.3))
    sparkle.close()
    sparkle.fill()
}

// Draw sparkles
drawSparkle(at: NSPoint(x: 350, y: 700), size: 30)
drawSparkle(at: NSPoint(x: 650, y: 650), size: 25)
drawSparkle(at: NSPoint(x: 380, y: 350), size: 20)
drawSparkle(at: NSPoint(x: 680, y: 380), size: 22)

// Draw text "AI" in modern font
let textAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 180, weight: .bold),
    .foregroundColor: NSColor(red: 0.2, green: 0.3, blue: 0.6, alpha: 1.0)
]

let aiText = "AI" as NSString
let textSize = aiText.size(withAttributes: textAttributes)
let textRect = NSRect(
    x: (size.width - textSize.width) / 2,
    y: (size.height - textSize.height) / 2 - 50,
    width: textSize.width,
    height: textSize.height
)
aiText.draw(in: textRect, withAttributes: textAttributes)

// Draw cross symbol above AI
context?.setStrokeColor(NSColor(red: 0.2, green: 0.3, blue: 0.6, alpha: 1.0).cgColor)
context?.setLineWidth(20)
context?.setLineCap(.round)

// Vertical line of cross
context?.move(to: CGPoint(x: 512, y: 650))
context?.addLine(to: CGPoint(x: 512, y: 750))

// Horizontal line of cross
context?.move(to: CGPoint(x: 462, y: 700))
context?.addLine(to: CGPoint(x: 562, y: 700))
context?.strokePath()

image.unlockFocus()

// Save the image
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    let outputPath = "/Users/shawncarpenter/Desktop/BibleAI/BibleAI/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png"
    try? pngData.write(to: URL(fileURLWithPath: outputPath))
    print("App icon created successfully at: \(outputPath)")
} else {
    print("Failed to create app icon")
}
