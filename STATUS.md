# Current checkpoint — Bright Scroll preparation, 2026-11-01

- Shawn selected **Bright Scroll: Bible AI** after checking overlap with Scroll The Bible and
  BibleScroll. Short native label: **Bright Scroll**. Source/copy and two branded creative videos
  are prepared locally; this new name is not yet saved in Apple.
- Guarded render_store_brand `BibleAI-render_store_brand-20261101-193223-pdgv` passed in84.0s.
  Both actual encoded posters show BRIGHT SCROLL; all format/copy limits pass. Title23characters.
  The18screenshots and21-second App Preview are preserved. No native build/Simulator started;
  icon/in-app label changes still require a later binary.
- Existing Apple submission remains **Scroll Bible: Daily Verses**,2.0.1/build8, WAITING_FOR_REVIEW,
  MANUAL release, independently verified19:22:32CST. Historical checkpoint below records it.
- Narrow `plan_rebrand`/`apply_rebrand`/`verify_rebrand` actions are prepared. Plan reads actual Apple
  state and requires only name/description-brand/review-note-brand changes plus two creatives.
  Apply is ask-first, cancels only the planned exact review, preserves existing18screenshots/preview,
  and refuses a second application. Existing submit_review remains separate.
- Actual read-only plan `BibleAI-plan_rebrand-20261101-193632-nvcb` passed12.5s at19:43:58CST,
  pinning review684b6508-7b6f-410f-9721-80e04cbdc2cd and package
  `96425a30d3c5fe80766fbb6f1eb6a47eac37eb39843899507135b2187533c717`. Local/source/format checks
  and independent visual/source review passed. Final approval to publish this rebrand and replace
  the newly submitted review was requested; no rebrand Apple writes have occurred.
- Published GitHub main before this preparation: `d805ba17cba9bb7304d13702876418d25feb8dbf`
  (PR4), including recorded build8 sourcec63c68d and tested native source2841df3.

---

# Submitted package checkpoint — 2026-11-01, 19:22 CST

- App Store Connect now holds **Scroll Bible: Daily Verses** for 2.0.1/build 8. All nine public
  metadata fields, review notes, 18 screenshots and three videos match the approved package.
  All screenshot/preview processing is COMPLETE; header/search placements are ACTIVE.
- Strict `verify_aso` passed (`BibleAI-verify_aso-20261101-180911-fabw`). Independent Apple
  readback at 18:29:47 CST confirmed exact assets/copy and unchanged build 8 VALID/MANUAL.
  Package hash: `8fb4dbbaf295f8297117662c112660c250335bffb11cd885a66a7ad4028df480`.
- **Submitted and WAITING_FOR_REVIEW.** Shawn confirmed Mac availability; authenticated job
  `BibleAI-submit_review-20261101-191639-vjky` passed in 46.6 seconds at 19:17:50 CST.
  Independent readback `BibleAI-inspect_aso-20261101-191808-hatx` at 19:22:32 CST confirmed
  review submission at 19:17:47 CST, exact 2.0.1/build 8 VALID/MANUAL and all nine public fields,
  screenshots, preview and creative placements unchanged. Screenshots/preview COMPLETE;
  creative placements ACTIVE, library videos WAITING_FOR_REVIEW. No mismatches found.
  Review notes retain the earlier strict verification; the inspector does not fetch them.
- **Naming decision pending.** Shawn noted the existing Scroll The Bible app. Apple also has
  BibleScroll: Christian Focus (6755406222). He proposed “Bible Scroll AI”; an exact web search
  found no exact title match, which does not establish Apple availability. “Bright Scroll: Bible AI”
  was offered as a more distinct alternative. Await his selection before preparing another rename;
  no second cancellation, rename or resubmission has occurred. Manual release remains enabled.
- Source and assets are published through PRs 1–3 at GitHub main
  `4de94c244e567e8f844a142780864853435f2fb4`. Recorded build-8 source `c63c68d` and tested
  native source `2841df3` are ancestors. Final checkpoint documentation follows through the
  existing guarded review-branch publication and merge path.
