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

Work on claude/scroll-parity (from codex/scroll-bible) until local proof is acceptable. Main starts at872beac; no main push,
store changes, billing changes, deployment or submission is authorized by this design continuation.
The newer source includes the previously submitted2.0.1 build8; keep its history intact. Publish the
review branch via the committed ask-first publish_review_branch action. Main merge/release requires
Shawn's explicit go. Follow the actual docs/os.yaml actions; do not infer permission from their names.

## November 1 ASO continuation

Shawn requested the complete App Store listing/creative refresh used for Milepost. This authorizes
preparing and updating listing text, screenshots, preview, and header/search assets when editable.
Live read on November 1: 2.0.1 is WAITING_FOR_REVIEW; do not cancel or resubmit that review without
explicit approval after the complete asset package is ready. No new binary or pricing change is
authorized. The one approved Air test already passed within 20 minutes; reuse retained app captures.
Render the three video exports with render_store_videos, which uses the normal runner load guard
and two ffmpeg encoder threads. No Simulator is started by that action.

The first publish_review_branch Mac password prompt expired without running; do not requeue it
until Shawn is available to confirm. ASO sources and the app redesign remain local until then.
