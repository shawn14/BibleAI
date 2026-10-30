# BibleAI 2.0 App Store creative

Everything here is built from real 2.0 simulator captures (no redrawn UI) and pushed to App Store
Connect by the `store_assets` mac-run action (`scripts/asc/store-assets.mjs`).

| Asset | File | Spec | Built by |
|---|---|---|---|
| Name, subtitle, keywords, promo, description, What's New, review notes | `en-US/*.txt` | ASC limits (30/30/100/170/4000) | hand-written; pushed by `listing_push` and fastlane `submit_review` |
| iPhone 6.9" screenshots (6) | `screenshots-6.9/` | 1320x2868 | `creative-src/screenshots.py iphone` |
| iPad 13" screenshots | `screenshots-ipad-13/` | 2064x2752 | `creative-src/screenshots.py ipad` from `ipad_shots` captures |
| App preview (iPhone 6.9") | `preview/BibleAI-preview-6.9.mp4` | 886x1920, 30 fps, 29.5 s | `preview_video` action records `testPreviewRecording`, then cut with ffmpeg |
| Product page header video (iOS 27) | `header-video/product-page-header.mp4` | 3840x1646, 10 s loop, silent | `creative-src/header_video.py` (StockAlarm method) |
| Search results video (iOS 27) | `header-video/search-results.mp4` | 3840x2560, 10 s loop, silent | `creative-src/header_video.py --search` |

Apple picks the 5 s frame as the header/search poster; the loop puts John 3:16 there. The 6.5" iPhone
set is removed so Apple scales the 6.9" set down. Captures: release suite `build/proof/20261030T140422Z`.
