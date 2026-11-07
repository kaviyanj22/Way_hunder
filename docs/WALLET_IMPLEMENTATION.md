# Wallet implementation

Approved reference: `docs/wallet/wallet_eight_screen_reference.png`, confirmed by the owner on 6 November 2026. Workflow: `docs/flows/06_wallet_vouchers.png`.

## Scope and inventory

Reuse the existing WalletState, WalletViewModel, MockWalletRepository and local preference storage. Game/Hunter reward sinks already credit this provider and will remain unchanged. Profile and Game already link to `/wallet`; replace that route's preview with the real overview.

| Reference | Screen | Route |
|---|---|---|
| W-01 | My Wallet Overview | `/wallet` |
| W-02 | Redeem Rewards | `/wallet/choose` |
| W-03 | Confirm Redemption | `/wallet/confirm?offer=&intent=` |
| W-04 | Request Submitted | `/wallet/pending?id=` |
| W-05 | Voucher Approved | `/wallet/approved?id=` |
| W-06 | My Vouchers | `/wallet/vouchers` |
| W-07 | Voucher Details | `/wallet/voucher?id=` |
| W-08 | Transaction History | `/wallet/history` |
| W-LO / W-RJ | Insufficient RC / rejected request | `/wallet/insufficient?offer=` / `/wallet/rejected?id=` |
| W-EX | Used / expired voucher | `/wallet/voucher?id=` |
| Supporting | Wallet Rules / isolated debug tools | `/wallet/rules` / `/wallet/demo` |

## Milestones

1. Strengthen the existing ledger: initialization, idempotent requests/decisions/reward credits, reservations, finite demo inventory assignments, one-use vouchers, account-scoped persistence and transaction links. Add state/repository tests.
2. Implement the eight reference screens as real glass UI with fixed headers/footers and internal voucher/history lists. Connect GoRouter, QR/copy, rules and error states. Put approval/rejection and merchant simulation in a clearly labeled debug-only area.
3. Exercise the full user journey, Profile/Game entry, shared reward sinks, error states and persistence. Run analysis and the complete test suite, inspect rendered screens and report exact results.

All fixture datasets remain in `lib/core/mock/mock_data.dart`. No backend, commercial voucher issuance, real admin or merchant connection is added. Every voucher and QR must be clearly marked DEMO / NOT REDEEMABLE.

## Completed behavior

All eight reference screens are now real interactive widgets, using the original scenic image, transparent navy glass, cyan controls, purple HP, gold RC and green success states. Header, Home/Wallet footer and demo notice remain fixed. Catalog, voucher and history lists scroll inside their allocated area. Fixed content fits phone viewports down to 320 × 568 in widget tests; debug merchant forms can scroll when the keyboard opens.

Profile's My Wallet tab/card and Game Rewards' Open My Wallet action reach the same overview. Back uses the actual navigation stack when present, with sensible direct-link fallbacks. The existing Game and Hunter reward sinks remain unchanged and both credit the authoritative wallet provider. Watching the authenticated account ID preserves the wallet during profile edits, while separate accounts use separate saved ledgers.

Confirmation generates a UUID request with an idempotency token. Repeated taps or a repeated token reopen the existing request. A pending request reserves RC without deducting the posted balance or issuing a voucher. Approval requires a pending request, sufficient posted RC and unassigned demo stock. It assigns one stock item, records one RC debit, releases the hold and issues one uniquely coded voucher. Repeated approval fails. Rejection releases its reservation without an RC debit. Used and expired stock never returns to the pool.

The existing account-scoped `LocalDemoStorage` saves balances, requests, decisions, stock assignments, vouchers, history and credited reward IDs. Writes are serialized. Credits arriving while a saved wallet loads are merged and deduplicated. A failed write remains in memory and exposes a retry action on Overview. Invalid saved ledger data falls back to the centralized demo seed.

Each active voucher has a QR payload derived from its identifier and prominently containing `NOT-REDEEMABLE`. Copy writes the full demo code to the platform clipboard, with an unavailable-platform fallback. Used/expired vouchers have no active QR; an open detail screen also removes its QR at expiry or refreshes status on resume. Merchant simulation accepts a valid demo code or QR payload only once. History includes reward credits, request, approval, one RC debit, rejection and use events; All/HP/RC/Vouchers filters use those actual entries.

## Demo walkthrough

