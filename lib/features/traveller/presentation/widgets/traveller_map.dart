import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/maps_service.dart';
import '../../../../core/theme/wayhunter_palette.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../viewmodels/traveller_map_view_model.dart';
import '../../domain/entities/traveller_map_data.dart';
import 'traveller_island_map.dart';

/// Reusable Android map. Tiles are live; the single landmark is mock content.
/// It never requests location at startup or changes the existing navigation.
class TravellerMap extends ConsumerWidget {
  const TravellerMap({
    super.key,
    this.height = 260,
    this.routePoints = const [],
    this.extraMarkers = const [],
    this.alternative = false,
    this.landing = false,
    this.compact = false,
  });
  final double height;
  final List<MapCoordinate> routePoints;
  final List<TravellerMapMarker> extraMarkers;
  final bool alternative;
  final bool landing;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (landing) return const TravellerIslandMap();
    final state = ref.watch(travellerMapViewModelProvider);
    final availability = ref.watch(mapsAvailabilityProvider);
    final vm = ref.read(travellerMapViewModelProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        availability.when(
          loading: () => SizedBox(
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => compact
              ? SizedBox(
                  height: height,
                  child: const Center(child: Text('Map unavailable')),
                )
              : _fallback(
                  ref,
                  'Map unavailable',
                  'Continue using the prototype while Android Maps configuration is checked.',
                ),
          data: (status) {
            if (status != MapsAvailability.configured) {
              if (compact) {
                return SizedBox(
                  height: height,
                  child: const Center(
                    child: Text('Google Maps needs Android configuration'),
                  ),
                );
              }
              return _fallback(
                ref,
                status == MapsAvailability.missingKey
                    ? 'Google Maps needs setup'
                    : 'Android map preview',
                status == MapsAvailability.missingKey
                    ? 'A restricted Maps SDK key is not configured. The Jaffna demo remains usable without tiles.'
                    : 'Live map tiles require a configured Android device. No map key is sent through Dart.',
              );
            }
            final marker = state.map.marker;
            // Center the initial camera on the entire selected demo route,
            // rather than forcing it to the first stop (usually Jaffna).
            final initialLatitude = routePoints.isEmpty
                ? state.map.center.latitude
                : routePoints.fold<double>(0, (v, p) => v + p.latitude) /
                      routePoints.length;
            final initialLongitude = routePoints.isEmpty
                ? state.map.center.longitude
                : routePoints.fold<double>(0, (v, p) => v + p.longitude) /
                      routePoints.length;
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: height,
                child: GoogleMap(
                  key: const ValueKey('traveller-google-map'),
                  initialCameraPosition: CameraPosition(
                    target: LatLng(initialLatitude, initialLongitude),
                    zoom: routePoints.length > 1 ? 7 : 12,
                  ),
                  markers: {
                    for (var i = 0; i < routePoints.length; i++)
                      Marker(
                        markerId: MarkerId('stop-$i'),
                        position: LatLng(
                          routePoints[i].latitude,
                          routePoints[i].longitude,
                        ),
                        infoWindow: InfoWindow(title: 'Demo stop ${i + 1}'),
                      ),
                    for (final member in extraMarkers)
                      Marker(
                        markerId: MarkerId(member.id),
                        position: LatLng(
                          member.position.latitude,
                          member.position.longitude,
                        ),
                        infoWindow: InfoWindow(
                          title: member.name,
                          snippet: 'DEMO location',
                        ),
                      ),
                    Marker(
                      markerId: MarkerId(marker.id),
                      position: LatLng(
                        marker.position.latitude,
                        marker.position.longitude,
                      ),
                      infoWindow: InfoWindow(
                        title: marker.name,
                        snippet: 'DEMO landmark · approximate pin',
                      ),
                    ),
                  },
                  polylines: routePoints.length < 2
                      ? {}
                      : {
                          Polyline(
                            polylineId: const PolylineId('demo-route'),
                            points: routePoints
                                .map((p) => LatLng(p.latitude, p.longitude))
                                .toList(),
                            color: alternative
                                ? Colors.amber
                                : WayhunterPalette.travellerCyan,
                            width: 5,
                            patterns: alternative
                                ? [PatternItem.dash(20), PatternItem.gap(10)]
                                : [],
                          ),
                        },
                  myLocationEnabled: state.myLocationEnabled,
                  myLocationButtonEnabled: state.myLocationEnabled,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                ),
              ),
            );
          },
        ),
        if (!compact) const SizedBox(height: 10),
        if (!compact && routePoints.length > 1)
          const Text(
            'DEMO estimated route · straight segments, not verified road directions',
            style: TextStyle(fontSize: 11),
          ),
        if (!compact)
          Text(
            'DEMO marker: ${state.map.marker.name} · no road directions or location verification',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (!compact) const SizedBox(height: 12),
        if (!compact)
          Semantics(
            liveRegion: true,
            child: Text(
              state.locationMessage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (!compact && state.settingsMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              state.settingsMessage!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (!compact) const SizedBox(height: 10),
        if (!compact)
          OutlinedButton.icon(
            key: const ValueKey('traveller-enable-location'),
            onPressed: state.busy ? null : vm.enableMyLocation,
            icon: state.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text('Enable my location'),
          ),
        if (!compact && state.canOpenSettings)
          TextButton.icon(
            onPressed: state.busy ? null : vm.openSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Open app settings'),
          ),
      ],
    );
  }

  Widget _fallback(WidgetRef ref, String title, String description) =>
      GlassPanel(
        child: Column(
          children: [
            const Icon(
              Icons.map_outlined,
              color: WayhunterPalette.travellerCyan,
              size: 38,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: () => ref.invalidate(mapsAvailabilityProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Check map availability'),
            ),
          ],
        ),
      );
}
