# CODEX -- BUILD WAYHUNTER FLUTTER UI PROTOTYPE (MASTER PROMPT)

You are editing a freshly generated Flutter project in this repository. **Build real functional Flutter UI screens, not a slide deck or static screenshots.** Read `AGENTS.md`, ALL SIX files in `docs/flows/`, the 35 source screens in `docs/original_screens/`, the two separated montage directories, the wallet reference image, and the user-supplied asset files before implementing. The six workflow images are the navigation source of truth, and individual original screen images are layout/controls references. Preserve all flow steps and controls. Screens that appear only as 'FLOW / NO SCREEN' in the diagrams should be newly designed using the same glass UI language and added to coverage; they are not to be skipped.

## GOAL

Ship a working Android-first Wayhunter **mobile prototype** in Flutter, using Feature-first + Clean Architecture + MVVM with Riverpod, GoRouter routing and local-only mock data. Use **Google Maps Flutter SDK with a real restricted API key supplied by the developer** (the key is NOT in the provided assets). GPS/camera native capabilities are allowed. No backend of any kind. No ASP.NET, Angular, Firebase, SQL Server, local HTTP service, mock REST endpoints, live signup/SMS/email or real voucher/merchant redemptions. All content fixture data lives in exactly one file: `lib/core/mock/mock_data.dart` (already provided).

## PRIORITY AND BUILD METHOD

1. Inspect all reference files and produce a screen inventory `docs/SCREEN_COVERAGE.md` BEFORE coding: group by Auth, Traveller, Hunter, Game, Profile, Wallet; list source image or flow state; route; Dart screen; and button destinations. Keep design inventory distinct from completed work.
2. Verify and correct Flutter project setup; install stable dependency versions compatible with installed Flutter/Dart (`flutter pub add flutter_riverpod go_router google_maps_flutter geolocator camera image_picker shared_preferences intl uuid`). Use only the dependencies needed. Ensure actual Android minSdk compatible with packages; configure permissions. Configure Maps key injection securely (see README); never commit an unrestricted key. Handle missing Maps key with an error/fallback panel, not a crash.
3. Create/apply shared `app_theme.dart`, `app_router.dart`, glass widgets, screen background widget and responsive layout. Base the entire visual style on the REAL user-supplied `home_background.png`. On Home render three ORIGINAL graphic assets as tappable, accessible full-image buttons: `traveller_button.png`, `hunter_button.png`, `game_button.png`. Use BoxFit.contain or clipping that doesn't cut off the built-in label/arrow. Do not retype 'Traveller/Hunter/Game' over those images. Keep profile in header, advert banner if in reference, and correct bottom navigation; use SafeArea/SingleChildScrollView without overflow. Avoid generic Material-colored placeholder pages.
4. Create local mock repositories per feature, but import **all fixtures from `MockData`**. Riverpod providers/ViewModels are responsible for mutable UI state (draft trips, login session, camera evidence, pending voucher request, progress). Optionally persist harmless session/username/selected preferences in shared_preferences locally, not as simulated server operations. No hardcoded fixture arrays in widgets.
5. Implement milestone by milestone from `prompts/`, run `flutter analyze`, `flutter test`, and smoke navigation after each milestone. Fix build and missing imports before proceeding. Do not delete existing features to resolve errors. Give a concise completion ledger.

## PROJECT STRUCTURE

```
lib/
  main.dart
  app/{app.dart,app_router.dart,app_theme.dart,app_providers.dart}
  core/
    mock/mock_data.dart                      # ALL local hardcode/mock fixtures HERE
    constants/{app_colors.dart,app_assets.dart,route_names.dart}
    services/{maps_service.dart,location_service.dart,camera_service.dart}
    storage/{local_demo_storage.dart}
    widgets/{glass_panel.dart,scenic_background.dart,neon_button.dart,app_nav_bar.dart}
  shared/{domain/models,widgets}
  features/
    auth/{data,domain,presentation/views,presentation/viewmodels,presentation/providers}
    home/{presentation/views,presentation/widgets}
    traveller/{data,domain,presentation/views,presentation/viewmodels,presentation/providers}
    hunter/{data,domain,presentation/views,presentation/viewmodels,presentation/providers}
    games/{data,domain,presentation/views,presentation/viewmodels,presentation/providers}
    profile/{data,domain,presentation/views,presentation/viewmodels,presentation/providers}
    wallet/{data,domain,presentation/views,presentation/viewmodels,presentation/providers}
    shared/{presentation/widgets}
assets/images/{backgrounds,buttons}
docs/{flows,original_screens,hunter_separated,settings_separated,wallet}
test/{auth,traveller,hunter,games,profile,wallet}
```