- Short icon/in-app label **Scroll Bible** is in source and requires the next binary. The later
  native onboarding/completion refinements also are not in uploaded build 8. This ASO-only
  operation does not claim to ship those changes. Public version 1.0 remains unchanged.

## Completed operations and safe continuation

- Original review cancellation passed at 17:12 CST (`BibleAI-swap_to_201-20261101-171114-dsyo`).
  The default Apple review-item response omitted the version relationship; explicit
  `?include=appStoreVersion` fixed the exact-version read before cancellation. Preserve that guard.
- `apply_aso` saved metadata/screenshots/preview but stopped on an intermediate video COMPLETE
  state. Scoped `resume_aso_videos` passed at 18:00:38 CST, reusing the uploaded header and adding
  only the missing search video/placements. All processing later completed without re-upload.
  **Do not rerun apply_aso or resume_aso_videos:** both have completed their writes and preserve
  one-time receipts in ignored `build/aso-refresh/`. Submission has now completed.
- Post-submit `inspect_aso` confirmed actual review state/build/copy/assets; retain manual release.
  Central Fastlane's actual submit metadata directory
  `fastlane/apps/bibleai/metadata` was empty, so it cannot overwrite the prepared copy with the
  historical root-level metadata. See [ASO runbook](docs/aso/README.md).

## Native proof and limits

- The one approved Air run passed in 664.3 seconds, within the 20-minute cap:
  `BibleAI-test_reader-20261101-114317-ygdf`. Reader journey: 201.036 seconds, zero failures;
  recording-only test intentionally skipped. Independent feature review completed.
- Proven on iPhone Simulator: onboarding/free reading, real KJV swipe/search, saved verse and
  note/cancel/relaunch persistence, reading-place restoration, all four plans' day-one completion
  and restoration. Screens: [reader](docs/design-preview/reader.png),
  [onboarding](docs/design-preview/onboarding-plan.png), [completion](docs/design-preview/reading-complete.png).
- Native source tested: `2841df3`; later display-name/text rename has source checks only.
  Device study, purchase/restore, notification delivery and two-device iCloud remain unverified.
  No additional Simulator/build was started; owned Simulator and temporary render inputs removed.
- AppleCharts research retained 150 sampled reviews from three apps, incomplete three-month
  coverage. Actual-screen assets/source recordings are retained for cheap reproduction.
- November 1 public lookup showed version 1.0 at $6.99. Pricing was unchanged; no free-download
  claim was made. Replacement rule 54 controls future test scope; older holds below are historical.

---

# BibleAI status — 2026-10-30 (late afternoon)

## 2.0.1 (8) submitted for App Review 15:18 CDT (replaced 2.0 (6) at Shawn's request) — iCloud sync (Shawn: "yes" to iCloud instead of accounts)
- No accounts. CloudSync (NSUbiquitousKeyValueStore) syncs saved verses + notes, plan progress,
  streak, reading place and onboarding-done via the user's own iCloud. Union merges; deletions as
  tombstones (CloudSyncMerge). sync_logic_test: 10/10 pass. test_reader passed with the code
  (BibleAI-test_reader-20261030-194702-dpti).
- App ID now has ICLOUD capability (icloud_capability action). Release signing is manual with the
  App Store profile (fastlane bibleai manual_release_signing), since the team wildcard profile can't
  carry the kvstore entitlement. IPA verified: entitlement BYRK5RUS4U.com.shawncarpenter.bibleai-companion.
- Not yet proven on devices: two real iPhones/iPad signed into one iCloud account.
- 2.0 (6) submission canceled; version renamed 2.0.1, build 8 attached, WAITING_FOR_REVIEW with all
  screenshots, preview, header and search videos.

# BibleAI status — 2026-10-30 (afternoon)

