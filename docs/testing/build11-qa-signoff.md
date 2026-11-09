# BibleAI 2.0.3 (11) release QA

CI run 42656604910
Native input 497fae42e26b829a50e6095b34e2465febb9db676ca9db415be63b934e36a415
Source d7a7120b49250ed6709d8551188b1f8884b2b55c

An independent release reviewer downloaded all three XCTest artifact bundles from
[GitHub Actions](https://github.com/shawn14/BibleAI/actions/runs/42656604910).
All three iPhone 17 Pro / iOS 26.2 simulator journeys passed, with zero failures
and zero skips. Ten reviewed captures spanned the first-use flow, Apple sheet,
KJV reader, sharing, received invitation, purchase history, one-day streak and
restored Gospel Tour progress (1 of 8). The reviewer compared all 18 App Store
screenshots and the English copy with the app and found no candidate-specific
blocker. The native difference from 2.0.2 (10) is the purchase-history wording
and the version/build.

These runs establish the reading, progress and visible account claims. Real
billing, paid restore, second-device iCloud sync and on-device AI generation were
outside these tests. The release lane separately checks the signed IPA.
