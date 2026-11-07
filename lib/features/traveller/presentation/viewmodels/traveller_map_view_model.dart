import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/geolocator_traveller_location_repository.dart';
import '../../data/repositories/mock_traveller_map_repository.dart';
import '../../domain/entities/traveller_map_data.dart';
import '../../domain/repositories/traveller_map_repository.dart';

final travellerMapRepositoryProvider = Provider<TravellerMapRepository>(
  (ref) => MockTravellerMapRepository(),
);
final travellerLocationRepositoryProvider =
    Provider<TravellerLocationRepository>(
      (ref) => GeolocatorTravellerLocationRepository(),
    );
final travellerMapViewModelProvider =
    NotifierProvider<TravellerMapViewModel, TravellerMapState>(
      TravellerMapViewModel.new,
    );

class TravellerMapState {
  const TravellerMapState({
    required this.map,
    this.locationAccess = TravellerLocationAccess.notRequested,
    this.busy = false,
    this.settingsMessage,
  });
  final TravellerMapData map;
  final TravellerLocationAccess locationAccess;
  final bool busy;
  final String? settingsMessage;
  bool get myLocationEnabled =>
      !busy && locationAccess == TravellerLocationAccess.granted;
  bool get canOpenSettings =>
      locationAccess == TravellerLocationAccess.deniedForever ||
      locationAccess == TravellerLocationAccess.serviceDisabled;

  String get locationMessage => switch (locationAccess) {
    TravellerLocationAccess.notRequested =>
      'Showing the Jaffna demo center. Your location has not been requested.',
    TravellerLocationAccess.granted => 'Location access granted. The blue dot is available on the configured map; the initial view remains Jaffna.',
    TravellerLocationAccess.denied => 'Location permission denied. You can retry or keep exploring the demo marker.',
    TravellerLocationAccess.deniedForever => 'Location permission is blocked. Enable it in app settings, then tap Enable my location again.',
    TravellerLocationAccess.serviceDisabled => 'Device location is off. Turn it on in device settings, then retry. The Jaffna demo marker remains available.',
    TravellerLocationAccess.unavailable => 'Live location is unavailable here. Use a supported Android device or keep exploring the demo marker.',
  };
}

class TravellerMapViewModel extends Notifier<TravellerMapState> {
  @override
  TravellerMapState build() => TravellerMapState(
    map: ref.watch(travellerMapRepositoryProvider).loadInitialMap(),
  );

  Future<void> enableMyLocation() async {
    if (state.busy) return;
    final map = state.map;
    state = TravellerMapState(
      map: map,
      locationAccess: state.locationAccess,
      busy: true,
    );
    TravellerLocationAccess access;
    try {
      access = await ref
          .read(travellerLocationRepositoryProvider)
          .requestAccess();
    } catch (_) {
      access = TravellerLocationAccess.unavailable;
    }
    if (!ref.mounted) return;
    state = TravellerMapState(map: map, locationAccess: access);
  }

  Future<void> openSettings() async {
    if (state.busy) return;
    final previous = state;
    state = TravellerMapState(
      map: previous.map,
      locationAccess: previous.locationAccess,
      busy: true,
    );
    var opened = false;
    try {
      opened = await ref
          .read(travellerLocationRepositoryProvider)
          .openAppSettings();
    } catch (_) {
      // The demo remains usable when the native settings surface is absent.
    }
    if (!ref.mounted) return;
    state = TravellerMapState(
      map: previous.map,
      locationAccess: previous.locationAccess,
      settingsMessage: opened
          ? 'After changing device settings, return and tap Enable my location again.'
          : 'App settings could not be opened here. Continue with the Jaffna demo map.',
    );
  }
}
