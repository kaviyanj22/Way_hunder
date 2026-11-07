# Phase 1 plan

Read PHASE_1_IMPLEMENTATION.md for the inspected baseline and bounded implementation order. SCREEN_COVERAGE.md inventories all supplied workflows before code. Implement foundation, theme, router, local demo Auth and first-time permissions, original-asset Home, safe Maps integration and navigable feature entry previews only. Run flutter analyze and flutter test, verify layouts and document native/key setup. Later feature workflows remain deferred.

1. Inspect project rules, centralized fixtures, all six workflow images, 35 originals, both separated panel sets, Wallet authority and original runtime artwork; preserve generated platform structure and existing working files.
2. Record the complete navigation inventory before code. Keep future reservations distinct from implemented and tested screens.
3. Establish Feature-first Clean Architecture and MVVM: typed repository contracts, MockData-backed data implementations, Riverpod state/ViewModels, and GoRouter guards. No backend, database, live auth, HTTP or payment integration.
4. Add shared scenic background, bounded transparent glass surfaces, responsive keyboard-safe layouts, accessible buttons and module accents: Traveller electric blue, Hunter gold, Game purple. Use original artwork unchanged.
5. Implement Sign In, Create Account → OTP → Sign In, Forgot → OTP → Reset → Sign In, inline validation, visibility/remember/language controls, explicit offline retry/resume/cancel, and once-only permission introduction with denied/unsupported fallback.
6. Implement Home with exactly three original full-image cards, profile/search/notifications, demo advert and working footer. Route later features to explicit entry previews with working return navigation; do not claim their full reference UIs complete.
7. Integrate google_maps_flutter via Android key injection from an ignored local secret, compatible SDK/permissions and missing-key/platform fallback. Use Google Maps tiles only when configured; do not claim real Directions, server verification or live nearby content.
8. Format, run flutter analyze and flutter test, exercise meaningful auth and Home navigation/state tests, then record exact outcomes and Android/key setup. Reconcile coverage routes/files with final implementation.

Phase 1 completion never implies complete Traveller, Hunter, Game, Profile/Settings or eight-screen Wallet. Those remain scheduled for prompts 02–06. Native capabilities require an Android emulator/device; none is currently attached.

## Phase 1 reconciliation

Foundation, local authentication, first-time permission introduction and original-asset Home are implemented. All auth views share `lib/features/auth/presentation/views/auth_screens.dart`; state lives in `auth_view_model.dart`, with typed domain models/contracts and a MockData-backed repository. Home is `lib/features/home/presentation/views/home_screen.dart`. GoRouter guards protected routes and unverified recovery, and auth device Back preserves the appropriate form. `/notifications` renders local notifications and updates read/badge state.

`/traveller`, `/hunter`, `/game`, `/profile`, `/wallet` and `/leaderboard` are working, explicitly labeled entry previews in `feature_entry_screen.dart`. Their complete later-phase reference screens remain deferred. Google Maps is integrated with a safe missing-key/platform fallback. The debug APK compiled successfully; native permission dialogs and configured tile rendering still require Android device verification.

Validation: `flutter test` exited **0**, **23 tests passed**. Evidence is grouped in `SCREEN_COVERAGE.md`: 7 auth ViewModel tests, 3 auth widget flows, 5 app/Home/router widget tests and 8 native-service/fallback/storage tests. The latest completed analysis reported no issues; final exact analysis/build output is maintained by the implementation ledger in `PHASE_1_IMPLEMENTATION.md`. Android device smoke testing and restricted Maps key setup remain required.
