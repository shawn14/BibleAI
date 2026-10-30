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
