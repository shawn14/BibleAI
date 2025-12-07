# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BibleAI is a native iOS application built with SwiftUI, designed as an AI-powered Bible companion for the App Store. The app targets iPhone devices running iOS 17.0 or later.

## Technology Stack

- **Language**: Swift 5.0+
- **UI Framework**: SwiftUI
- **Minimum Deployment**: iOS 17.0
- **IDE**: Xcode 15.0+
- **Bundle Identifier**: com.bibleai.app

## Development Commands

### Opening the Project
```bash
open BibleAI.xcodeproj
```

### Building and Running
- **Run in Simulator/Device**: `Cmd + R` in Xcode
- **Build Only**: `Cmd + B` in Xcode
- **Clean Build Folder**: `Cmd + Shift + K` in Xcode

### Command Line Build
```bash
# Build for simulator
xcodebuild -project BibleAI.xcodeproj -scheme BibleAI -sdk iphonesimulator -configuration Debug build

# Build for device
xcodebuild -project BibleAI.xcodeproj -scheme BibleAI -sdk iphoneos -configuration Release build

# Run tests
xcodebuild test -project BibleAI.xcodeproj -scheme BibleAI -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project Structure

```
BibleAI/
├── BibleAI/                    # Main application target
│   ├── BibleAIApp.swift       # @main app entry point
│   ├── ContentView.swift      # Root SwiftUI view
│   ├── Assets.xcassets/       # Images, colors, and app icon
│   └── Info.plist             # App configuration and permissions
├── BibleAITests/              # Unit tests (to be implemented)
├── BibleAIUITests/            # UI tests (to be implemented)
└── BibleAI.xcodeproj/         # Xcode project configuration
```

## Architecture Guidelines

### SwiftUI Best Practices
- Use SwiftUI's declarative syntax for all UI components
- Leverage `@State`, `@Binding`, `@StateObject`, and `@ObservedObject` appropriately
- Create reusable view components in separate files
- Use `#Preview` macros for SwiftUI previews during development

### Code Organization
- Keep view files focused and under 200 lines when possible
- Separate business logic into ViewModels (MVVM pattern recommended)
- Use extensions to organize code by functionality
- Group related views in folders (e.g., Views/, ViewModels/, Models/, Services/)

### Naming Conventions
- Views: Descriptive names ending in `View` (e.g., `BibleVerseView`)
- ViewModels: Name + `ViewModel` (e.g., `BibleVerseViewModel`)
- Models: Clear, singular nouns (e.g., `Verse`, `Chapter`, `Book`)
- Files: Match the primary type they contain

## App Store Preparation

### Required Assets
- App Icon: 1024x1024px (already configured in Assets.xcassets)
- Launch Screen: Configured via SwiftUI (automatic)
- Screenshots: Prepare for various iPhone sizes

### Before Submission
1. Update version and build numbers in project settings
2. Configure code signing with Apple Developer account
3. Set proper app permissions in Info.plist (if accessing camera, location, etc.)
4. Test on physical devices, not just simulators
5. Archive build: `Product > Archive` in Xcode
6. Submit via App Store Connect

## Important Notes

- Always test on real devices before submitting to App Store
- SwiftUI previews require macOS and may not work in all environments
- Bundle identifier `com.bibleai.app` must be unique in App Store
- iOS 17.0+ requirement means latest SwiftUI features are available
- Keep Info.plist updated with required permissions and configurations

## Future Enhancements

When extending this project, consider:
- Adding unit tests in BibleAITests/
- Implementing UI tests in BibleAIUITests/
- Integrating Swift Package Manager for dependencies
- Setting up CI/CD with Xcode Cloud or GitHub Actions
- Adding localization for multiple languages
