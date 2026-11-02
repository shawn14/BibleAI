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

Main contains recorded2.0.1/build8 sourcec63c68d, tested native source2841df3 and Bright Scroll
source/assets (PR5,112eb65). Preserve that ancestry. Publish reviewed changes with the committed
ask-first publish_review_branch action and deliberate PR merge; keep main clean/current.
Use docs/os.yaml and Mac authentication. No new binary, pricing change or public manual release
was authorized by the November1 ASO/rebrand task. Additional decisions: one at a time.

## November 1 completed ASO and rebrand

Selected App Store title: Bright Scroll: Bible AI. Short icon/in-app brand: Bright Scroll.
The store title/copy and two branded creative videos are saved and verified. The short native
label and later UX refinements require a later binary; they are not in uploaded build8.
Bundle/product IDs, storage keys, repo and service URLs remain unchanged.

Shawn explicitly approved publication and replacement/resubmission. apply_rebrand200450-bfxv
passed97.1s; actual20:17read confirmed all processing complete. Strict verify_rebrand201746-jhcq
passed5.5s including review notes, all copy, asset identity/checksums and video processing.
Final submit_review201830-yibo passed45.1s at20:24:52CST. Independent actual Apple read20:25:04CST
confirmed WAITING_FOR_REVIEW, exact2.0.1/build8 VALID/MANUAL, nine public fields,18preserved
screenshots, preserved AppPreview and both newvideo placements unchanged. No public release.

The first strict check stopped while Apple reported PROCESSING; current readback is COMPLETE.
Its generic original error cannot establish which field was pending. Never describe it as a
failed asset or repeat an upload merely because processing is pending.

Do not rerun the completed apply_rebrand, apply_aso, resume_aso_videos or submit_review jobs.
Retain one-time receipts in build/aso-rebrand and build/aso-refresh. The narrow rebrand path
is specific to this completed rename; prepare any future update from current Apple state rather
than deleting receipts to bypass it. Runbook: docs/aso/README.md.

Canonical listing copy is docs/aso/en-US. Central submit_review resolves Fastfile-relative
fastlane/apps/bibleai/metadata, observed empty November1. Historical root-level
apps/bibleai/metadata is not its input; never stage stale copy over the verified listing.

ASC review items require ?include=appStoreVersion for a positive exact-version match. Library
video state can pass through COMPLETE before PREPARE_FOR_SUBMISSION; poll through it and allow
placement only in PREPARE_FOR_SUBMISSION/APPROVED. Final verification requires complete posters.

The approved Air native test already passed within20minutes. Reuse retained real-screen captures
for ASO changes. Render actions use normal resource guards and two FFmpeg threads, no Simulator.
