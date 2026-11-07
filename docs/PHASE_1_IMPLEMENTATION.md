# Phase 1 implementation ledger

## Inspected baseline

- Flutter 3.47.6 stable / Dart 3.13.5, Android generated structure present.
- Existing runtime is the generated counter app; no feature screens are being removed.
- Read AGENTS.md, CODEX_MASTER_PROMPT.md, the Phase 1 prompt, all six workflow images, all 35 original references, both cropped-panel sets, wallet reference, original assets and MockData.
- Dependencies are already declared. Runtime asset directories still need registration.
- This folder is not currently a Git repository. Secret exclusions still apply when it is added to source control.

## Scope and implementation order

1. Record the complete six-flow screen inventory in SCREEN_COVERAGE.md, with later phases explicitly deferred.
2. Add the app shell, dark glass theme, responsive shared widgets, asset paths and stable Riverpod/GoRouter wiring.
3. Implement local typed authentication repositories and Riverpod view models: sign in, registration, OTP, recovery/reset, offline retry/cancel and first-time permissions.
4. Implement Home using the original background and exactly three original full-image mode buttons. Provide honest, navigable module entry previews while preserving later-phase route plans.
5. Integrate the Google Maps widget and Android configuration with an ignored local key and safe missing-key fallback. Request native permissions only on user action.
6. Run analysis, meaningful auth/Home/router tests and visual layout checks. Record exact outcomes and remaining native setup below.

## Architecture boundaries

- Domain: typed entities and repository contracts without Flutter widgets.
- Data: mock implementations consume only lib/core/mock/mock_data.dart for application fixtures.
- Presentation: Riverpod Notifier view models manage local state; widgets render state and invoke commands.
- Navigation: GoRouter reacts to authentication and onboarding state, including protected deep links.
- Storage: remember harmless preferences only; no persisted passwords or simulated remote authentication.
- Google Maps is the only approved live network integration. Auth, OTP and all application data remain local demonstrations.

## Working screens and navigation

- `/sign-in`: local credentials, show/hide password, remembered email, login-only language dropdown, demo autofill, inline validation and explicit offline simulation.
- `/register` → `/otp` → `/sign-in`: optional camera/gallery profile photo, name/email/phone/password confirmation/terms, duplicate account feedback, six-digit OTP validation, expiry and resend cooldown. Verification never signs the account in automatically.
- `/forgot-password` → `/otp` → `/reset-password` → `/sign-in`: verified local recovery, matching passwords, changed credentials work for the current run.
- Auth action → `/offline` → Retry → `/connection-restored` → Resume: original action executes once. Cancel → `/cancel-auth` → original form, preserving drafts. Header and Android Back return safely to the appropriate form.
- Newly registered account Sign In → `/permissions` → Continue or Not Now → `/home`. Location/camera/notifications request native permission only on explicit taps. Denied or unavailable permissions do not block demo use. Introduction completion persists per local email.
- `/home`: original scenic background and exactly three original full image buttons; local search and selected-place entry; local advertisement details; notifications and mark-read state; profile entry and footer destinations.
- `/traveller`, `/hunter`, `/game`: explicit Phase 1 entry previews with mode accent colors, safe Maps view/fallback, working Back/Home. Full feature workflows are deferred.
- `/profile`, `/wallet`, `/leaderboard`: explicit entry previews with session/sample details and working navigation. Profile has confirmed local sign-out. These do not complete the later reference screens.
- `/notifications`: local demo notices and mark-all-read state reflected on Home.

The router protects signed-out deep links, OTP/reset context and incomplete first-time onboarding. The same GoRouter instance listens to auth changes; form updates do not recreate the navigation stack.

## Created files

App and shared foundation:

- `lib/app/app.dart`
- `lib/app/app_router.dart`
- `lib/app/app_theme.dart`
- `lib/core/constants/app_assets.dart`
- `lib/core/services/device_permission_service.dart`
- `lib/core/services/maps_service.dart`
- `lib/core/storage/local_demo_storage.dart`
- `lib/core/widgets/app_nav_bar.dart`
- `lib/core/widgets/demo_map.dart`
- `lib/core/widgets/feature_scaffold.dart`
- `lib/core/widgets/glass_panel.dart`
- `lib/core/widgets/neon_button.dart`
- `lib/core/widgets/scenic_background.dart`

Authentication:

