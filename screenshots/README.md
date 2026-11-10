# Android screenshot export

From PowerShell in the project root, with an Android emulator running:

```powershell
flutter pub get
.\scripts\export_screenshots.ps1
```

Use `-Device <adb-id>` for another Android target, or `-Module wallet` (auth,
home, traveller, hunter, games, profile, wallet) to export one module.

The script temporarily sets the Android surface to **390 × 844 at density 160**
and restores its previous size/density in `finally`. It grants the existing
declared camera/location/notification permissions on the test device. Run on
a disposable emulator when existing permission choices matter.

The integration test mounts the existing `WayhunterApp`, router, theme and
feature screens. Only persistence uses the existing `MemoryDemoStorage`, so
the installed demo's saved balances, profile and trip data are preserved.
Existing ViewModel demo actions prepare pending/approved/used states; no app
code, reward rules, balances or screen designs are modified.

`IntegrationTestWidgetsFlutterBinding.takeScreenshot` captures the Android
Flutter surface including platform views. The host driver copies each original
PNG byte-for-byte via `adb run-as`, checks its PNG signature, and writes the
module folders, `SCREEN_INDEX.md` and `capture_manifest.json`. Errors are
reported and fail the run; screens with loading/error widgets are refused.
Bundled assets are precached; native maps receive an additional render wait.
Configured Maps keys remain native and are never exported. Camera/360 demo
screens retain the application's visible prototype limitations.

`/loading` is intentionally excluded. Historical classes with no route and
reference-only screens that were never implemented are identified in the index.
