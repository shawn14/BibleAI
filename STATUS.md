# Current checkpoint — 2026-11-01

- Apple now holds Scroll Bible: Daily Verses in pending2.0.1/build8; original review canceled
  successfully at17:12CST. Copy,18screenshots and preview uploaded. Apply stopped on the header
  intermediate COMPLETE state before replacing either old creative placement. Readback23:24Z
  confirms header PREPARE_FOR_SUBMISSION and pending title; preview still processing.
  At23:24Z,16of18screenshots COMPLETE; the final large-iPhone and iPad images remain
  UPLOAD_COMPLETE. New resume_aso_videos finishes only recorded header/search placements after
  verifying completed copy/assets; never rerun apply_aso. Current new helper is not yet executed.

- Renamed source/ASO media merged through PR1 at GitHub main5086fde. Both recorded build8
  sourcec63c68d and tested native source2841df3 are ancestors. Cancellation then stopped before
  any Apple write: the default review-item response omitted appStoreVersion relationships.
  Added the documented include option; read-only inspect_aso passed at23:09:39Z and returned
  the exact2.0.1 version id for the sole review item. Existing review remains intact.

- Shawn confirmed publication/resubmission approval in this chat and requested Scroll and Bible
  in the name. Prepared title: Scroll Bible: Daily Verses. Source icon/in-app label: Scroll Bible.
  The latter needs a later binary; same-build8 ASO approval does not upload a new binary.
  Header/search videos now show SCROLL BIBLE. Guarded render_store_brand passed at16:48CST
  in95.9sec, with both encoded posters visually checked. Full ASO format/copy check passed.
  Reviewed screenshots and21-second interaction preview contain no old brand and are unchanged.

- Earlier availability hold (superseded): Shawn was away from the MacBook Air.
  Publication/resubmission approval remains valid. Do not queue another prompt until he is at
  the Mac. Job BibleAI-publish_review_branch-20261101-140622-wpee was safely withdrawn before
  execution at his request: runner terminal DENIED at 14:13:16 CST, approval.allowed=false,
  no started_at and no command log. This was withdrawn authentication, not revoked task approval.
  Shawn subsequently said "I’m at the Air—reopen it" in Milepost chat01a182fa at16:37CST;
  its upload job then authenticated successfully and passed at16:46CST. The approved BibleAI
  publication can resume through the existing Mac prompt. No BibleAI push or Apple write yet.

- Shawn approved publishing the reviewed changes and replacing/resubmitting the pending Apple
  listing by voice in the Pose chat (01a17d7a), explicitly: "I approve the Bible one."
  Fresh 20:05Z Apple preflight still shows 2.0.1/build 8 VALID, WAITING_FOR_REVIEW, MANUAL.
  Scope: GitHub publication and ASO replacement/resubmission of the same build; no new binary
  or pricing change. Additional decisions must be presented one at a time.


- Complete ASO draft is ready and independently reviewed: English title/subtitle/keywords,
  promotional text/description/release and review notes, 18 actual-screen screenshots (6 large
  iPhone, 6 medium iPhone, 6 iPad), a 21-second App Preview, and two 10.5-second header/search loops.
  Open docs/aso/README.md or docs/aso/preview-board.png. No Apple writes made.
- Actual formats/copy limits passed in guarded render_store_videos (87.1 sec) and the scoped
  preview-ending correction render_store_preview (13.5 sec). Independent review inspected all
  screenshots and encoded videos, captions, posters, loop seams and final preview frame.
- Apple inventory read at 18:32Z: 2.0.1/build 8 VALID, WAITING_FOR_REVIEW, MANUAL release,
  en-US only. Existing screenshot sets: 6 large iPhone + 6 iPad; the new medium set is prepared.
  Public 1.0 remains live. inspect_aso/apply_aso/verify_aso reuse the existing ASC path with
  exact version/build, inspected-state and full processing/readback checks. Upload path is unrun.
- Publication/resubmission approval requested after the complete package review. Do not cancel
  review, merge main, submit another build or change pricing without the relevant explicit go.
- Branch publication job BibleAI-publish_review_branch-20261101-115701-lbto expired at its Mac
  password prompt; nothing was pushed. Requeue only once Shawn is available to confirm.
- AppleCharts research: 150 sampled reviews across three apps, incomplete three-month coverage;
  retained under docs/aso/research. Support/marketing/privacy/terms URLs all returned HTTP 200.
- Removed this session's research dependency install and temporary frame/caption inputs. Captures,
  source recording and final assets are retained in docs/aso so they can be reproduced cheaply.

- Native Apple-style redesign is locally verified on iPhone 16: clearer reading hierarchy,
  system navigation/sheets, and unboxed onboarding summary and reading completion.
- One approved Air run finished in 664.3 seconds (11m04s), within the 20-minute cap:
  `BibleAI-test_reader-20261101-114317-ygdf`, exit 0. Reader journey passed in 201.036 seconds,
  zero failures; the separate recording-only test was intentionally skipped. Owned simulator deleted.
- Verified onboarding/free reading, actual KJV swipe/search, save/note/cancel/relaunch, and day-one
  completion/restoration for all four plans. Independent feature review completed. Updated screens:
  [reader](docs/design-preview/reader.png), [onboarding](docs/design-preview/onboarding-plan.png),
  [completion](docs/design-preview/reading-complete.png).
- Native source tested: `2841df3`; later changes include ASO assets and the uncompiled display-name/text rename.
  Existing October 30 iPad capture passed before this typography pass; no second native run started.
- Preserved the newer `claude/scroll-parity` history, including the recorded 2.0.1/build 8 submission.
  GitHub main remains `872beac405913046496effcf9aeaffdcd76b1184`; branch publication is next through
  `publish_review_branch`. The later explicit ASO approval above authorizes main publication.
- Device AI, purchase/restore, reminder delivery, and two-device iCloud remain unverified.
  Public Apple lookup on November 1 returned version 1.0 at $6.99; no store/pricing changes made.
- Replacement rule 54 controls test scope; older approval holds and full-gate language below are
  historical. This session honored Shawn's additional one-run, 20-minute Air limit.

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
