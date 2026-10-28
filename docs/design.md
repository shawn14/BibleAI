# BibleAI — native reading redesign

## Goal and evidence

Transform BibleAI around the Scroll the Bible experience referenced by Shawn, then make the
interface feel natural on iOS (Shawn, 2026-10-28). The outcome is a Bible people open to read,
return to, and understand; it is not a generic chat app with a Bible tab.

Reference: https://x.com/EndrewBiz/status/2115518969104969800
Retrieved public post and inspected its 26-second video on 2026-10-28. The post is a claim
about another app's business; its revenue is not independently verified and is not our copy.
The demo contains white screens, serif headings, black bottom buttons, feature education,
social proof, premium tools, reminder selection, and trial terms. The recording does not
exercise the main reader. https://scrollthebibleapp.com/ supplies the developer's description
of verse scrolling, saved position, study, search and plans. These are reference evidence,
not proof of our app or of their revenue, downloads or ratings.

AppleCharts roadmap was attempted with its existing CLI for `scroll the bible`, five apps,
two review pages, six months. It stopped because tsx/node_modules are not installed. No package
installation, broad crawl, or review numbers were invented. Market evidence remains incomplete.

## Locked direction

- 2026-10-28: Shawn asked for Apple UX that looks natural. Use NavigationStack, native tabs,
  toolbars, sheets, searchable, SF Symbols, Dynamic Type, system backgrounds and semantic colors.
- Read / Plans / Saved. Reading opens to one verse at a time, restores the last position, and
  continues across chapter boundaries. Real KJV data only, never generated Scripture.
- Three brief native introduction pages replace the reference's ten-screen marketing funnel.
  Start Reading and Skip lead to the reader. Premium is a separate explicit choice.
- Keep BibleAI identity. No copied brand/icon, borrowed testimonials, fabricated review counts,
  unsupported translation options, hardcoded prices or unverified seven-day trial promises.
- No content cards/chips: hierarchy, spacing, and row separators. Bordered/prominent controls
  are allowed. Long Scripture and accessibility text must expand instead of clipping/shrinking.
- Keep existing RevenueCat integration. Match trial messaging to actual offering and eligibility;
  neither this design change nor the reference authorizes billing changes, paid calls or release.

## Core three outcomes

1. Read Scripture instead of a social feed. Evidence: the reference product's verse-by-verse
   description. Build: primary reader, actual chapter source, stable position, bounded chapter
   loading, cache, native passage navigation. Verify: real app swipe/restore/chapter-boundary
   journeys, valid scripture text and translation, offline reopened chapter.
2. Understand and keep a meaningful verse. Evidence: reference study/search tools. Build:
   study sheet, reference search, save, note, share. Verify: correct selected verse in every
   outcome; note Save survives relaunch; Cancel changes nothing; removal is explicit; real
   provider responses and original-language sources must be verified before claims.
3. Return with a clear next reading. Evidence: developer's guided-plan description. Build:
   native plans, exact chapter navigation, honest progress, resume. Verify: all four plans,
   every chapter reference, persistent completion after relaunch, reset/cancel isolation.

## Implementation and remaining work

Current first pass implements reader and navigation source. It uses the established
bible-api.com KJV source through a validated, per-chapter disk cache. A single public John3
read returned36 ordered verses and exact KJV John3:16. This proves the provider response only.
Cache is not a bundled offline Bible: only previously opened chapters can reopen offline.

Still required for the complete transformation: native compile/runtime/visual evidence;
full interaction inventory/enrollment; all reading-plan persistence outcomes; complete offline
catalog and supported translations if retained in the final parity scope; real study provider
configuration and cost authorization; store-backed premium/trial/reminder behavior; independent
runtime refutation. Original-language study currently requests AI commentary, not an interlinear
source: it must never claim scholarly word-level accuracy without a validated data source.

## First verification loop

1. Build and launch the actual source through a committed mac-run action in an allowed native
   execution environment. Never weaken the Air lock or use a second simulator.
2. Exercise onboarding → live verse → swipe → save → note/cancel/save → relaunch → search.
   Retain native screenshots, actual XCTest result/log, app artifact identity and cleanup.
3. Review the screenshots independently and expand coverage to all controls/states. Shared QA
   currently refuses (directory unenrolled,137 source candidates before final first-pass edits).
   No completion or release claim until this and the existing gates pass.
