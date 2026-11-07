import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/mock/mock_data.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/theme/wayhunter_palette.dart';
import '../../domain/entities/traveller_map_data.dart';

/// Compact SDK map for a draft. Lines are estimates, never road directions.
class TripRouteMap extends ConsumerStatefulWidget {
  const TripRouteMap({
    super.key,
    required this.stops,
    this.onTap,
    this.pickedPoint,
  });
  final List<TravellerMapMarker> stops;
  final ValueChanged<MapCoordinate>? onTap;
  final MapCoordinate? pickedPoint;

  @override
  ConsumerState<TripRouteMap> createState() => _TripRouteMapState();
}

class _TripRouteMapState extends ConsumerState<TripRouteMap> {
  final _viewport = GlobalKey();
  GoogleMapController? _controller;
  bool _needsFit = true, _scheduled = false;

  List<LatLng> get _points => widget.stops
      .map((s) => LatLng(s.position.latitude, s.position.longitude))
      .toList();

  @override
  void didUpdateWidget(covariant TripRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.stops
        .map((s) => LatLng(s.position.latitude, s.position.longitude))
        .toList();
    if (!listEquals(previous, _points)) _needsFit = true;
  }

  void _fit() {
    if (!_needsFit || _scheduled || _controller == null) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduled = false;
      if (!mounted || !_needsFit || _controller == null) return;
      final box = _viewport.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return;
      final points = _points;
      final island = MockData.sriLankaMapBounds;
      CameraUpdate update;
      if (points.isNotEmpty && points.toSet().length == 1) {
        update = CameraUpdate.newLatLngZoom(points.first, 12);
      } else {
        final south = points.isEmpty
            ? island['south']!
            : points.map((p) => p.latitude).reduce(math.min);
        final north = points.isEmpty
            ? island['north']!
            : points.map((p) => p.latitude).reduce(math.max);
        final west = points.isEmpty
            ? island['west']!
            : points.map((p) => p.longitude).reduce(math.min);
        final east = points.isEmpty
            ? island['east']!
            : points.map((p) => p.longitude).reduce(math.max);
        update = CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(south, west),
            northeast: LatLng(north, east),
          ),
          math.min(24.0, box.size.shortestSide / 8),
        );
      }
      _needsFit = false;
      try {
        await _controller!.moveCamera(update);
      } on PlatformException {
        // Keep editing usable if the native surface is interrupted.
      } on MissingPluginException {
        // Supported previews can use the searchable mock catalog instead.
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _controller = null; // GoogleMap owns the controller lifecycle.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ref
      .watch(mapsAvailabilityProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Map unavailable')),
        data: (availability) {
          if (availability != MapsAvailability.configured) {
            return const Center(
              child: Icon(
                Icons.map_outlined,
                color: WayhunterPalette.travellerCyan,
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxHeight > 0 && constraints.maxWidth > 0) _fit();
              final points = _points;
              return Stack(
                fit: StackFit.expand,
                children: [
                  SizedBox.expand(
                    key: _viewport,
                    child: GoogleMap(
                      key: const ValueKey('trip-route-google-map'),
                      initialCameraPosition: CameraPosition(
                        target: points.isEmpty
                            ? LatLng(
                                (MockData.sriLankaMapBounds['south']! +
                                        MockData.sriLankaMapBounds['north']!) /
                                    2,
                                (MockData.sriLankaMapBounds['west']! +
                                        MockData.sriLankaMapBounds['east']!) /
                                    2,
                              )
                            : points.first,
                        zoom: 6,
                      ),
                      onMapCreated: (controller) {
                        _controller = controller;
                        _fit();
                      },
                      onTap: widget.onTap == null
                          ? null
                          : (point) => widget.onTap!(
                              MapCoordinate(
                                latitude: point.latitude,
                                longitude: point.longitude,
                              ),
                            ),
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          EagerGestureRecognizer.new,
                        ),
                      },
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      padding: const EdgeInsets.only(top: 28, bottom: 4),
                      markers: {
                        for (var i = 0; i < widget.stops.length; i++)
                          Marker(
                            markerId: MarkerId('draft-stop-$i'),
                            position: points[i],
                            onTap: widget.onTap == null
                                ? null
                                : () => widget.onTap!(widget.stops[i].position),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              i == 0
                                  ? BitmapDescriptor.hueGreen
                                  : i == points.length - 1
                                  ? BitmapDescriptor.hueOrange
                                  : BitmapDescriptor.hueAzure,
                            ),
                            infoWindow: InfoWindow(
                              title: '${i + 1}. ${widget.stops[i].name}',
                            ),
                          ),
                        if (widget.pickedPoint case final point?)
                          Marker(
                            markerId: const MarkerId('picked-point'),
                            position: LatLng(point.latitude, point.longitude),
                            infoWindow: const InfoWindow(
                              title: 'Selected location',
                            ),
                          ),
                      },
                      polylines: points.length < 2
                          ? {}
                          : {
                              Polyline(
                                polylineId: const PolylineId(
                                  'draft-estimated-route',
                                ),
                                points: points,
                                width: 4,
                                color: WayhunterPalette.travellerCyan,
                                patterns: [
                                  PatternItem.dash(12),
                                  PatternItem.gap(6),
                                ],
                              ),
                            },
                    ),
                  ),
                  if (points.length > 1)
                    const Positioned(
                      right: 4,
                      top: 4,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xCC031420),
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            child: Text(
                              'Mock route',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      );
}
