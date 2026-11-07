# Google Maps and Android permissions

The Traveller feature supplies a reusable `TravellerMap` built with `google_maps_flutter`, Riverpod and a typed repository/ViewModel. Its existing `/traveller` entry opens the map centered on Jaffna with one approximate Jaffna Fort demo marker from `MockData`. Home artwork and GoRouter navigation are unchanged. Android reports only a configuration boolean to Dart; no key is returned or passed through `--dart-define`. Missing/default keys and unsupported preview platforms show an explicit fallback.

The project uses Android API 24 or newer, matching the installed [google_maps_flutter package requirements](https://pub.dev/packages/google_maps_flutter). The generated Android platform structure and AGP 9 configuration are preserved.

## Configure a restricted key

1. Create or select a Google Cloud project, enable billing, and enable **Maps SDK for Android**.
2. Create a key restricted to the Android package `com.example.wayhunter_mobile` and your development signing certificate SHA-1. Restrict API use to **Maps SDK for Android**. Release signing needs its own matching fingerprint.
3. Use the ignored local `android/secrets.properties` file. An existing key found in the source manifest was moved here during configuration. Edit this file locally if you need to replace it; never paste the key in chat:

   ```properties
   MAPS_API_KEY=YOUR_RESTRICTED_ANDROID_KEY
   ```

4. Both root and Android `.gitignore` rules exclude `secrets.properties`. The committed `android/local.defaults.properties` contains only `MAPS_API_KEY=DEFAULT_API_KEY`; keep this safe value unchanged. Native keys are packaged into the APK and therefore still require the package/certificate/API restrictions above.
5. Rebuild and run on an Android device or emulator with Google Play services:

   ```powershell
   flutter pub get
   flutter run -d <android-device-id>
   ```

To inspect signing fingerprints (requires a JDK and working Android SDK):

```powershell
Push-Location android
.\gradlew.bat signingReport
Pop-Location
```

The current machine's debug signing SHA-1 is `E5:F8:24:81:6D:41:47:14:B1:F9:89:39:92:B5:E8:A0:D6:97:E7:AE`. Use it with package `com.example.wayhunter_mobile` for a debug Android key restriction. Regenerating the debug keystore or signing a release changes the certificate; rerun the signing report for that environment.

`android/settings.gradle.kts` declares Google's Secrets Gradle Plugin `2.0.1`, and the app module applies it with `propertiesFileName = "secrets.properties"` and `defaultPropertiesFileName = "local.defaults.properties"`. Both files resolve relative to the Android Gradle root. The plugin supplies `${MAPS_API_KEY}` to the manifest and generated BuildConfig constants; BuildConfig generation is enabled for compatibility. Manual `Properties` loading and a competing manifest-placeholder assignment were removed. This follows Google's [Flutter configuration guide](https://developers.google.com/maps/flutter-package/config).

The default sentinel permits a clean checkout to build but is treated as unconfigured by Android. It does not attempt to open a Google Map. The Flutter-generated AGP 9 compatibility flags and SDK-managed compile/target versions are preserved; minimum SDK stays at least 24.

## What the map demonstrates

- Actual Google Maps tiles after Android key setup.
- One approximate Jaffna Fort DEMO marker read through the Traveller mock repository from `MockData.places`.
- Initial Jaffna view from `MockData.demoCities['Jaffna']`; it is not the user's live GPS location.
- `TravellerMap` lives in `lib/features/traveller/presentation/widgets/traveller_map.dart`. Its Riverpod ViewModel keeps presentation state separate from widgets; typed domain repositories do not depend on Flutter or Google Maps types.
- Enable my location is an explicit user action handled through `geolocator`. The native location layer stays disabled until permission is granted and location services are enabled. Denied, permanently blocked, GPS-off and unsupported states keep demo browsing available; app settings are available for blocked access.
- No Directions/Routes/Places REST calls, route verification, traffic, live weather, or backend.
- A configured key boolean does not prove billing, SHA-1 restrictions, Google Play services, or network access are valid. If a configured map has blank tiles, check those settings and Android device logs. This cannot be fully validated without the developer key and a device.
- Web Maps and iOS Maps are outside Phase 1. Both currently show the safe fallback; no web key is embedded.

## Permission behavior

The manifest declares location, camera and notifications, and makes camera hardware optional. The first-time permission introduction has explicit request actions; loading it never opens a native prompt. Skipping or denying permissions keeps demo browsing available.

- Location requests use `geolocator`, return denied/blocked/GPS-off feedback, and do not start continuous tracking or fetch a GPS fix.
- Camera permission uses a small Android method channel. It does not start filming or claim genuine 360 capture. No-camera devices receive an explicit unavailable result.
- Notifications request Android 13+ runtime permission. Earlier versions inspect the app notification setting. There is no Firebase, push delivery, or notification server.
- App settings can be opened after denial. The native behavior follows Android's [runtime permission workflow](https://developer.android.com/training/permissions/requesting) and [notification permission documentation](https://developer.android.com/develop/ui/compose/notifications/notification-permission).
- `LocalDemoStorage` persists harmless flags/preferences through SharedPreferences. If plugins are unavailable, an in-memory fallback keeps the current launch usable; these fallback values do not survive restarting the app.

Device permission dialogs and configured native Maps need an Android device/emulator smoke check. Flutter widget tests use injected storage/services and do not prove native permission or map-tile behavior.

## Verification for this Maps update

- `flutter analyze`: exit 0, **No issues found! (ran in 35.7s)**.
- `flutter test`: exit 0, **30 passed**. Seven new Traveller tests cover initial Jaffna fixture data, one demo landmark, permission grant/denial/permanent denial, disabled service, missing plugins, unsupported devices, repeated taps, settings fallback and missing-key UI.
- Android debug build with Secrets Gradle Plugin: exit 0. The merged manifest receives the local key and contains both coarse and fine location permissions; key comparisons were reported only as booleans.
- Home background, Home screen and GoRouter file SHA-256 hashes match their values before this update. No routes or backend were added.
- The source scan found no literal Maps key outside ignored `android/secrets.properties`; generated ignored Android build output necessarily contains the packaged key.

The later Traveller implementation now adds the full local trip workflow inside `/traveller`; its maps also support approximate stop/member markers and explicitly labeled straight-segment demo route lines. The original Secrets Gradle Plugin configuration remains unchanged. See `TRAVELLER_IMPLEMENTATION.md` for current module verification.
