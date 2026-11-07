# WAYHUNTER -- Codex project rules

The owner is building **only the Flutter Android-first mobile UI prototype**. It is NOT the ASP.NET backend, Angular admin website or real voucher redemption platform.

## Read these before writing code
1. `CODEX_MASTER_PROMPT.md` -- exact behavior, priorities and acceptance checks.
2. `docs/flows/01_login_to_home.png` through `docs/flows/06_wallet_vouchers.png` -- six authoritative, final workflow maps.
3. `docs/original_screens/` -- 35 original design reference images.
4. `docs/hunter_separated/` and `docs/settings_separated/` -- cropped panels from the original screen montages.
5. `docs/wallet/wallet_eight_screen_reference.png` -- authoritative wallet UI and order.
6. `assets/images/backgrounds/home_background.png` and `assets/images/buttons/{traveller,hunter,game}_button.png` -- ORIGINAL user assets. Use unchanged.

## Non-negotiable
- Flutter + Dart, **Feature-first + Clean Architecture + MVVM + Riverpod**.
- **NO** backend, EF/SQL Server, Firebase, Supabase, live auth, GraphQL, REST, mock HTTP server or payment/merchant API calls.
- `lib/core/mock/mock_data.dart` is the **only source of hardcoded application datasets**. Other classes can hold UI copy, model types and state but may not invent separate duplicate fixture lists. Implement mock repositories that consume `MockData`.
- Live network allowed **only** for the user-approved Google Maps Platform/Maps SDK (if properly configured). Do not pretend a mock polyline is a verified Directions route.
- Use Riverpod for state, GoRouter for screen navigation, and typed domain entities/repositories. Screens should not embed mock JSON, business rules, or networking.
- Use user-supplied home scenic background and original *three full button graphics*: Traveller=BLUE; Hunter=GOLD/AMBER; Game=PURPLE. Never add duplicate text over a button image that already contains its title.
- All other screens: dark premium cinematic imagery, low-opacity black/navy **glass** surfaces and readable contrast. Reuse existing screenshots' layout and function, change only color/background as requested.
- No inert buttons, broken nav or silent UI omissions. Every clickable action must navigate or update meaningful local state; if external action truly unavailable, show an honest DEMO indicator and an explicit non-functional description.
- Android-first. User uses Windows 11 / VS Code; give commands for PowerShell.
- Do not implement production location safety/duplicate checks, authentic 360 filming, payment or partner voucher acceptance: simulate **clearly labeled** prototype flows and keep the app usable if camera/GPS/Maps key are unavailable.
- Flutter project files such as AndroidManifest, pubspec and main.dart may be edited when necessary; preserve generated Flutter platform structure.
- Recheck `flutter analyze` and `flutter test` after each milestone; report exact results, do not claim tests passed without running them.

## Workflow integrity
- Auth -> Home, Create Account -> OTP -> Sign In, Forgot -> OTP -> Reset Password -> Sign In, offline Retry/Cancel, one-time permissions.
- Traveller: manual, AI plan (mock), previous traveller segments, reorder/add/remove stops, saved plans, active trip, nearby on demand only, alerts/hazards/memories/friends/deviation, finish. Include T-A and T-F missing UI states in flow diagram.
- Hunter: current district GPS, H-CAM, H-GPS, H-DUP, 360 evidence mock/real capture if supported, live photo, review, submit pending, H-ADM demo moderation status, rewards, leaderboard.
- Game: create + play paths, G-VICTORY, G-OVER, G-W, G-HOW, G-LB, G-MY, G-RW; creator can't join own game, winner decision must be a **mock simulation** rather than claiming verified server result.
- Profile: profile tabs, edit profile, P-DO cancel action, language dropdown, security/password, privacy, notifications, help/how to use, app version, delete Yes/No, logout confirmation, wallet entry.
- Wallet: exactly eight main screens (Overview -> Choose Voucher -> Confirm -> Request Pending -> Approved -> My Vouchers -> Details QR/code -> Transaction History), plus insufficient RC, rejected, expired/used, pending states. `Pending -> Approved` is a **manual developer demo action** in the prototype; no real admin exists. Display DEMO voucher; QR is non-redeemable.

## Reporting
- Work in small milestones following `prompts/`.
- Maintain `docs/SCREEN_COVERAGE.md` mapping every reference screen and flow-only state to implemented Dart file and route.
- Implement actual UI screens; do NOT just paste or display entire flow diagram as app UI.
