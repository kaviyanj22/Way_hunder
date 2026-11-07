import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Harmless local prototype preferences. Do not store passwords or API keys.
abstract class LocalDemoStorage {
  Future<bool?> readBool(String key);
  Future<String?> readString(String key);
  Future<void> writeBool(String key, bool value);
  Future<void> writeString(String key, String value);
  Future<void> remove(String key);
}

final localDemoStorageProvider = Provider<LocalDemoStorage>(
  (ref) => SharedPreferencesDemoStorage(),
);

class MemoryDemoStorage implements LocalDemoStorage {
  final Map<String, Object> _values = {};

  @override
  Future<bool?> readBool(String key) async => _values[key] as bool?;

  @override
  Future<String?> readString(String key) async => _values[key] as String?;

  @override
  Future<void> writeBool(String key, bool value) async {
    _values[key] = value;
  }

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

/// Keeps this launch usable when a native plugin is unavailable (e.g. previews).
/// In that case preferences last for this launch only.
class SharedPreferencesDemoStorage implements LocalDemoStorage {
  final MemoryDemoStorage _fallback = MemoryDemoStorage();

  Future<SharedPreferences?> _preferences() async {
    try {
      return await SharedPreferences.getInstance();
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<bool?> readBool(String key) async =>
      (await _preferences())?.getBool(key) ?? await _fallback.readBool(key);

  @override
  Future<String?> readString(String key) async =>
      (await _preferences())?.getString(key) ?? await _fallback.readString(key);

  @override
  Future<void> writeBool(String key, bool value) async {
    await _fallback.writeBool(key, value);
    try {
      await (await _preferences())?.setBool(key, value);
    } on MissingPluginException {
      // The in-memory preference remains available for this launch.
    } on PlatformException {
      // The in-memory preference remains available for this launch.
    }
  }

  @override
  Future<void> writeString(String key, String value) async {
    await _fallback.writeString(key, value);
    try {
      await (await _preferences())?.setString(key, value);
    } on MissingPluginException {
      // The in-memory preference remains available for this launch.
    } on PlatformException {
      // The in-memory preference remains available for this launch.
    }
  }

  @override
  Future<void> remove(String key) async {
    await _fallback.remove(key);
    try {
      await (await _preferences())?.remove(key);
    } on MissingPluginException {
      // Nothing is sent to any server.
    } on PlatformException {
      // Nothing is sent to any server.
    }
  }
}
