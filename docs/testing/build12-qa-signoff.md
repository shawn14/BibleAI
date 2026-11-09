# BibleAI 2.0.4 (12) release QA

CI run 42682033210
Native input 8c66b3c99ceaff814ee2052e02aa32b6aee15f33047b0f217b86ae6f8eeeb14b
Source b5b7cf252bca03dd2eac9533183f84d1843b2046

An independent reviewer downloaded the four passing XCTest exports, checked their
digests, and inspected all 64 screen captures. Each suite recorded one pass, zero
failures and zero skips. The first reader job timed out at simulator launch. Its
single retry passed on the same source. [GitHub Actions](https://github.com/shawn14/BibleAI/actions/runs/42682033210/attempts/2).

On iPhone SE (3rd generation), iOS 18.6, the reader reopened at John 3:16 in
the World English Bible. Gospel Tour resumed its chapter, advanced to Day 2 on
explicit completion, and reopened a saved Matthew study with its WEB quotation.
On iPhone 17 Pro, iOS 26.2, the reviewer saw version 2.0.4, the saved note,
John 3:16 in KJV, restored progress in all four plans, the native Apple sign-in
sheet, and the system sharing and received invitation screens.

The reviewer found no candidate-specific simulator blocker. Physical Apple
Intelligence, two-device iCloud, paid purchase/restore and reminder delivery
remain unverified. The signed IPA and Apple's processing state are checked by
the release lane and its subsequent readback.
