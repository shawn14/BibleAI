# BibleAI status — 2026-10-28

## Goal and decisions locked

Transform the app around Scroll the Bible from Shawn's X reference, with Shawn's later direction
to use natural Apple UX. Native Read / Plans / Saved, verse scrolling and native sheets. Short
three-page onboarding replaces the copied funnel; free reading stays directly accessible.
Full product scope and unresolved parity are in docs/design.md. No fake testimonials or trial claims.

## Completed source work (not compiled or runtime verified)

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
- CocoaPods dependencies are absent from this new checkout. Native compile, screenshot review,
  persistence, all-plan coverage, study provider, subscription/trial/reminder and full offline
  catalog are still unverified. Do not claim the clone complete or release-ready.

## Authorization and next execution

Shawn explicitly approved ONE Air test run, capped at20minutes, with resource guards, in this chat
on2026-10-28. Reuse that authorization; do not ask again. No authorization for additional runs,
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

Current feature branch: codex/scroll-bible. No push while local feature proof remains unrun;
no native server/simulator started by this session at this checkpoint.