- `lib/features/auth/data/mock_auth_repository.dart`
- `lib/features/auth/domain/auth_repository.dart`
- `lib/features/auth/domain/auth_user.dart`
- `lib/features/auth/presentation/viewmodels/auth_view_model.dart`
- `lib/features/auth/presentation/views/auth_screens.dart`

Home:

- `lib/features/home/data/repositories/mock_home_repository.dart`
- `lib/features/home/domain/entities/home_content.dart`
- `lib/features/home/domain/repositories/home_repository.dart`
- `lib/features/home/presentation/viewmodels/home_view_model.dart`
- `lib/features/home/presentation/views/feature_entry_screen.dart`
- `lib/features/home/presentation/views/home_screen.dart`

Tests and delivery docs:

- `test/auth/auth_flow_test.dart`
- `test/auth/auth_view_model_test.dart`
- `test/core/native_fallback_test.dart`
- `README.md`
- `docs/PHASE_1_PLAN.md`
- `docs/PHASE_1_IMPLEMENTATION.md`

## Updated existing files

- `lib/main.dart`: ProviderScope and Wayhunter app entry, replacing generated counter content.
- `lib/core/theme/wayhunter_palette.dart`: exact electric blue, gold and purple accents.
- `pubspec.yaml`: original runtime asset directories and project description; compatible dependencies were already declared.
- `test/widget_test.dart`: replaces generated counter test with five app/Home integration tests and optional local screenshot capture.
- `android/app/build.gradle.kts`: API 24 minimum, ignored secret injection, explicit Properties import and compatibility with Flutter's generated legacy Android DSL flags.
- `android/app/src/main/AndroidManifest.xml`: app label, permissions, optional camera hardware and Maps metadata placeholder.
- `android/app/src/main/kotlin/com/example/wayhunter_mobile/MainActivity.kt`: native configuration boolean and explicit camera/notification permission channel.
- `.gitignore`: native Maps secrets and disposable review artifacts.
- `README_FIRST.md`, `docs/04_GOOGLE_MAPS_SETUP.md`, `docs/SCREEN_COVERAGE.md`: current setup and complete reference inventory.

No reference images, original artwork, MockData fixtures, or generated platform files were deleted. The original duplicate `home_buttons` asset directory is retained.

## Verification

- `flutter pub get`: exit 0; compatible existing dependencies resolved.
- `flutter test`: exit 0, **23 passed**. Seven auth repository/ViewModel tests, three auth widget flows, five app/Home widget flows, eight native-service/fallback tests.
- Auth tests exercise wrong credentials, invalid and expired OTP, cooldown, duplicate registration, recovery guards, remembered email/language, offline retry/cancel, signup/onboarding once, password reset and Android Back.
- App tests exercise protected deep links, all original Home mode image buttons, module return navigation, search, notifications, sign-out confirmation and 320×640 layout with a keyboard inset.
- Local captures were rendered and inspected at 390×844 and 320×640 using the supplied artwork; no replacement images were generated. Captures/logs are disposable ignored files under `.codex_review/`.
- Final `flutter analyze`: exit 0, **No issues found! (ran in 15.8s)**.
- Final standard `flutter test` (without screenshot/font environment settings): exit 0, **23 passed**, runner finished at `00:04 +23: All tests passed!`.
- `flutter build apk --debug`: exit 0, **Built build/app/outputs/flutter-apk/app-debug.apk**, Gradle task took 406.0s. The debug APK is a generated ignored build artifact.
- The native build emitted an Android SDK XML-version tooling warning and a geolocator dependency deprecation note; both were non-fatal. No native runtime behavior is claimed from compilation alone.

## Remaining setup and prototype boundaries

1. Supply an Android-restricted Maps SDK key in ignored `android/secrets.properties`, enable Maps SDK for Android/billing and restrict by package `com.example.wayhunter_mobile` plus signing SHA-1. See `docs/04_GOOGLE_MAPS_SETUP.md`.
2. Connect an Android device/emulator with Google Play services and verify real map tiles, profile photo picker and permission dialogs. No Android device was attached during this implementation; widget tests do not prove native runtime behavior.
3. Registration and changed passwords reset with the app process. Remembered email, language selection and permissions-introduction flags are harmless local preferences. No passwords or key are written to SharedPreferences.
4. Language selection is saved; prototype copy remains English. Offline is an explicitly controlled demonstration, independent of real device connectivity.
5. Full Traveller, Hunter, Game, Profile/Settings and eight-screen Wallet implementation remains in Phases 2–6. No real evidence verification, winner decisions, merchant redemption or safety/navigation service is claimed.
