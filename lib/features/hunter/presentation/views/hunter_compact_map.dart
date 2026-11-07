import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/maps_service.dart';
import 'hunter_ui.dart';

/// A compact, correctly bounded map. Unlike DemoMap, this does not append
/// a text block beneath the GoogleMap, so Hunter Home remains non-scrollable.
class HunterCompactMap extends ConsumerWidget {
  const HunterCompactMap({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(mapsAvailabilityProvider);
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: availability.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _MapFallback(label: 'Map unavailable'),
          data: (status) {
            if (status != MapsAvailability.configured) {
              return const _MapFallback(label: 'Map preview unavailable');
            }
            final maps = ref.watch(mapsServiceProvider);
            final city = maps.initialCity;
            return GoogleMap(
              key: const ValueKey('hunter-compact-google-map'),
              initialCameraPosition: CameraPosition(
                target: LatLng(city.latitude, city.longitude),
                zoom: 10.5,
              ),
              markers: maps.places
                  .map(
                    (place) => Marker(
                      markerId: MarkerId(place.id),
                      position: LatLng(place.latitude, place.longitude),
                      infoWindow: InfoWindow(
                        title: place.name,
                        snippet: 'DEMO place',
                      ),
                    ),
                  )
                  .toSet(),
              compassEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
            );
          },
        ),
      ),
    );
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xDD0D2E39),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, color: hunterGold),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}
