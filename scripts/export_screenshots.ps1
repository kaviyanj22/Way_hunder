param(
  [string]$Device = 'emulator-5554',
  [ValidateSet('all','remaining','auth','home','traveller','hunter','games','profile','wallet')]
  [string]$Module = 'all',
  [string]$OnlyFiles = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$adbPath = Join-Path $sdkRoot 'platform-tools\adb.exe'
if (-not (Test-Path -LiteralPath $adbPath)) { throw "Android adb not found: $adbPath" }
$env:WAYHUNTER_ADB = $adbPath
$env:WAYHUNTER_DEVICE = $Device
$previousCaptureFlag = $env:WAYHUNTER_SCREENSHOT_EXPORT
$env:WAYHUNTER_SCREENSHOT_EXPORT = 'true'
$oldSize = & $adbPath -s $Device shell wm size
$oldDensity = & $adbPath -s $Device shell wm density
$oldOverrideSize = ($oldSize | Select-String 'Override size: (\d+x\d+)').Matches.Groups
$oldOverrideDensity = ($oldDensity | Select-String 'Override density: (\d+)').Matches.Groups
$restoreSize = if ($oldOverrideSize) { $oldOverrideSize[1].Value } else { 'reset' }
$restoreDensity = if ($oldOverrideDensity) { $oldOverrideDensity[1].Value } else { 'reset' }
New-Item -ItemType Directory -Path 'screenshots' -Force | Out-Null
try {
  & $adbPath -s $Device shell wm size 390x844
  & $adbPath -s $Device shell wm density 160
  & $adbPath -s $Device shell input keyevent KEYCODE_WAKEUP
  # flutter drive normally uninstalls its app at completion. Keep it installed
  # and grant permissions before launch, even on a clean emulator.
  $debugApk = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-debug.apk'
  if (-not (Test-Path -LiteralPath $debugApk)) {
    flutter build apk --debug --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Could not prepare the Android debug APK.' }
  }
  & $adbPath -s $Device install -r -t -g $debugApk
  if ($LASTEXITCODE -ne 0) { throw 'Could not install the test app.' }
  # Grant the app's declared emulator permissions without replacing native APIs.
  foreach ($permission in @('CAMERA','ACCESS_COARSE_LOCATION','ACCESS_FINE_LOCATION','POST_NOTIFICATIONS')) {
    & $adbPath -s $Device shell pm grant com.example.wayhunter_mobile "android.permission.$permission" 2>$null
  }
  $ErrorActionPreference = 'Continue'
  flutter drive --no-pub --keep-app-running --driver=test_driver/screenshots_driver.dart --target=integration_test/export_screens_test.dart -d $Device "--dart-define=SCREENSHOT_MODULE=$Module" "--dart-define=SCREENSHOT_FILES=$OnlyFiles" 2>&1 | Tee-Object -FilePath 'screenshots/export_run.log'
  $captureExit = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  if ($captureExit -ne 0) { throw "Screenshot integration run exited $captureExit. See screenshots/export_run.log and SCREEN_INDEX.md." }
} finally {
  & $adbPath -s $Device shell wm size $restoreSize
  & $adbPath -s $Device shell wm density $restoreDensity
  $env:WAYHUNTER_SCREENSHOT_EXPORT = $previousCaptureFlag
}