1. Profile → My Wallet, or Game → Rewards → Open My Wallet.
2. Redeem Rewards → Thyaga Rs.500 → Confirm → Request Submitted. Posted RC stays unchanged; available RC is reserved.
3. Back to Wallet → Wallet Rules → DEMO testing area. This separate **debug-only** screen is the only approval/rejection control; the normal pending screen cannot approve.
4. Approve the pending request → Voucher Approved → View My Vouchers → voucher details.
5. Copy the demo code, expand How to Use, or open DEMO merchant testing. Simulate use once, then inspect Used and Transaction History.
6. For rejection, use Requests in the same testing area. The held RC is released without a debit.

The reused seed account starts with posted RC 1,500 and an existing pending RC 1,000 request: **available RC 500**. This is shown explicitly. The three catalog offers cost 500/1,000/2,000 RC. Shopping contains those existing offers; Food and Travel currently show honest empty-category states with an All reset. No extra application fixture lists are embedded in screens.

## Files created

- `lib/features/wallet/presentation/providers/wallet_routes.dart` — eight main routes plus supporting routes.
- `lib/features/wallet/presentation/views/wallet_ui.dart` — fixed scenic shell, responsive fit, glass/buttons/tabs and shared display widgets.
- `lib/features/wallet/presentation/views/wallet_overview_screen.dart` — Overview and Wallet Rules.
- `lib/features/wallet/presentation/views/wallet_redemption_screens.dart` — catalog, confirmation, pending, approved, rejected, insufficient and missing-record states.
- `lib/features/wallet/presentation/views/wallet_voucher_screens.dart` — My Vouchers, QR/code details and filtered history.
- `lib/features/wallet/presentation/views/wallet_demo_screen.dart` — isolated debug approval/rejection and merchant simulation.
- `test/wallet/wallet_ledger_test.dart` — 13 ledger/repository/reward/persistence tests.
- `test/wallet/wallet_flow_test.dart` — 9 journey/integration/error/expiry/layout widget tests.
- `docs/WALLET_IMPLEMENTATION.md` — inventory, implementation and delivery ledger.

## Files modified

- `lib/core/mock/mock_data.dart` — centralized finite demo stock, validity/progress configuration, expired sample and request/history metadata.
- `lib/features/wallet/domain/wallet_models.dart` — extend existing typed entities with assignment/decision metadata, derived balances/status and integrity checks.
- `lib/features/wallet/data/mock_wallet_repository.dart` — consume centralized fixtures and persist/restore the complete ledger.
- `lib/features/wallet/presentation/viewmodels/wallet_view_model.dart` — extend the existing provider and ViewModel; no duplicate wallet repository/provider/model set.
- `lib/app/app_router.dart` — replace only the old Wallet preview route with the Wallet route list.
- `docs/SCREEN_COVERAGE.md` — W-01 through W-08, supporting states and Profile/Game wallet entries.

No existing tests were deleted, skipped or weakened. No dependencies, platform configuration, Maps keys, original assets or unrelated feature source were changed. Hash checks confirm the baseline Home/Auth/Traveller/Hunter/Game/Profile source samples, original background and Android manifest are unchanged.

## Verification — 6 November 2026

- Milestone 1: complete suite **77 passed**, after the 13 ledger tests were added.
- Final `flutter test`: exit **0**, **86 passed** (64 existing + 22 new Wallet tests).
- Final `flutter analyze`: exit **1**, **30 existing informational lint notices** in untouched Game, Hunter, Profile and Traveller code; no errors or warnings. These unrelated files were preserved.
- `flutter analyze lib/features/wallet lib/app/app_router.dart lib/core/mock/mock_data.dart test/wallet --no-pub`: exit **0**, **No issues found**.
- Render review: **9 Wallet widget tests passed** with real Roboto. W-01 through W-08 were captured and visually inspected. Small-phone layouts at 390 × 844, 320 × 640 and 320 × 568 retain fixed header/footer and have no rendering exceptions. QR painter output is compared against the identifier payload, and platform clipboard arguments are checked against the full code.
- `flutter build apk --debug --no-pub`: exit **0**, debug APK built; Gradle completed in **39.2 seconds**.
- Android 17/API 37 emulator (`emulator-5554`): debug APK installed with existing data retained. Profile → My Wallet → catalog → confirm → Pending → separate debug approval → approved → vouchers → details/clipboard → merchant use → history passed. Repeated merchant use was blocked. Pending kept posted RC 1,500 while reserving the remaining 500; approval posted exactly one 500 RC debit. Restart and local demo sign-in restored posted RC 1,000, the original 1,000 RC hold, the same unique Used voucher and transaction history. The Used record had no active QR. Android Back from a directly entered Wallet root returned to Profile. No `flutter:E` or `AndroidRuntime:E` entries were returned by the final diagnostic check. Physical hardware was not tested.