## Submitted for App Review 2026-10-30 14:29 CDT (2.0 build 6)
- Build 2.0 (6) uploaded 13:15 CDT, VALID, compliance set, attached to version 2.0; TestFlight group Beta.
  Contents: streak + "Well done" day-complete, daily reminder, 7-day trial checkout + reminder,
  personalized onboarding with hold-to-commit, new logo (open Bible + cross), iPad layout fixes.
- Level 3 suite passed on this source: BibleAI-test_reader-20261030-175938-zjrm (iPhone) and
  BibleAI-ipad_shots-20261030-172802-coxd (iPad 13").
- ASC 2.0 en-US: 6x iPhone 6.9", 6x iPad 13" (docs/aso/screenshots-*), 30 s preview, header video
  (3840x1646) and search-results video (3840x2560) placed DEFAULT_PROFILE, copyright, 6.5" set removed.
  All assets COMPLETE (asset_state). Age rating: socialMedia=false (Apple's Sept 2026 required question).
- Website main 83b5ae5 live: new mark, Habit/streak section, 7-day trial CTA.
- New runner actions: age_rating, asset_state, fix_stuck_shots (Apple can leave a screenshot at
  UPLOAD_COMPLETE; re-encode + re-upload clears it).

## Next
- Watch App Review; ask_first restored to [testflight, listing_push].
- Merge claude/scroll-parity into main.

# BibleAI status — 2026-10-29 (evening)

## Shipped
- 2.0 (4) uploaded to TestFlight 21:03 CDT; Shawn added to internal group Beta.
- App Store version 2.0 (PREPARE_FOR_SUBMISSION): name "BibleAI: Daily Bible Verses", subtitle,
  description, keywords, What's New, review notes, 6x 6.9" screenshots, 30 s preview (docs/aso/).
- Full reader journey passed on the Air (job BibleAI-test_reader-20261030-015146-hisx) on this source.
- Website bibleaicompanion.com redesigned and live (repo shawn14/v0-bible-ai-companion-website).
- Verse study runs on Apple Intelligence (FoundationModels), 5 free/day, Premium unlimited.

## Next
- Shawn tries 2.0 (4) on his iPhone, then submit for review (fastlane submit_review / deliver).
- Optional: 7-day free trial intro offer on the yearly product (trial pages turn on automatically).
- Real App Store reviews into SocialProof to show the reviews page.

# BibleAI status — 2026-10-29

## Scroll The Bible parity pass (branch claude/scroll-parity)

Shawn: "Make as close as you can to the app I shared." Reference video stepped frame by frame:
hook stat → "scrolling fed your soul" → plans → study → search → reviews → "Get Addicted…"
→ premium checklist → "We'll remind you" (2 or 3 days) → trial timeline → plan picker.

Built (source only, not yet compiled):
- OnboardingView.swift: that 11-step flow in the reference look (white, serif, black capsule
  Continue, phone mockups with real KJV text). Reviews step skipped until real reviews are added
  to SocialProof. Reminder/timeline steps appear only when RevenueCat says the annual product has
  an eligible free trial.
- PaywallView.swift: shared style, footer (Terms | Privacy | Restore), trial math from the store
  product, local trial-ending reminder scheduled after a trial purchase, plan picker with
  "Try for $0.00" when a trial applies. Settings/Chat paywall uses the same screen.
- Reader: no nav bar; KJV pill + passage button + search + options on top; TikTok-style right
  rail (heart save, study, note, share). Tabs: The Bible / Plans / Saved.
- Study: added "Explain It Simply".
- UI test walks the variable-length onboarding to the plan picker and closes it.

Needs Shawn: real App Store reviews/rating for SocialProof; a 7-day free trial intro offer on
the yearly product in App Store Connect (otherwise trial steps hide themselves).

## Previous status (2026-10-28)


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
this directory is not enrolled and has zero joined runtime proofs. The refreshed inventory has
134 unverified source candidates; candidates are not proof.

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
