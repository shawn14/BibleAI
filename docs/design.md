# BibleAI — native reading design

## Goal and reference

Make BibleAI a natural iOS reading app: open Scripture, understand a verse, and return to a
clear next reading. Shawn requested Apple UX on October 28 and closer reference parity on
October 29. Reference: https://x.com/EndrewBiz/status/2115518969104969800.
The public 26-second video was inspected frame by frame: white screens, serif headings,
black primary buttons, feature education, social proof, reminders, and store trial terms.
The developer site https://scrollthebibleapp.com/ describes verse scrolling, restored place,
study, search, and plans. Its business claims are not independently verified or our copy.
AppleCharts research stopped at missing CLI dependencies; no review counts were invented.

## Current design

- The Bible / Plans / Saved, using native SwiftUI tabs, sheets, search, SF Symbols, and semantic
  colors. Scripture is the primary reading surface; controls use clear primary/secondary weight.
- One verse at a time, restored reading place, reference search, save, notes, and sharing.
  Actual KJV chapters load from bible-api.com on demand into a bounded cache. Previously opened
  chapters are cached; this is not a complete offline Bible or a multi-translation catalog.
- Four reading plans with saved progress, day completion, and a reading streak. Typography,
  spacing, and separators organize content. Containers are reserved for controls and overlays.
- Onboarding follows the reference funnel, with personal reading preferences and a hold-to-commit
  step. The superseded three-page first pass is not a product lock. Free reading remains
  accessible by closing Premium; store trial pages appear only for eligible products.
- Keep BibleAI branding. Show only real testimonials; the reviews page stays hidden while its
  source is empty. Prices and trial length come from RevenueCat/store products, never invented copy.
- Verse study uses AppleStudy in VerseStudySheet.swift and on-device FoundationModels on eligible
  iOS 26 devices. Legacy AIService is not the current study path. Study is commentary, not a
  validated original-language interlinear source.
- iCloud key-value sync preserves the existing local-first storage design; it introduces no account.

## Verification and limits

Use the committed mac-run test_reader action with cached dependencies and normal resource guards.
The XCTest journey exercises actual onboarding, free-reader access, live Scripture, swipe/save,
note save/cancel, process relaunch, John 3:16 search, study/settings presentation, and day-one
completion/restoration for all four plans. Screenshots are exported from the same xcresult.
See STATUS.md for the latest observed run, source, and changes still awaiting verification.

The existing October 30 iPhone journey passed and the iPad capture run passed. Eligible-device
AI responses, purchase/restore, reminder delivery, and two-device iCloud sync remain unverified.
Sharing, full-chapter navigation, larger accessibility sizes, and complete offline behavior are
not established by that journey. Local design work does not authorize billing or store changes.

Follow rule 54: scoped local tests for edits; affected flows and one independent review for a
feature; full release gates only for an archive/upload/deploy candidate. The older first-pass
full-interaction gate is superseded. Main merge and release require Shawn's explicit approval.
