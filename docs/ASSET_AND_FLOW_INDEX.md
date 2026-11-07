# Wayhunter reference inventory

## Real user-supplied runtime assets (COPY into Flutter assets)

- `assets/images/backgrounds/home_background.png` -- waterfall, bridge, mountain, compass travel art. Use Home scenic background and optionally subtle theme-wide use.
- `assets/images/buttons/traveller_button.png` -- complete Traveller blue scenic graphic with label and arrow; tappable Home button.
- `assets/images/buttons/hunter_button.png` -- complete Hunter amber/gold graphic with label and arrow; tappable Home button.
- `assets/images/buttons/game_button.png` -- complete Game purple trophy graphic with label and arrow; tappable Home button.

## Six flow diagrams (reference only; DO NOT show as full UI screen)

1. `docs/flows/01_login_to_home.png` -- Auth, OTP, recovery, errors, first-time permission, Home.
2. `docs/flows/02_home_to_traveller.png` -- Route builder, AI, past traveller, Edit T-A, live trip branches, Group T-F, finish.
3. `docs/flows/03_home_to_hunter.png` -- District, 360, photo, review, moderation, H-CAM/H-ADM/H-GPS/H-DUP.
4. `docs/flows/04_home_to_game.png` -- Game create, Game play, winner, Game Over, My Games, leaderboard, how/rewards/wallet.
5. `docs/flows/05_profile_settings.png` -- profile/settings, edit, account confirmation, Wallet entry.
6. `docs/flows/06_wallet_vouchers.png` -- Wallet workflow including alternative states; latest wallet reference takes priority.

## Individual screens (original ZIP)

- `docs/original_screens/login/` -- Auth & Home (6 image files).
- `docs/original_screens/traveller/` -- Traveller (12 image files including create/active/finish).
- `docs/original_screens/hunder/` -- original Hunter 10-panel combined image (one image file).
- `docs/hunter_separated/` -- 10 cropped Hunter panels for convenient per-screen inspection; first two share Auth/Home.
- `docs/original_screens/game/` -- Game (14 image files including one combined storyboard).
- `docs/original_screens/profile/` -- Profile + settings montage (2 image files).
- `docs/settings_separated/` -- 10 cropped settings panels (10 reference images).
- `docs/wallet/wallet_eight_screen_reference.png` -- current wallet eight-screen reference; supersedes older wallet illustrations.

Note: Some additional screen cards in the six workflow diagrams were generated as design proposals and marked FLOW / NO SCREEN. Codex should implement them as new Flutter screens but must not misrepresent them as shipped/verified UI or functioning backend services.
