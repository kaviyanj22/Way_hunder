import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock/mock_data.dart';

enum MapsAvailability { configured, missingKey, unsupported }

class DemoMapPlace {
  const DemoMapPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;

  factory DemoMapPlace.fromFixture(Map<String, Object?> value) => DemoMapPlace(
    id: value['id']! as String,
    name: value['name']! as String,
    latitude: (value['lat']! as num).toDouble(),
    longitude: (value['lng']! as num).toDouble(),
  );
}

class DemoMapCity {
  const DemoMapCity(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}

/// Reads only a configuration boolean from Android. The API key stays native.
class MapsService {
  static const _channel = MethodChannel('wayhunter/device');

  List<DemoMapPlace> get places =>
      List.unmodifiable(MockData.places.map(DemoMapPlace.fromFixture));

  DemoMapCity get initialCity {
    final city = MockData.demoCities.entries.first;
    return DemoMapCity(city.key, city.value['lat']!, city.value['lng']!);
  }

  Future<bool> isConfigured() async =>
      await availability() == MapsAvailability.configured;

  Future<MapsAvailability> availability() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return MapsAvailability.unsupported;
    }
    try {
      final configured =
          await _channel.invokeMethod<bool>('mapsConfigured') ?? false;
      return configured
          ? MapsAvailability.configured
          : MapsAvailability.missingKey;
    } on MissingPluginException {
      return MapsAvailability.unsupported;
    } on PlatformException {
      return MapsAvailability.missingKey;
    }
  }
}

final mapsServiceProvider = Provider<MapsService>((ref) => MapsService());

final mapsAvailabilityProvider = FutureProvider<MapsAvailability>(
  (ref) => ref.watch(mapsServiceProvider).availability(),
);
