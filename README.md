# Wayhunter mobile prototype

Flutter Android-first UI prototype with working authentication, Home and the complete local Traveller workflow. Traveller opens a real map landing and supports planning, multiple stops, saved/active/completed trips and independent trip tools. Hunter, Game, Profile and Wallet retain their existing entry previews outside the Traveller task. The original Home artwork and native Google Maps configuration are preserved.

There is no backend, database, live authentication, SMS/email delivery or voucher redemption. `lib/core/mock/mock_data.dart` is the only application fixture source. Registration and password changes live in memory for the current run. Remember Me saves only the email, and harmless language/onboarding preferences can persist locally.

## Run on Windows / PowerShell

From this project folder:

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <ANDROID_DEVICE_ID>
```

Use Flutter 3.47.6 / Dart 3.13.5 or a compatible newer stable SDK. Android minimum SDK is 24. A phone or emulator with Google Play services is needed to verify native Maps, camera and permission prompts. Chrome can preview the local UI, but this phase deliberately keeps Android Maps key configuration separate and shows a fallback on unsupported platforms.

## Explore the demo

- Demo account: `traveller@gmail.com` / `wayhunter123`.
- Demo OTP: `123456`. No code is sent externally. The Sign In screen can fill the demo account for you.
- Create Account → local OTP → Sign In → first-time permissions → Home. Later sign-ins skip the completed introduction.
- Forgot Password → local OTP → Reset Password → Sign In. The new password is valid in the current run.
- Use the explicit offline simulation to exercise Retry, Resume and Cancel while preserving entered form values.
- Home's Traveller image button opens the actual Traveller landing. Create → add/reorder stops → save → My Plans → Start → Active Trip → Finish → Completed works locally. AI and previous-segment plans are optional. Nearby, road alerts, hazards, memories, friends and invitations return independently to the trip. Other module entry previews remain unchanged. Search filters local places; notifications can be marked read; the profile entry supports confirmed sign-out.
- The language dropdown saves the selection. This phase does not claim translated UI strings.

## Maps configuration

Read [the Android Maps setup guide](docs/04_GOOGLE_MAPS_SETUP.md). Add your own Android-restricted key in ignored `android/secrets.properties`; never put it in Dart, a checked-in manifest, or a shared launch configuration. Without a key, the UI remains usable and shows an explicit map fallback.

Map pins are approximate demo content. No road Directions, location verification, traffic, live nearby search or safety service is implemented.

## Architecture and coverage

- `lib/app`: MaterialApp, theme and a stable GoRouter listening to auth changes.
- `lib/core`: assets, glass widgets, native services, local storage and centralized MockData.
- `lib/features/auth`: typed domain contracts, local repository, Riverpod view model and views.
- `lib/features/home`: typed content repository, Riverpod view model, Home and explicit feature entry previews.
- `lib/features/traveller`: reusable Jaffna map, typed fixture repository, geolocator permission adapter and Riverpod map ViewModel.

See [Traveller completion](docs/TRAVELLER_IMPLEMENTATION.md), [screen coverage](docs/SCREEN_COVERAGE.md) and historical [Phase 1 evidence](docs/PHASE_1_IMPLEMENTATION.md) for files, navigation, checks and remaining setup. The six workflow diagrams and original images remain the authority.
