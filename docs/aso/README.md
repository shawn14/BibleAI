# Scroll Bible App Store refresh

November 1 package for existing iOS **2.0.1/build 8** is uploaded and verified in App Store
Connect. Title: **Scroll Bible: Daily Verses**. All nine public metadata fields, review notes,
18 screenshots, App Preview, and header/search videos match the approved package. All processing
is complete and creative placements are ACTIVE. Strict verification passed at 18:09 CST;
independent readback at 18:29:47 CST preserved the same assets and build 8 VALID/MANUAL.

**Resubmission remains outstanding.** The 18:09 submission job's Mac password prompt expired
at 18:29:37 CST without executing. Apple remains DEVELOPER_REJECTED with no active review.
Shawn has already approved publication and same-build resubmission. Confirm Mac availability
before queuing `submit_review` once; do not rerun `apply_aso` or `resume_aso_videos`.

The short icon/in-app label **Scroll Bible**, plus later native onboarding/completion changes,
are saved in source and require the next binary. This package keeps existing build 8 and manual
release; the public version 1.0 remains unchanged. No new binary or pricing change was made.

| Deliverable | Location | Specification |
|---|---|---|
| Title, subtitle, keywords, description, promotional text, release and review notes | `en-US/` | 30/30/100/170/4000 character limits |
| Six large iPhone screenshots | `screenshots-6.9/` | 1320×2868, RGB |
| Six medium iPhone screenshots | `screenshots-6.3/` | 1206×2622, RGB |
| Six iPad screenshots | `screenshots-ipad-13/` | 2064×2752, RGB |
| App Preview | `preview/BibleAI-preview-6.9.mp4` | 886×1920, 30 fps, 21 seconds |
| Product-page header | `header-video/product-page-header.mp4` | 3840×1646, 30 fps, 10.5-second loop |
| Search-results creative | `header-video/search-results.mp4` | 3840×2560, 30 fps, 10.5-second loop |
| Encoded 5-second posters | `header-video/*-poster.png` | RGB PNG, same canvas size |

[Preview all 18 screenshots](preview-board.png). Positioning, source research, and limitations
are in [refresh-plan.md](refresh-plan.md). These assets use actual retained app pixels, with
provenance in [creative-src/captures/README.md](creative-src/captures/README.md).

## Reproduce and check

`python3 docs/aso/creative-src/render_refresh.py` creates the screenshots, video scenes and
captions from retained inputs. Then `mac-run BibleAI render_store_videos` runs serial, two-thread
FFmpeg encoding under the existing load/disk/memory guard. It never boots a Simulator.
`check_aso` checks every screenshot, copy limit, and actual encoded video dimensions, codec,
frame rate and duration. Older screenshots.py/header_video.py are historical generators whose
raw export/font directories were cleaned; render_refresh.py is the current reproducible path.

Apple specifications: [screenshots](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications),
[creative assets](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications/),
[product page](https://developer.apple.com/app-store/product-page/).

## Canonical workflow and recovery

Use committed `docs/os.yaml` actions through mac-run. These actions reuse the BibleAI ASC client
and the inspect/apply/verify pattern already used for Milepost.

1. `inspect_aso` reads Apple; no changes. Stop if the intended version/build differs.
2. Cancellation/resubmission requires explicit approval. November 1 approval is recorded and
   cancellation has completed; do not repeat it for this package.
3. `apply_aso` requires the inspected inventory to match, exact 2.0.1/build 8, MANUAL release,
   and an editable version/app-info state. It uploads all nine metadata fields, review notes,
   18 screenshots, the App Preview and two creative placements. It saves the prior state and
   refuses a second apply after a partial attempt. It cannot cancel review, submit, change
   pricing, select another build, or edit live app-info metadata.
4. `verify_aso` reads Apple back. All copy must match; screenshot order/checksums and preview
   checksum must match and processing must be COMPLETE; creative placements must be ACTIVE
   with the uploaded reference/file size and complete posters. Pending processing is unverified.
5. Resubmission is a separate approved operation through central Fastlane's existing
   `submit_review app:bibleai version:2.0.1 build:8` lane, followed by exact Apple readback.
   Do not upload another binary merely to update the listing.

The canonical metadata for this BibleAI-specific flow is `docs/aso/en-US`. Central Fastlane's
BibleAI listing lane already reads this directory. Its general submit lane resolves the separate
`fastlane/apps/bibleai/metadata` directory, observed empty on November 1; the old root-level
`apps/bibleai/metadata` contains historical text and is not that lane's input. Do not copy stale
central text over this package. If central staging changes, review it before submitting.

The November 1 public lookup still showed the old 1.0 listing at $6.99. This refresh makes no
free-download claim and changes no pricing. A free-download correction is a separate decision.


November 1 recovery: `apply_aso` stopped after saving metadata/screenshots/preview because a
library video temporarily reported COMPLETE before PREPARE_FOR_SUBMISSION. The guarded
`resume_aso_videos` action reused that header and uploaded/placed only the absent search video.
It passed at 18:00:38 CST. Preserve the recorded package hash and one-time receipts; both write
stages are finished. `verify_aso` subsequently required and observed full processing/checksums.
For future video uploads, poll through COMPLETE and place only PREPARE_FOR_SUBMISSION/APPROVED.
