# BibleAI status — 2026-10-28

## Goal and decisions locked

Transform the app around Scroll the Bible from Shawn's X reference, with Shawn's later direction
to use natural Apple UX. Native Read / Plans / Saved, verse scrolling and native sheets. Short
three-page onboarding replaces the copied funnel; free reading stays directly accessible.
Full product scope and unresolved parity are in docs/design.md. No fake testimonials or trial claims.

## Completed source work (native verification incomplete)

- Read-first SwiftUI shell; stable reading-place persistence, per-chapter validated KJV fetch/cache,
  bounded in-memory chapter window, native passage picker, study sheet and verse save/share/note.
- Native system navigation/list patterns across onboarding, plans, saved notes, settings and Premium.
  Dynamic Type in the new reader; semantic light/dark colors; no decorative content cards.
- Existing RevenueCat products/prices preserved; prices come from offerings; loading/failure states
  are explicit. No subscription purchase or AI request executed. Placeholder AI key never sent.
- Xcode project references all new sources. Missing ignored Config.private.swift replaced by the
  existing tracked placeholder Config.swift source reference; no secret added.
- Real XCTest reader journey and committed mac-run actions prepared. No source changes to other apps.

## Observed evidence

- Initial main and freshly fetched origin/main:872beac405913046496effcf9aeaffdcd76b1184.
- Public bible-api.com John3 KJV read returned HTTP200,36 ordered verses, correct John3:16.
  This proves the provider response, not app runtime behavior.
- Ruby xcodeproj reopened the project; all40app source files and1UI-test source exist.
- Source registration/JSON/whitespace checks pass. Test shell syntax passes.
- Shared interaction gate refused: directory not enrolled,0joined proofs. Candidate discovery is
  saved locally as docs/interaction-coverage.json; outcomes remain UNRUN.
- AppleCharts roadmap stopped: local tsx/node_modules absent. No invented market/review counts.
- Pinned CocoaPods installation passed (5.49.2); the first native run failed before app launch.
  Native compile, screenshot review,
  persistence, all-plan coverage, study provider, subscription/trial/reminder and full offline
  catalog are still unverified. Do not claim the clone complete or release-ready.

## Authorization and next execution

Shawn explicitly approved ONE Air test run, capped at20minutes, with resource guards, in this chat
on2026-10-28. Reuse that authorization; do not ask again. That run was consumed by the failed123.8-second job below. No authorization for additional runs,
paid calls, store edits, uploads or main push. Preserve15GiBminimum, normal load8/memory guards,
one simulator, current queue/failure cooldowns. Native job must be classified heavy by its
simulator-named wrapper. Never globally unlock the Air or admit unrelated work. Restore exact
settings bytes/flags immediately after scoped admission.

1. Commit source so mac-run can read docs/os.yaml. Prepare CocoaPods through canonical
   prepare_dependencies; stop on first infrastructure failure and retain output.
2. Reconcile any generated project changes before proof. Execute exact test_reader once through
   runner when safe. Keep job id and real process until terminal; don't duplicate a waiting job.
3. Inspect actual XCTest failure or captured screens. Independent runtime refutation is required
   after builder checks pass. Full shared enrollment/evidence and remaining parity stay open.

Current feature branch: codex/scroll-bible. No push while local feature proof remains unsuccessful.
The owned simulator was removed and the runner returned idle after the first test.

## Dependency preparation — actual red check

Canonical job BibleAI-prepare_dependencies-20261028-165400-vkfl failed3.1seconds before
installation/build: deployment-mode Podfile checksum mismatch. Both current Podfile and
origin/main:Podfile hash to3e545cdce3f217add1574b56ed82859de6a84b06; the cloned lockfile retained
c42e42e8043278277cfda8cbc157d066c1c663c2. Updated only the stale checksum, keeping RevenueCat
and RevenueCatUI pinned at5.49.2 and all spec checksums unchanged. check_source now rejects
future Podfile/lock checksum drift. Same canonical prepare must run again after this concrete
configuration correction. This was a source/config failure, not a network flake. Native test
has not started; the one-run20-minute authorization is unused.

## First Air run — 17:07 CDT

Dependency preparation `BibleAI-prepare_dependencies-20261028-165804-kmid` passed22.3seconds;
installed manifest exactly matches locked RevenueCat/RevenueCatUI5.49.2.
The ONE approved native job `BibleAI-test_reader-20261028-170359-lflo` ran123.8seconds and
exited65 before app launch. Actual failure: UI-test target PRODUCT_NAME absent in both configs,
producing duplicate output `-Runner.app/PlugIns/.xctest`. Added the canonical `$(TARGET_NAME)`
value and a source guard. This correction is NOT yet verified by Xcode.
Raw evidence: docs/verification/2026-10-28-first-air-run/.
The Air policy was restored byte-for-byte at17:05:36; owned simulator was deleted. No UI screens
or successful behavioral assertions exist. The authorization is consumed; obtain a new explicit
run allowance before executing the corrected test. No release/main push is authorized.
