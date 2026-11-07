# Wayhunter Flutter – Active Trip and Profile Integration Update

This update was prepared from the uploaded existing source project, not a fresh Flutter app. It changes the UI/application wiring and keeps the current authentication, original scenic Home assets, Android Maps configuration and core mock repositories.

## Implemented in source

- `/traveller/active` routes to `ActiveTripDashboard` with a fixed page (no main vertical `ListView` or `SingleChildScrollView`), fixed four-icon bottom navigation, compact trip header, embedded Google Map, route progress, Find, Report Hazard, Add Memories, Friends, road alert and Finish Trip.
- `TravellerMap(compact: true)` hides its extra developer notes and `Enable my location` button when embedded in the compact active dashboard; standard TravellerMap remains unchanged for other screens.
- The initial map camera is centered across selected stop coordinates instead of always on the first stop. Polyline remains a **mock straight-segment route**, not road navigation.
- `/profile` now shows a five-tab UI (Games, Posts, Trips, Hunt Places, My Wallet), displays the signed-in user's name, avatar, bio and level, and reads trip posts/completed trips from the existing Traveller provider.
- `/profile/edit` allows changing the local display name, bio, location and small avatar. `/profile/settings` exposes local language/privacy/notification preferences, help/about, and logout confirmation.
- Traveller memory and hazard **metadata**, plus small photo bytes when below 1 MB, are written to the existing local storage and restored on app restart. Large photo bytes and captured video temporary paths may not persist indefinitely; secure production media storage is out of scope for this offline prototype.
- Existing Nearby Places, Hazard Report, Add Memories and Friends detail screens remain implemented and navigable through their original routes, with their original input validation and demo capture; they were **not** pixel-perfect redesigned in this patch.

## Important prototype limitations

- There is NO backend, real multi-user Friend tracking, real hazard broadcast, live Places search, verified road routing or actual voucher redemption.
- Google Maps tile display requires your **own local Android API key**. Real secrets and `android/secrets.properties` are deliberately excluded from shared ZIP archives.
- Security/password changes and real account deletion need backend services. Settings do not misleadingly claim those real operations were completed.
- UI references are taller than most mobile viewports. Active Trip uses a flexible-height map and compressed tiles so the page stays fixed; device-specific overflow should be checked in landscape and on very small handsets.
- Flutter SDK/Dart are not installed in the processing environment. Therefore `flutter analyze`, `flutter test` and Android emulator/device interaction could NOT be run here. The modified Dart files passed **static reference/import and balanced-delimiter checks only**; device compilation is not guaranteed.

## Windows – apply PATCH ZIP (recommended)

1. Keep the original `wayhunter_mobile` project intact.
2. Extract `Wayhunter_ActiveTrip_Profile_PATCH.zip` to an empty folder (e.g. Downloads/Wayhunter_Patch).
3. Open a PowerShell terminal in the extracted folder.
4. Execute:

```powershell
powershell -ExecutionPolicy Bypass -File .\APPLY_PATCH.ps1 -ProjectRoot "C:\Users\Admin\Desktop\way_hunder\wayhunter_mobile"
```

The script backs up only replaced source files under `wayhunter_mobile/.wayhunter_backup_*` and copies modified/new files.

5. In the original Flutter project terminal:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

6. Test: Home -> Traveller -> My Plans -> Start Trip -> Active Trip. Confirm fixed layout and tap Find, Report Hazard, Add Memories, Friends, Road Alert, Finish Trip. Post a memory, then open Profile -> Posts and Profile -> Trips. Exit and reopen the app to test local restoration.

## Troubleshooting

- `GoogleMap` blank: verify the Android Maps SDK key is present in your local ignored secrets file, and your package/SHA-1 restrictions match the APK.
- `RenderFlex overflowed`: screenshot the device size and the exact screen; this requires adjusting the compact-height thresholds for that device.
- Any Dart analysis errors: send the complete `flutter analyze` output plus the affected file and line; no SDK was available for a definitive compile here.
- Your original Home/Authentication and the other Hunter/Game/Wallet prototype flows are not redesigned by this patch.
