# Bright Scroll growth loop

Objective: earn repeat sharing that brings new readers who actually read, then share themselves.
Target: activated-referral K30 above1, with retained reading and voluntary sharing. This is an
experiment target, not a result promised by source code. No measured Bright Scroll K exists yet.

## Evidence and limits

The retained AppleCharts November1 sample (`docs/aso/research/bible-study-2026-11-01.json`)
contains24 App Store search results and150 recent reviews across3 apps. None reaches the full
requested3-month window. Search positions1–3: Olive Tree4.84/324,680ratings,
Manna4.91/31,672, Bible Chat4.92/370,389. Seven pricing and two login complaints were detected;
these are a small, selected review sample, not population incidence or causal evidence.

[YouVersion](https://www.youversion.com/news/youversion-shares-its-top-hacks-for-more-consistent-bible-engagement)
uses links to bring friends into Bible plans and offers verse images. Its engagement statement
supports testing shared reading; it supplies no expected uplift for Bright Scroll.
[Duolingo's product account](https://blog.duolingo.com/product-lessons-friend-streak/)
identified the initial invitation as its largest funnel obstacle. Its22% association between
friend streaks and daily lessons is observational and is not our projected conversion rate.

Core three outcomes:
1. **Send someone a verse worth receiving.** Share actual KJV text as a legible image plus an
   exact-content link. No private notes, contact access, automatic sends, guilt prompts, or forced
   sharing. Verify the real image and iOS share sheet; completed activity is not delivery.
2. **Read what a friend sent immediately.** Recipient page shows actual Scripture or plan before
   account/paywall decisions; explicit acceptance opens that same passage/plan. Verify invalid
   links, cold/warm opening, exact text, acceptance, retry and persistence. New installs return to
   the message and reopen the link; custom URL schemes do not provide deferred-install attribution.
3. **Have a natural reason to return and invite.** Offer a plan invitation from its detail and
   completed-day screen. Reuse the existing reading and progress engine. Progress remains personal;
   there is no claimed shared streak, friend acceptance, group discussion or live friend activity.

## Implementation and release order

- Native: Paper/Night verse composer, system share completion events, plan invitations, validated
  link handling, content-first recipient screen, explicit link entry during onboarding and Plans.
- Website: `/share` content preview, actual KJV lookup, metadata, Open in Bright Scroll and App Store
  fallback. The existing website clone failed once on transport; additive patch is prepared from
  GitHub connector source. It is not deployed. Do not release native links while destination is absent.
- Measurement: device-local diagnostics currently preserve a random installation identity,
  activation, first invitation attribution, bounded events and lifetime counters. Nothing is sent.
  A real first-party cross-install collection path, privacy disclosure/choice and cohort collection
  are still required. Existing web analytics can measure explicit button clicks only.
- Publication, new binary, pricing and public release require their own explicit go. The already
  submitted2.0.1/build8 remains unchanged. Historical public price was$6.99; recheck actual price
  and obtain approval for any free-download correction before acquisition rollout.

## Measurement contract

K30 = distinct **new installations that activate a received invitation within30days** divided by
all eligible activated seed installations in that acquisition cohort. Attribute to one first
valid invitation. Count only after the real verse is loaded and accepted, or the invited plan's
first chapter is opened. Deduplicate invitation/installation and activation; exclude returning
readers from new acquisition. Reinstall and cross-device duplicates remain a limitation until a
privacy-respecting identity strategy is proven.

Record separately: eligible readers, share composer opened, share activity completed, share
cancelled/failed, recipient page engagement, app-open click, App Store click, invitation opened,
invitation accepted, first reading, D1/D7 reading return, and recipient's first completed share.
Never equate share-sheet presentation, Copy, bot link previews or App Store clicks with installs.
Do not calculate global K from a selected set of device exports or anonymous web pageviews.

First experiments after the complete path is live:
1. Compare the existing text share against verse artwork + exact passage. Primary outcome:
   new activated recipients per eligible reader; guardrail: reader completion/return.
2. Test the contextual first-day completion invitation against plan-detail invitation alone.
   Measure first-invite rate, activation and D7 return; no repeated modal nagging.
3. Improve the largest observed funnel drop-off. Keep pricing, onboarding and creative changes
   separate enough to attribute results. Report sample counts and uncertainty; don't call a
   small noisy cohort viral or optimize only for share clicks.

Defer rewards/paywall unlocks, public feeds, leaderboards, referral contests and group chat.
They add moderation, billing and social-state work before the acquisition path is proven.
