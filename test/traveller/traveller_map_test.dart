import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wayhunter_mobile/core/mock/mock_data.dart';
import 'package:wayhunter_mobile/core/services/maps_service.dart';
import 'package:wayhunter_mobile/features/traveller/data/repositories/geolocator_traveller_location_repository.dart';
import 'package:wayhunter_mobile/features/traveller/data/repositories/mock_traveller_map_repository.dart';
import 'package:wayhunter_mobile/features/traveller/domain/entities/traveller_map_data.dart';
import 'package:wayhunter_mobile/features/traveller/domain/repositories/traveller_map_repository.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/viewmodels/traveller_map_view_model.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/widgets/traveller_map.dart';

class _LocationGateway implements TravellerLocationGateway {
  bool serviceEnabled = true;
  LocationPermission currentPermission = LocationPermission.denied;
  LocationPermission requestedPermission = LocationPermission.whileInUse;
  Object? failure;
  int serviceChecks = 0;
  int permissionChecks = 0;
  int permissionRequests = 0;
  @override
  Future<bool> isServiceEnabled() async {
    serviceChecks++;
    if (failure != null) throw failure!;
    return serviceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    permissionChecks++;
    return currentPermission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return requestedPermission;
  }

  @override
  Future<bool> openAppSettings() async => false;
}

class _LocationRepository implements TravellerLocationRepository {
  TravellerLocationAccess nextAccess = TravellerLocationAccess.denied;
  Completer<TravellerLocationAccess>? pending;
  int requests = 0;
  int settingsRequests = 0;
  @override
  Future<TravellerLocationAccess> requestAccess() async {
    requests++;
    return pending == null ? nextAccess : pending!.future;
  }

  @override
  Future<bool> openAppSettings() async {
    settingsRequests++;
    return false;
  }
}

void main() {
  test('initial Traveller camera and single landmark use centralized Jaffna fixtures', () {
    final map = MockTravellerMapRepository().loadInitialMap();
    final city = MockData.demoCities['Jaffna']!;
    final landmark = MockData.places.firstWhere((p) => p['id'] == 'place-001');
    expect(map.center.latitude, city['lat']);
    expect(map.center.longitude, city['lng']);
    expect(map.marker.id, landmark['id']);
    expect(map.marker.name, landmark['name']);
    expect(map.marker.position.latitude, landmark['lat']);
    expect(map.marker.position.longitude, landmark['lng']);
  });

  test('location permission is requested only when denied, and permanent denial stays blocked', () async {
    final gateway = _LocationGateway();
    final repository = GeolocatorTravellerLocationRepository(
      gateway: gateway,
      supported: true,
    );
    expect(await repository.requestAccess(), TravellerLocationAccess.granted);
    expect(gateway.permissionRequests, 1);
    gateway.currentPermission = LocationPermission.deniedForever;
    expect(
      await repository.requestAccess(),
      TravellerLocationAccess.deniedForever,
    );
    expect(gateway.permissionRequests, 1);
    gateway.currentPermission = LocationPermission.whileInUse;
    expect(await repository.requestAccess(), TravellerLocationAccess.granted);
    expect(gateway.permissionRequests, 1);
  });

  test('disabled services and unavailable native support do not trigger permission prompts', () async {
    final gateway = _LocationGateway()..serviceEnabled = false;
    final repository = GeolocatorTravellerLocationRepository(
      gateway: gateway,
      supported: true,
    );
    expect(
      await repository.requestAccess(),
      TravellerLocationAccess.serviceDisabled,
    );
    expect(gateway.permissionChecks, 0);
    expect(gateway.permissionRequests, 0);
    gateway.failure = MissingPluginException();
    expect(
      await repository.requestAccess(),
      TravellerLocationAccess.unavailable,
    );
    gateway.failure = PlatformException(code: 'unavailable');
    expect(
      await repository.requestAccess(),
      TravellerLocationAccess.unavailable,
    );
    final unsupported = GeolocatorTravellerLocationRepository(
      gateway: gateway,
      supported: false,
    );
    final checks = gateway.serviceChecks;
    expect(
      await unsupported.requestAccess(),
      TravellerLocationAccess.unavailable,
    );
    expect(await unsupported.openAppSettings(), isFalse);
    expect(gateway.serviceChecks, checks);
  });

  test('ordinary permission refusal stays denied instead of enabling the location layer', () async {
    final gateway = _LocationGateway()
      ..requestedPermission = LocationPermission.denied;
    final repository = GeolocatorTravellerLocationRepository(
      gateway: gateway,
      supported: true,
    );
    expect(await repository.requestAccess(), TravellerLocationAccess.denied);
  });

  test('view model never prompts on initialization and coalesces repeated button taps', () async {
    final location = _LocationRepository()
      ..pending = Completer<TravellerLocationAccess>();
    final container = ProviderContainer(
      overrides: [
        travellerLocationRepositoryProvider.overrideWithValue(location),
      ],
    );
    addTearDown(container.dispose);
    final initial = container.read(travellerMapViewModelProvider);
    expect(location.requests, 0);
    expect(initial.myLocationEnabled, isFalse);
    final vm = container.read(travellerMapViewModelProvider.notifier);
    final first = vm.enableMyLocation();
    final second = vm.enableMyLocation();
    expect(location.requests, 1);
    expect(container.read(travellerMapViewModelProvider).busy, isTrue);
    location.pending!.complete(TravellerLocationAccess.granted);
    await Future.wait([first, second]);
    final granted = container.read(travellerMapViewModelProvider);
    expect(granted.myLocationEnabled, isTrue);
    expect(identical(granted.map, initial.map), isTrue);
  });

  test(
    'blocked access and failed settings handoff leave the demo map usable',
    () async {
      final location = _LocationRepository()
        ..nextAccess = TravellerLocationAccess.deniedForever;
      final container = ProviderContainer(
        overrides: [
          travellerLocationRepositoryProvider.overrideWithValue(location),
        ],
      );
      addTearDown(container.dispose);
      final vm = container.read(travellerMapViewModelProvider.notifier);
      await vm.enableMyLocation();
      expect(
        container.read(travellerMapViewModelProvider).canOpenSettings,
        isTrue,
      );
      expect(
        container.read(travellerMapViewModelProvider).myLocationEnabled,
        isFalse,
      );
      await vm.openSettings();
      expect(location.settingsRequests, 1);
      expect(
        container.read(travellerMapViewModelProvider).settingsMessage,
        contains('could not be opened'),
      );
    },
  );

  testWidgets(
    'missing key shows Jaffna demo and only an explicit tap requests location',
    (tester) async {
      final location = _LocationRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mapsAvailabilityProvider.overrideWith(
              (ref) async => MapsAvailability.missingKey,
            ),
            travellerLocationRepositoryProvider.overrideWithValue(location),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: TravellerMap())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GoogleMap), findsNothing);
      expect(find.text('Google Maps needs setup'), findsOneWidget);
      expect(find.textContaining('Jaffna'), findsWidgets);
      expect(location.requests, 0);
      await tester.ensureVisible(
        find.byKey(const ValueKey('traveller-enable-location')),
      );
      await tester.tap(find.byKey(const ValueKey('traveller-enable-location')));
      await tester.pumpAndSettle();
      expect(location.requests, 1);
      expect(find.textContaining('permission denied'), findsOneWidget);
      expect(find.byType(GoogleMap), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
