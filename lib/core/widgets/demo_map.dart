import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/maps_service.dart';
import '../theme/wayhunter_palette.dart';
import 'glass_panel.dart';

/// An actual Google Map when Android is configured, otherwise an honest panel.
/// Pins are local sample content. This does not request location or directions.
class DemoMap extends ConsumerWidget {
  const DemoMap({super.key, this.height = 260});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(mapsAvailabilityProvider);
    return availability.when(
      loading: () => SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => _fallback(
        ref,
        'Map unavailable',
        'Continue exploring the prototype. Google Maps needs a configured Android device.',
      ),
      data: (status) {
        if (status != MapsAvailability.configured) {
          return _fallback(
            ref,
            status == MapsAvailability.unsupported
                ? 'Android map preview'
                : 'Google Maps needs setup',
            status == MapsAvailability.unsupported
                ? 'Live map tiles are available on a configured Android device. The prototype remains usable here.'
                : 'A restricted Maps SDK key has not been configured. The prototype remains usable without map tiles.',
          );
        }
        final service = ref.watch(mapsServiceProvider);
        final city = service.initialCity;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: height,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(city.latitude, city.longitude),
                    zoom: 11,
                  ),
                  markers: service.places
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
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  zoomControlsEnabled: true,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'DEMO pins · no live GPS or road directions',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _fallback(WidgetRef ref, String title, String description) =>
      GlassPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 38,
              color: WayhunterPalette.travellerCyan,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              'DEMO places · no live GPS or route verification',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            TextButton.icon(
              onPressed: () => ref.invalidate(mapsAvailabilityProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Check map availability'),
            ),
          ],
        ),
      );
}
