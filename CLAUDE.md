# BibleAI project instructions

Read STATUS.md and docs/design.md first. AGENTS.md and CLAUDE.md carry identical instructions.

## Product direction

Native SwiftUI iOS17+ Bible reader. Shawn's2026-10-28 request: transform around Scroll the Bible,
then make the experience natural Apple UX. Use system navigation, tabs, sheets, search, semantic
colors, Dynamic Type and plain lists. Read / Plans / Saved; one verse at a time is the primary job.
No marketing hero above the reader, content cards, copied branding, fake testimonials or invented
trial terms. Native introduction is three pages. Keep free Scripture reading accessible.

## Source and services

Actual bundle ID from the project: com.shawncarpenter.bibleai-companion.
Project BibleAI.xcodeproj; CocoaPods workspace BibleAI.xcworkspace; existing Podfile.lock is canonical.
Use existing RevenueCat integration/config identifiers; never guess product ids, credentials or prices.
Source declarations in old README are historical, not proof of current behavior.

ScriptureFeedModel/ScriptureChapterStore fetch actual KJV chapters from bible-api.com, cache chapters,
and keep a bounded in-memory window. Never invent Scripture or load a complete monolith at launch.
Cache only covers opened chapters; do not claim full offline availability. AIService remains the
existing metered service, requires real configuration and spend authorization for live proof.
Config.swift is a placeholder, not a real credential. Never commit secrets or manufacture AI answers.

## Verification and execution

All Mac-native work uses mac-run and committed docs/os.yaml. check_source is a cheap source check,
not compile proof. prepare_dependencies installs locked CocoaPods. test_reader is the real native
XCTest journey via scripts/simulator-reader-proof.sh. Its name deliberately triggers runner heavy
classification; retain normal load/memory/disk/cooldown and single-Simulator guards.

Shawn approved one20-minute Air test run on2026-10-28, with resource guards. Preserve the exact
approval scope, count and terminal job evidence in STATUS. No automatic retry after infra failure.
Do not edit global runner policy permanently, admit other jobs or touch another session's simulator.
The runtime wrapper cleans its owned simulator. Stop every resource this session starts.

Before completion/release: run shared interaction QA plus actual required native journeys. Inventory
source candidates, actual controls, states, persistence outcomes and raw evidence; unrun is not pass.
Fresh-context runtime/visual refutation follows builder proof. No native/device claim from source.

## Source control and release

Work on codex/scroll-bible until local proof is acceptable. Main starts at872beac; no main push,
store changes, billing changes, deployment or submission is authorized. Existing fastlane paths need
current-source/store audit before reuse. See docs/os.yaml; no release alias is offered yet.