Each data feature owns a `Mock*Repository` that reads `MockData` and returns typed domain entities; each domain feature owns entity/repository interfaces as appropriate; presentation `ConsumerWidget/ConsumerStatefulWidget` watches `Notifier/AsyncNotifier` providers. Use consistent provider setup compatible with installed Riverpod major version, no deprecated API mixing. Router guards respect mock auth state and browser/device Back; preserve user edits on navigating between draft steps.

## DESIGN AND COLORS -- STRICT

- Brand dark/navy overlay + cyan/glass with crisp text, vivid premium travel-adventure imagery; users should be able to read text on photography. Use `Color.fromRGBO` or `withValues(alpha:)` not stale deprecated APIs if the Flutter version supports them.
- Traveller primary `#08B7FF` / electric blue, secondary deeper blue.
- Hunter primary `#FFBA32` / GOLD/amber. Current district and GPS validation must be visually clear.
- Game primary `#B277FF` / PURPLE, optional gold for winners and trophies.
- Wallet/Profile neutral cyan + gold accent, keeping new wallet mockup look.
- Rounded glass cards with transparent navy surfaces, thin accent borders and subtle glow; no heavy opaque backgrounds over the scenic art unless essential for text legibility.
- Everything is interactive. Tapping original banner/card buttons must navigate; role-theme active navigation and progress indicators; loading, permission denied, empty, missing Maps key and validation feedback states.
- Use provided original images directly in `assets/` with paths in `pubspec.yaml` and `app_assets.dart`; don't substitute random network art. Reference flow image is a *guide*; do not display it as a single screen in the app.

## FULL 6 WORKFLOW MAPS

### 01 LOGIN -> HOME
Sign In (email/password, remember me, language English/Tamil/Sinhala DROPDOWN on Login only) -> Home on successful local demo validation. Create Account (no language dropdown; form with photo option, name, email, phone, password/confirm, terms) -> OTP six digits -> Sign In -> first-time permissions once -> Home. Forgot Password -> OTP -> Reset Password -> Sign In. Inline errors, show/hide password, incorrect credentials, missing fields, invalid OTP, offline Retry / Cancel. Preserve prior inputs and navigation routes. Demo credentials from MockData; OTP from MockData. Mock 'send OTP' performs no real SMS/email. Home has exactly three large image buttons Traveller, Hunter and Game, header search/profile, advert area if shown.

### 02 HOME -> TRAVELLER (BLUE)
Home -> Traveller Landing Map -> Create New Trip with title/dates, start/end, **Add Stop** multiple intermediates, reorder, remove, vehicle/people/budget. Three alternative plan methods: Manual; AI Trip Plan using local deterministic suggestions; Previous Traveller Plan allowing reuse of selected ordered route **segments**, not necessarily full route. User can review/edit route (T-A), save to My Plans, view Shared/Completed, Start Trip -> Active Trip real Google Map, route markers and sample route polyline (static mock, clearly label estimated, not real Directions). From Active Trip independently open Find Nearby Places **only on demand** with category filter, Road Alert + alternative route demonstration, Report Hazard evidence, Add Memories photo/video/caption, Group Friends live demo markers with deviation alert at 500m, Invite/Accept T-F. Return to Active Trip after each branch. End Trip -> Finish/Summary -> Completed in My Plans. Respect user's multiple-stop journey and ability to edit mid-trip where depicted. All data local.

