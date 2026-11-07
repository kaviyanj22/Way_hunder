import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/mock/mock_data.dart';
import '../../../../core/services/maps_service.dart';
import '../viewmodels/traveller_map_view_model.dart';

/// Map-only landing surface; other trip maps retain their existing controls.
class TravellerIslandMap extends ConsumerStatefulWidget {
  const TravellerIslandMap({super.key});

  @override
  ConsumerState<TravellerIslandMap> createState() => _TravellerIslandMapState();
}

class _TravellerIslandMapState extends ConsumerState<TravellerIslandMap> {
  final _viewportKey = GlobalKey();
  GoogleMapController? _controller;
  bool _initialFitApplied = false;
  bool _fitScheduled = false;

  LatLngBounds get _islandBounds {
    final bounds = MockData.sriLankaMapBounds;
    return LatLngBounds(
      southwest: LatLng(bounds['south']!, bounds['west']!),
      northeast: LatLng(bounds['north']!, bounds['east']!),
    );
  }

  void _scheduleInitialFit() {
    if (_controller == null || _initialFitApplied || _fitScheduled) return;
    _fitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fitScheduled = false;
      if (!mounted || _controller == null || _initialFitApplied) return;
      final viewport = _viewportKey.currentContext?.findRenderObject();
      if (viewport is! RenderBox ||
          !viewport.hasSize ||
          viewport.size.isEmpty) {
        return; // A later layout can schedule the initial fit again.
      }
      // Mark before awaiting so rebuilds and user gestures cannot refit it.
      _initialFitApplied = true;
      final padding = math.min(24.0, viewport.size.shortestSide / 10);
      try {
        await _controller!.moveCamera(
          CameraUpdate.newLatLngBounds(_islandBounds, padding),
        );
      } on PlatformException {
        // Keep the SDK surface usable if the native view is interrupted.
      } on MissingPluginException {
        // Preview platforms may not have a native controller.
      }
    });
    // Native map creation can finish between frames without scheduling a new one.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    // GoogleMap owns and disposes the controller.
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availability = ref.watch(mapsAvailabilityProvider);
    return availability.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _MapUnavailable(),
      data: (status) {
        if (status != MapsAvailability.configured) {
          return const _MapUnavailable();
        }
        final mapState = ref.watch(travellerMapViewModelProvider);
        final marker = mapState.map.marker;
        final bounds = _islandBounds;
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 0 && constraints.maxHeight > 0) {
              _scheduleInitialFit();
            }
            return SizedBox.expand(
              key: _viewportKey,
              child: GoogleMap(
                key: const ValueKey('traveller-island-google-map'),
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
                    (bounds.southwest.longitude + bounds.northeast.longitude) /
                        2,
                  ),
                  zoom: 6,
                ),
                onMapCreated: (controller) {
                  _controller = controller;
                  _initialFitApplied = false;
                  _scheduleInitialFit();
                },
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    EagerGestureRecognizer.new,
                  ),
                },
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                myLocationEnabled: mapState.myLocationEnabled,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: true,
                markers: {
                  Marker(
                    markerId: MarkerId(marker.id),
                    position: LatLng(
                      marker.position.latitude,
                      marker.position.longitude,
                    ),
                    infoWindow: InfoWindow(title: marker.name),
                  ),
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(8),
      child: Text('Map unavailable', textAlign: TextAlign.center),
    ),
  );
}
