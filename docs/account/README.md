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
- Tests and exports cleaned their owned Simulators. No new binary was uploaded or installed on
  Shawn's phone; no customer, purchase, pricing or Apple capability was changed.

## Remaining device prerequisites

Read-only inspect_apple_account job122801-sveg observed Apple at18:34:06UTC:
com.shawncarpenter.bibleai-companion has IN_APP_PURCHASE and ICLOUD, but no APPLE_ID_AUTH.
The source entitlement alone does not enable sign-in on an installed app.

After explicit approval, run the guarded enable_apple_account action. It reads the app target
from Xcode, enables only APPLE_ID_AUTH if missing and checks that existing capabilities remain.
It neither creates a signing profile nor uploads a build. Recreate/verify the signed profile
and built app entitlement using the established native pipeline before device installation.
Successful Apple sign-in, relaunch persistence, Sign Out, profile removal, revoked credentials,
Manage Subscription and paid purchase/restore still require actual signed-device checks.

Use test_account for reader/account/restore-wait checks and test_apple_account for native Apple
prompt cancellation. Never seed a fake signed-in profile as evidence that Apple authentication works.