### 03 HOME -> LOCATION HUNTER (GOLD)
Home -> Hunter Home GPS/current district -> Add New Place -> H-GPS (location permission and restricted-zone feedback, demo validity) -> H-DUP (distance 200m and name/image similarity *demo only*; don't assert secure verification) -> H-CAM (in-app 360 recording flow, explain clearly when real 360 capture is unsupported) -> 360 Completed (Play/Retake) -> Add New Place (video attached) -> Normal Photo Camera using live camera plugin (no gallery upload for Hunter) -> Review photo + 360 + metadata -> Submit for Verification -> Pending -> H-ADM simulated review status (not a real admin) -> My Places/rewards and Leaderboard. Retake/edit and denied GPS/camera error branches work. Only current GPS district is active; avoid actually enabling verification based on guessed coordinates. Keep HP awarded in mock only on APPROVED state, never on submit.

### 04 HOME -> GAME (PURPLE)
Game Zone with level/HP/RC, Create Game, Play Game, My Games G-MY, Leaderboard G-LB, How to Play G-HOW, Rewards Store G-RW, Wallet G-W, sponsored games, active challenges. CREATE path: Setup title/district/type/reward -> Create Photo -> Hint/Rules -> Review -> Publish confirmation -> My Games. PLAY path: district picker (map) -> available challenge list/cards and preview -> Accept -> Find the Place / hints -> Live proof camera -> Submit -> **local demo verification** -> first-winner G-VICTORY + award HP/RC or G-OVER (already won/invalid); creator can't join own game; one win per game. All alternate paths, cancellations, re-entry and points history must work. Original create-photo mockup shows Gallery but earlier spec said phone camera only: preserve documented visible UI while making safety/evidence policy explicit; do not silently remove buttons.

### 05 PROFILE + SETTINGS
Profile avatar/name/level, tabs Games/Posts/Trips/Hunt Places, badges, profile edit P-EDIT, My Wallet entry P-WAL; Settings menu: Password screen (old/new/confirm), language dropdown English/Tamil/Sinhala, Public/Private, notification toggles, Help & Support + How to Use, About & update mock, Delete Account Yes/No including P-DO Cancel, Logout confirm and return to Login. Profile edits must refresh Home header locally. Preserve settings when navigating. Do not silently delete local demo account without confirmation.

### 06 PROFILE -> WALLET (NEWEST REFERENCE MUST OVERRIDE PREVIOUS WALLET FLOW)
Use `docs/wallet/wallet_eight_screen_reference.png` as the visual authority. Eight **distinct** screens: W-01 My Wallet overview (HP, RC, Lifetime HP, level, Redeem, My Vouchers, Transactions, Rules); W-02 Choose voucher Shopping/Food/Travel filtering; W-03 Confirm Redemption with RC cost, current and after balance; W-04 Request Submitted PENDING with Request ID; W-05 Request Approved after explicit **developer demo approval** (no real admin); W-06 My Vouchers Active/Used; W-07 voucher details QR/code/issue/expiry/status/How to Use; W-08 transaction history tabs All/HP/RC/Vouchers. Also W-RJ rejected request, W-LO insufficient RC, W-EX expired or already used. Request must reduce **available RC** by a local hold; approve posts final mock deduction/creates voucher exactly once; reject releases hold, never deducts. Generated code must be prominently `DEMO / NOT REDEEMABLE`; never falsely claim real Thyaga/partner acceptance. Merchant redemption is a simulated state transition with explicit DEMO label.

## GOOGLE MAPS AND CAMERA -- PROPER BOUNDARIES

- Use `google_maps_flutter` to show actual map tiles in map views; real location from `geolocator` when permission is granted. Demo pins are from `MockData.demoCities` and `MockData.places` (approximate). Use safe demo default when GPS not permitted; show that it isn't live GPS.
- Maps API key is NOT included. Use Android Manifest `com.google.android.geo.API_KEY` with a manifest placeholder configured from a local ignored secret file (not a committed literal key). Explain how to set up Maps SDK for Android, billing and API/package+SHA-1 restrictions. If targeting Web also enable Maps JavaScript API and separate web-restricted key; otherwise focus Android.
- Do not claim live route navigation, Traffic, Places Nearby API or live weather merely from showing markers/lines. Google Maps does not automatically provide Directions/Routes API; keep route lines mocked unless that API is explicitly configured later.
- For live Hunter photo use `camera`; for user's profile picture `image_picker` if appropriate. Authentic full 360-degree video, anti-cheat GPS proof and restricted geofencing need extra services/hardware; build transparent UI-only demo states rather than misrepresenting verification. Label mock status visibly.

## REQUIRED COVERAGE / ACCEPTANCE CHECKS

- In `docs/SCREEN_COVERAGE.md` list every UJ-001..UJ-050 from diagrams, and extra Auth-R/E/RY/C/P, Traveller T-A/T-F, Hunter H-CAM/H-ADM/H-GPS/H-DUP, Game G-VICTORY/G-OVER/G-W/G-HOW/G-LB/G-MY/G-RW, Profile P-DO/P-EDIT/P-WAL, Wallet W-01..W-08 plus W-RJ/W-LO/W-EX. Group by six flows; do not double count shared Sign In/Home/screens.
- Each screen should contain actual widgets/input fields/buttons matching the reference image. Do not use a generic empty container as a supposedly complete screen.
- Ensure back buttons are sensible and navigation works from every major path; use `SafeArea`, `MediaQuery`, correct keyboard avoidance, `TextOverflow` handling.
- Ensure local demo flows are genuinely interactive: registration, OTP, forgot/reset, profile changes, trip multi-stops, game session, Hunter drafts/photo, wallet request/approval/used status and history.
- Add widget tests for Home and one flow per feature using mocked dependencies; run analysis and tests; document which native features require physical Android device/real Google Maps key.
- Do not promise a Play Store production-ready app based on these mock flows. Mark this as a prototype.

Begin by presenting the screen inventory and implementation plan in repo docs, then implement **Milestone 1: foundation + assets + theme + Router + Auth + Home** completely. Run `flutter analyze` and `flutter test` (where dependencies permit). Continue only in bounded milestones instead of creating dozens of untested placeholder Dart files. Preserve all previous implemented screens when continuing.
