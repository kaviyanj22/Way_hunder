# Wayhunter Flutter Prototype -- START HERE

This folder now contains the Flutter project and Phase 1 implementation. Start with [README.md](README.md) for current run commands, demo credentials and coverage. The original pack setup instructions below are retained as background; an existing project does not need to be recreated.

## Step 1 -- Windows / PowerShell

```powershell
flutter doctor -v
flutter create --org com.wayhunter wayhunter_mobile
cd wayhunter_mobile
code .
```

If you already have the correct Wayhunter project, make a Git checkpoint and open that directory instead of creating a second project.

## Step 2 -- Unzip pack into Flutter project ROOT

Extract the pack so all of these exist:

- `your-project/AGENTS.md`
- `your-project/CODEX_MASTER_PROMPT.md`
- `your-project/lib/core/mock/mock_data.dart`
- `your-project/assets/images/buttons/traveller_button.png`
- `your-project/assets/images/buttons/hunter_button.png`
- `your-project/assets/images/buttons/game_button.png`
- `your-project/assets/images/backgrounds/home_background.png`
- `your-project/docs/flows/01_login_to_home.png` ... `06_wallet_vouchers.png`
- `your-project/docs/original_screens/` (35 original design images)
- `your-project/docs/wallet/wallet_eight_screen_reference.png`

**Do not unzip into a nested `Wayhunter_Codex_Flutter_Starter/` subfolder inside the Flutter root**; its contents should be at the project root. If unsure, locate your `pubspec.yaml` first.

## Step 3 -- Add packages (Codex can do this)

```powershell
flutter pub add flutter_riverpod go_router google_maps_flutter geolocator camera image_picker shared_preferences intl uuid
flutter pub get
```

Use only package APIs compatible with versions actually resolved. A physical Android device is preferable for GPS/camera/Maps. Android web/Chrome preview cannot prove native permission/camera flows.

## Step 4 -- Add asset folders to pubspec.yaml

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/backgrounds/
    - assets/images/buttons/
```

`docs/` images are references to read during design/build, **not** loaded as runtime Flutter image widgets. Do not include reference image directories under `flutter.assets`.

## Step 5 -- Open Codex in VS Code

Install the official Codex extension via VS Code Extensions / OpenAI Codex, sign in with your available ChatGPT account, open your Flutter project, and paste:

> Read AGENTS.md and CODEX_MASTER_PROMPT.md, inspect every image in docs/flows, docs/original_screens, docs/wallet, and the supplied assets. Implement Milestone 1 exactly as defined in the master prompt. Do not call any backend. Use mock_data.dart as the sole hardcoded data fixture source. After implementation run flutter analyze and flutter test, report remaining issues and next milestone.

Or run `codex` inside the Flutter project if the CLI is already installed.

## Step 6 -- Google Maps key (YOU must create it)

1. [Google Cloud Console](https://console.cloud.google.com/): create/select project; link billing; enable **Maps SDK for Android**. Google Maps is not necessarily free; review quotas/costs.
2. Create an API key and restrict it by Android app package name + SHA-1 and API: Maps SDK for Android. For Windows debug keystore fingerprint, PowerShell:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

3. In the app's `android/app/src/main/AndroidManifest.xml` under `<application>` the plugin expects:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}" />
```

4. Have Codex configure Gradle to read your **local ignored** `secrets.properties` and inject `MAPS_API_KEY` as a manifest placeholder. Add the actual key **only locally**, never inside the Codex prompt or a public repository. Android packaged keys still need correct application/API restrictions.
5. Also add `<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />` and `ACCESS_FINE_LOCATION` as direct children of `<manifest>` (request location at runtime). If camera used, configure camera permissions per the installed plugin docs.
6. Build and test on an Android phone/emulator with Google Play services. If there's no API key, the prototype should still render a clear no-key/fallback message.

Current Google package requirements may differ from older tutorials: let Codex inspect the chosen package version before setting `minSdk` (recent google_maps_flutter Android implementation documents API 24+).

## Step 7 -- Finish each milestone

```powershell
flutter analyze
flutter test
flutter devices
flutter run -d <YOUR_ANDROID_DEVICE_ID>
```

For each milestone, demand actual screen implementation, correct routing and tests. Use `prompts/01_foundation_auth_home.md`, then 02 traveller, 03 hunter, 04 games, 05 profile, 06 wallet, 07 final QA.

## Demo boundaries

- `mock_data.dart` is a source of sample data, not a real authentication/approval service.
- User state can be simulated via Riverpod; local SharedPreferences may remember harmless demo state across app restarts.
- Google map tiles/GPS are real if correctly configured, but markers, polylines, AI suggestions, nearby places, safety alerts, winners and voucher approvals are **simulated**.
- Never claim demo gift vouchers are redeemable at a real partner.
