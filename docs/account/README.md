# Account candidate — November 3, 2026

The fourth Account tab exposes native Sign in with Apple, Sign Out, Remove Apple Profile,
subscription status, Apple subscription management, restore and purchase history. Native
reading remains available without signing in. Apple identity is local: verified credentials
and profile metadata live in Keychain; there is no app backend account. Existing iCloud
reading and App Store billing remain independent. Sign out does not hide/delete saved
reading, sign out of iCloud, cancel billing, or change RevenueCat customer IDs. The UI says so.

Profile removal checks deletion of both the cached name/email and active app session. It is
not programmatic Apple consent revocation. Apple's permission-management link stays available.
Do not claim that this establishes App Review deletion compliance or authenticated device behavior.

## Proven locally

- Native input8ab4276 compiled; test_apple_account job123550-wofm passed one real UI test,
  zero failures,95.138s. Apple's actual signed-out Simulator prompt appeared; Close dismissed
  it, restored the usable sign-in button and did not invent an authenticated session.
- Earlier test_account job122621-bcgo passed real reader/save/note/relaunch/search/plan flows,
  Account navigation and pending-restore feedback, and returned to the saved note. That run
  was overall failed because the Apple prompt used Close while the test looked for Cancel.
  Only the failing Apple flow was rerun; the focused pass above corrects that selector.
- A real restore remained pending on the unsigned Simulator. After15seconds the UI now explains
  the wait and permits reading, without reporting success or starting duplicate restores.
  This proves waiting-state behavior, not paid restoration.
- Independent feature review inspected actual native captures, raw results and the final source.
  Screens: [Account](preview/account.png), [Subscription](preview/subscription.png),
  [restore waiting](preview/restore-pending.png), [native Apple prompt](preview/apple-prompt.png).
- Tests and exports cleaned their owned Simulators. No store binary was uploaded, and no
  purchase or pricing changed. The approved signed-device installation is described below.

## Signed device candidate

Approved enable_apple_account job133658-rpru passed November3 at19:37:09UTC. Apple readback
has APPLE_ID_AUTH, IN_APP_PURCHASE and ICLOUD. The earlier request with settings[] failed409;
use Fastlane's APPLE_ID_AUTH_APP_CONSENT / PRIMARY_APP_CONSENT configuration. Do not rerun
completed capability writes; the action itself reads before writing.

prepare_account_device134027-eywo passed282.9s from34b416169ed73dbbd85032d2e0fc62e26effa982.
It reused a valid local development identity and the already registered connected phone, created
one narrow development profile, built through the existing CocoaPods workspace/cache, verified
actual signed entitlements plus embedded profile, and installed/launched the app without deleting
its data. It never creates certificates, registers devices, deletes profiles or uploads to Apple.
The signed app carries applesignin=[Default] and the exact app iCloud KVS identifier. Source method
is adapted from Cairn's device signer and fastlane-configs' profile API, with narrower mutations.

Actual iPhone verification November3:

- Shawn completed native Face ID directly on the phone. Builder observed the actual identity
  and Signed in with Apple, then force-closed/reopened Bright Scroll and verified persistence.
- Sign Out confirmation completed; name/email disappeared and the Apple button returned.
  Premium remained active. Subscription detail identifies Test subscription · No real charge,
  with November4 renewal. This is sandbox access and does not establish real payment history.
- Independent reviewer observed signed-out Account with no identity and retained Premium.
  It force-closed only Bright Scroll, then Mirroring failed twice with noWindowsAvailable when
  reopening from Spotlight. The extra signed-out relaunch/reading-position check is unverified;
  do not hide that boundary or retry the same tool failure in a loop.

Paid restoration, native subscription-management completion, profile removal and revoked
credentials remain unproven. No destructive profile or billing changes were tested. The installed
candidate retains2.0.1/build8; this is a local development install, not a new public version.

Use test_account for reader/account/restore-wait checks and test_apple_account for native Apple
prompt cancellation. Never seed a fake signed-in profile as evidence that Apple authentication works.
