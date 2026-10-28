# BibleAI status — 2026-10-28

## Goal and current design

Transform BibleAI around Shawn's Scroll the Bible reference, with his later instruction to make
it feel natural on iOS. The source uses Read / Plans / Saved, one-verse scrolling, system navigation,
sheets, semantic colors and plain lists. The three-page introduction is a first-pass design choice,
not an explicit user lock on funnel length. Full reference parity is not proven. See docs/design.md.

## Source implemented, runtime unverified

- Native reader with stable reading-place storage, bounded chapter memory, real per-chapter KJV
  download/cache, passage picker, study sheet, verse save/share/note and reading settings.
- Native onboarding, plan list/details, Saved/notes, settings and Premium layouts. RevenueCat
  products/prices stay sourced from the existing integration. No paid call or purchase was tested.
- Placeholder AI configuration is not sent. Missing ignored Config.private.swift was replaced
  by the tracked Config.swift build reference; no secret was introduced.
- All 40 app sources and one UI-test source are registered. Cheap source checks pass; they do
  not establish compilation or behavior.
- Pending XCTest now captures all three introduction pages, reader, Saved, study, settings and
  all four plan details. It also asserts live Scripture, save/note/cancel persistence, reading-place
  restore, reference search, and day-one completion persistence for every plan after relaunch.
  These assertions are UNRUN. Saved rows have stable accessibility identifiers for those checks.

## Observed evidence

GitHub main at clone/fetch: `872beac405913046496effcf9aeaffdcd76b1184`. Work is on
`codex/scroll-bible`, intentionally local pending acceptable feature proof. No main push or release.

Public bible-api.com John 3 KJV returned HTTP 200, 36 ordered verses and the actual John 3:16 text.
That proves the provider response only. The AppleCharts roadmap stopped because local tsx and
node_modules are absent. No review counts were invented. Shared interaction QA refused because
this directory is not enrolled and has zero joined runtime proofs; source candidates are not proof.

Locked dependency preparation first failed at a stale Podfile checksum already present in GitHub.
The checksum-only correction preserved RevenueCat and RevenueCatUI 5.49.2. The same canonical
prepare then passed in 22.3 seconds: `BibleAI-prepare_dependencies-20261028-165804-kmid`.
Installed Pods/Manifest.lock exactly matches Podfile.lock.

The ONE approved Air native run was `BibleAI-test_reader-20261028-170359-lflo` at source
`64bb1cf9672f1f4c9844fa4df44d4c6d6f56a2a6`. It ran 123.8 seconds and exited 65 before app launch:
UI-test PRODUCT_NAME was missing, producing duplicate output `-Runner.app/PlugIns/.xctest`.
Commit c84107e sets `$(TARGET_NAME)` in both test configurations and adds a source guard.
The correction has NOT been verified by Xcode. No screenshots or UI assertions were produced.
Raw log, job result, admission and cleanup receipts: docs/verification/2026-10-28-first-air-run/.

## Authorization, cleanup and next action

Shawn's one-run, 20-minute Air approval is CONSUMED by the failed job above. A single cached retry
capped at 15 minutes was explicitly requested in chat and remains PENDING. The committed runner
timeout is prepared at 15 minutes; that configuration is not authorization. Do not queue native
work until Shawn answers. No paid calls, store edits, uploads, main push or release is authorized.

The exact original Air settings bytes/flags were restored at 17:05:36 CDT. Owned simulator
F1DF7111-32A4-4453-A2F5-4882ADC8ED27 was deleted. No BibleAI job remains queued or running.
The small 8.5 MB build cache is retained only for the pending cached retry. Preserve 15 GiB disk,
normal load 8 / memory guards, a single simulator, existing queue ownership and failure cooldowns.

After explicit retry approval: claim the repo, refresh real resource/queue checks, and run the
existing mac-run test_reader action once. The temporary scoped-admission helper still encodes
20 minutes and the original approval text: update it to the actual new approval before use.
Do not admit unrelated work. Restore exact standing settings immediately after admission.
Inspect actual logs/screens and obtain independent runtime/visual refutation after builder checks.

Remaining completion evidence: native compile and rendered UX; full control/state coverage and
shared QA enrollment; chapter boundaries/offline reopening; plan reset/cancel/navigation outcomes;
real study-provider configuration/authorization; verified premium/trial/reminder parity; dark mode,
Dynamic Type and device coverage. Full offline catalog/translations are also unresolved reference
parity. Do not call the clone complete or release-ready.
