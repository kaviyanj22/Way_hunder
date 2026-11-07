import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/traveller_map_data.dart';
import '../../domain/repositories/traveller_map_repository.dart';

/// A small native boundary, injectable without starting GPS or a platform map.
abstract interface class TravellerLocationGateway {
  Future<bool> isServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<bool> openAppSettings();
}

class GeolocatorLocationGateway implements TravellerLocationGateway {
  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();
  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();
  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();
  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

class GeolocatorTravellerLocationRepository
    implements TravellerLocationRepository {
  GeolocatorTravellerLocationRepository({
    TravellerLocationGateway? gateway,
    bool? supported,
  }) : _gateway = gateway ?? GeolocatorLocationGateway(),
       _supported =
           supported ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final TravellerLocationGateway _gateway;
  final bool _supported;

  @override
  Future<TravellerLocationAccess> requestAccess() async {
    if (!_supported) return TravellerLocationAccess.unavailable;
    try {
      if (!await _gateway.isServiceEnabled()) {
        return TravellerLocationAccess.serviceDisabled;
      }
      var permission = await _gateway.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _gateway.requestPermission();
      }
      return switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => TravellerLocationAccess.granted,
        LocationPermission.denied => TravellerLocationAccess.denied,
        LocationPermission.deniedForever =>
          TravellerLocationAccess.deniedForever,
        LocationPermission.unableToDetermine =>
          TravellerLocationAccess.unavailable,
      };
    } on MissingPluginException {
      return TravellerLocationAccess.unavailable;
    } on PlatformException {
      return TravellerLocationAccess.unavailable;
    } on PermissionDefinitionsNotFoundException {
      return TravellerLocationAccess.unavailable;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    if (!_supported) return false;
    try {
      return await _gateway.openAppSettings();
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
