import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final devicePermissionServiceProvider = Provider<DevicePermissionService>(
  (ref) => DevicePermissionService(),
);

/// Requests are made only after an explicit tap on the permission introduction.
/// No GPS fix, camera capture, or notification delivery is started here.
class DevicePermissionService {
  static const _channel = MethodChannel('wayhunter/device');

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<String> requestLocation() async {
    if (!_isAndroid) return 'Unavailable here. Android device required.';
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return 'Blocked. Enable location in app settings, or continue with demo places.';
      }
      if (permission == LocationPermission.denied) {
        return 'Denied. Demo places remain available without live GPS.';
      }
      if (permission == LocationPermission.unableToDetermine) {
        return 'Unavailable. Continue with demo places.';
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      return enabled
          ? 'Granted. Location is used only when a feature needs it.'
          : 'Granted, but GPS is off. Demo places remain available.';
    } on MissingPluginException {
      return 'Unavailable here. Continue with demo places.';
    } on PlatformException {
      return 'Unavailable. Check device settings, or continue with demo places.';
    }
  }

  Future<String> requestCamera() => _request('requestCamera');

  Future<String> requestNotifications() => _request('requestNotifications');

  Future<String> _request(String method) async {
    if (!_isAndroid) return 'Unavailable here. Android device required.';
    try {
      return await _channel.invokeMethod<String>(method) ??
          'Unavailable. You can continue without this permission.';
    } on MissingPluginException {
      return 'Unavailable here. You can continue with the prototype.';
    } on PlatformException {
      return 'Unavailable. Check app settings, or continue without this permission.';
    }
  }

  Future<bool> openSettings() async {
    if (!_isAndroid) return false;
    try {
      return await Geolocator.openAppSettings();
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
