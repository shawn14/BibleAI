# BibleAI project instructions

Read STATUS.md and docs/design.md first. AGENTS.md and CLAUDE.md carry identical instructions.

## Product direction

Native SwiftUI iOS17+ Bible reader. Shawn's2026-10-28 request: transform around Scroll the Bible,
then make the experience natural Apple UX. Use system navigation, tabs, sheets, search, semantic
colors, Dynamic Type and plain lists. Read / Plans / Saved; one verse at a time is the primary job.
2026-10-29: Shawn asked to match the reference app as closely as possible. Onboarding now mirrors
its funnel: hook stat, four feature pages with phone mockups, reviews (only real ones, from
SocialProof; skipped while empty), then paywall pages (hooked, features, trial reminder, trial
timeline, plan picker). Trial length/price come only from the store product and RevenueCat
eligibility. No copied branding, fake testimonials or invented trial terms. Every paywall page has
a close button; free Scripture reading stays accessible.

## Source and services

Actual bundle ID from the project: com.shawncarpenter.bibleai-companion.
Project BibleAI.xcodeproj; CocoaPods workspace BibleAI.xcworkspace; existing Podfile.lock is canonical.
Use existing RevenueCat integration/config identifiers; never guess product ids, credentials or prices.
Source declarations in old README are historical, not proof of current behavior.

ScriptureFeedModel/ScriptureChapterStore fetch actual KJV chapters from bible-api.com, cache chapters,
and keep a bounded in-memory window. Never invent Scripture or load a complete monolith at launch.
Cache only covers opened chapters; do not claim full offline availability. The active verse-study
path is AppleStudy in VerseStudySheet.swift, using on-device FoundationModels on eligible iOS 26
devices. AIService is legacy code, not that active study path. Device study and two-device iCloud
sync still need real-device checks. Never commit secrets or manufacture AI answers.

## Verification and execution

All Mac-native work uses mac-run and committed docs/os.yaml. check_source is a cheap source check,
not compile proof. prepare_dependencies installs locked CocoaPods. test_reader is the real native
XCTest journey via scripts/simulator-reader-proof.sh. Its name deliberately triggers runner heavy
classification; retain normal load/memory/disk/cooldown and single-Simulator guards.

Local builds and scoped tests need no additional approval under Shawn's replacement rule54
(2026-10-29). The October28 one-run approval and old blocked status are historical, not today's
local-test policy. Preserve resource guards and one heavy native job per Mac. Use cached builds;
stop owned simulators and helpers afterward. Do not change global runner settings.

Level1: run the touched-screen journey. Level2: touched flows plus critical journeys and one
feature review. Level3, only before a release: full suite/CI and required device checks. No
per-control manifests or refuter for each edit. Never claim device behavior from simulator output.

Critical journeys (the current ReaderJourneyTests covers the first five, except sharing/full-chapter):
1. Complete onboarding, choose a plan, and dismiss Premium into free Scripture reading.
2. Swipe verses and restore the saved reading place after relaunch.
3. Find an exact passage and open its full chapter.
4. Save a verse, edit/cancel a note, restore it after relaunch, and share.
5. Start/complete each of the four reading plans and restore progress after relaunch.
6. Generate verse study on an eligible device and enforce free/Premium limits.
7. Purchase/restore through StoreKit and verify trial-reminder/daily-reminder delivery.
8. Sync saved content and progress between two devices on the same iCloud account.
Journeys6–8 and the stated gaps remain unverified; do not turn those into passed claims.

## Source control and release

GitHub main includes the original main, recorded 2.0.1/build-8 source c63c68d, tested native
source 2841df3 and November 1 ASO/rename changes (PRs 1–3, main4de94c2). Preserve this ancestry.
Publish deliberate review-branch commits via the committed ask-first publish_review_branch
then merge the reviewed PR into main; keep main fast-forward current. Follow docs/os.yaml.

## November 1 ASO continuation

Shawn explicitly approved GitHub main publication and replacement/resubmission of existing
2.0.1/build 8. That approval persists. No new binary, public manual release, or pricing change.
Additional decisions: one at a time. Use mac-run authentication; never bypass it.

Shawn requires both Scroll and Bible in the name. Store title: Scroll Bible: Daily Verses.
Short icon/in-app display name: Scroll Bible. Bundle/product IDs, storage keys, repo and service
URLs stay unchanged. Listing/media rename is verified in Apple; the short native display name
requires a later binary and is not in uploaded build 8.

The complete ASO package is uploaded and verified: nine public fields, review notes,
18 screenshots and three videos; all processing complete, creative placements ACTIVE.
Strict verify_aso passed at18:09CST. Independent actual read at18:29:47CST confirmed unchanged
assets, copy and build8 VALID/MANUAL. Original review was canceled with approval.

The submission job BibleAI-submit_review-20261101-180943-mqxd EXPIRED at18:29:37CST without
executing (allowed=false, no start time). Apple remains DEVELOPER_REJECTED, no active review.
Confirm Shawn is at the Mac before queuing submit_review again; do not ask for repeat product
approval. After execution, verify actual review state/build/copy/assets. Do not rerun apply_aso
or resume_aso_videos: their writes are complete and one-time receipts must be preserved.

Runbook: docs/aso/README.md. inspect_aso reads exact version/build/assets; verify_aso requires
exact copy, ordered screenshot checksums, complete preview/video processing and ACTIVE
creative placements. docs/aso/en-US is canonical listing copy. Central submit_review uses
Fastfile-relative fastlane/apps/bibleai/metadata, observed empty November1. Historical
root-level apps/bibleai/metadata is not its input; never stage it over the new copy.

ASC review-item reads require ?include=appStoreVersion. The actual default response omitted
version relationships; the exact-version cancellation guard correctly refused before writes.
Keep the positive version-id match; never fall back to one active submission.

Library video state can transition COMPLETE → PREPARE_FOR_SUBMISSION. Poll through COMPLETE;
only PREPARE_FOR_SUBMISSION/APPROVED permit placement. The scoped November1 recovery reused
recorded assets, verified package hash/copy/checksums/placements, and completed without repeating
metadata/screenshots/preview writes. A processing state is not a failed asset or reason to reupload.

The approved Air test already passed within20minutes. Reuse retained real-screen captures for
ASO work. Render actions use normal load/disk/memory guards and two FFmpeg threads, no Simulator.