Logs and rendered evidence are in the ignored `.codex_review/` folder: `wallet_milestone1_test.log`, `wallet_final_test.log`, `wallet_final_analyze.log`, `wallet_scoped_analyze.log`, `wallet_visual_test.log`, `wallet_android_build.log`, and `wallet-w01.png` through `wallet-w08.png`.

Native evidence: `wallet_native_smoke.log`, `wallet_native_use.log`, `wallet_native_restore.log`, `wallet_native_errors.log`, and `wallet-native-*.png`. The emulator is left on the restored Overview. Its demo ledger was not reset: it retains the Used Rs.500 voucher and the original pending Rs.1,000 request. To free that hold for another manual run, reject the original request in Wallet Rules → DEMO testing area. The centralized initial fixtures are unchanged by running the app.

## Prototype limits

The catalog, finite stock and account ledger are local demo data. There is no real admin, merchant, voucher validation, payment or partner integration. All QR/codes are nonredeemable. Debug tools are hidden and route-blocked in release mode, and mutation methods also reject actions when those tools are disabled. This is a local UI boundary, not a production security system. Local preference persistence is not a server ledger and does not synchronize devices. The existing storage adapter intentionally falls back to memory for an unavailable native preferences plugin; in that fallback, data lasts only for the current launch. Wallet exposes retry when its repository reports a write failure. No additional API key or service setup is needed for Wallet; existing Google Maps configuration is preserved.

## Confirmation layout correction — 6 November 2026

Only application Dart file modified: `lib/features/wallet/presentation/views/wallet_redemption_screens.dart`, within `WalletConfirmScreen` and its new private presentation helpers. The shared scaffold, `WalletFit`, state/repository, pending cancellation, reservation/debit rules, approval, vouchers/QR, history, Profile routes and other feature source are preserved. Existing tests are byte-for-byte unchanged. Documentation updates are this ledger and `SCREEN_COVERAGE.md`.

The prior fixed 625/710-pixel design box was not a responsive height budget. Its inner Column laid out wrapped labels, additional balance rows, message, link and buttons before `FittedBox` scaled the finished page. Thus the inner Column could overflow even when the final page looked scaled to the phone. Current-source reproduction caught both 36-pixel small-phone errors. It also caught a separate missing shortfall action: a pending reservation replaced the shortfall link instead of offering both destinations.

The corrected screen uses `LayoutBuilder` and Expanded sections bounded by actual body space. A shorter phone uses a horizontal voucher, smaller padding and gaps; balance rows fit complete labels and values without wrapping or ellipsis. Each section measures its full natural height and scales down only within its own allocation, eliminating fixed-height nested Columns. The full explanatory text and both insufficient-RC links remain visible. Cancel/Confirm keep their normal 46-pixel height outside the flexible sections, above the unchanged fixed footer. No page scroll or content clipping was introduced.

Final checks for this correction:

- Required Wallet widget command: **9 passed**, exit **0**.
- Full `flutter test`: **88 passed**, exit **0**, no unrelated failures.
- Full `flutter analyze`: exit **1**, **one existing informational Profile async-BuildContext notice** at line 712; no errors/warnings. The changed Dart file: **No issues found**, exit **0**.
- Separate ignored 18-case diagnostic matrix passed with both the default test font and real Roboto. All three voucher values were exercised at all three requested sizes, with and without RC holds. Field visibility, full-size action buttons, fixed header/footer, shortfall navigation, disabled confirmation and Cancel were checked. Captures at 320 × 568 and 390 × 844 were visually inspected.

Current evidence: `.codex_review/wallet_overflow_repro.log`, `wallet_overflow_fixed_test.log`, `wallet_overflow_analyze.log`, `wallet_overflow_scoped_analyze.log`, `wallet_overflow_full_test.log`, `wallet_confirm_matrix.log`, `wallet_confirm_visual.log` and `wallet-confirm-*.png`. This correction's verification is widget/render validation; the earlier Android build/smoke evidence above predates this layout change.
