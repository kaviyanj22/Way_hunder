import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../viewmodels/game_view_model.dart';
import 'game_ui.dart';

/// Play Game district selector. Existing create-game and game-play routes are
/// untouched. A GPS point is resolved against Sri Lanka's district boundaries.
/// If location permission, network, or district lookup fails, selection is
/// manual; it never pretends the user's district is Jaffna.
class GameCurrentDistrictScreen extends ConsumerStatefulWidget {
  const GameCurrentDistrictScreen({super.key});

  @override
  ConsumerState<GameCurrentDistrictScreen> createState() =>
      _GameCurrentDistrictScreenState();
}

class _GameCurrentDistrictScreenState
    extends ConsumerState<GameCurrentDistrictScreen> {
  String? _selectedDistrict;
  String? _detectedDistrict;
  LatLng? _position;
  bool _busy = false;
  bool _manualChoice = false;
  String _message = 'Checking whether location access is already allowed...';

  @override
  void initState() {
    super.initState();
    // Silently use GPS only if the user has already granted permission.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _detectDistrict(requestPermission: false);
    });
  }

  static String _canonical(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'\bdistrict\b'), '')
      .replaceAll(RegExp(r'[^a-z]'), '');

  String? _matchDistrict(String name, List<String> districts) {
    final aliases = <String, String>{
      'moneragala': 'Monaragala',
      'kegalla': 'Kegalle',
      'kilinochchi': 'Kilinochchi',
      'killinochchi': 'Kilinochchi',
      'mullaitivu': 'Mullaitivu',
    };
    final normalized = _canonical(name);
    final target = _canonical(aliases[normalized] ?? name);
    for (final district in districts) {
      if (_canonical(district) == target) return district;
    }
    return null;
  }

  Future<String?> _districtForPosition(
    Position position,
    List<String> districts,
  ) async {
    // District Boundary, Sri Lanka National Spatial Data Infrastructure.
    // No third-party advertising or tracking endpoint is used.
    final uri = Uri.https(
      'www.gisapps.nsdi.gov.lk',
      '/server/rest/services/Srilanka/Boundaries/MapServer/3/query',
      <String, String>{
        'f': 'json',
        'geometry': '${position.longitude},${position.latitude}',
        'geometryType': 'esriGeometryPoint',
        'inSR': '4326',
        'spatialRel': 'esriSpatialRelIntersects',
        'outFields': 'district_name',
        'returnGeometry': 'false',
        'where': '1=1',
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return null;
    final features = data['features'];
    if (features is! List || features.isEmpty) return null;
    final first = features.first;
    if (first is! Map || first['attributes'] is! Map) return null;
    final attrs = first['attributes'] as Map;
    final raw = attrs['district_name'] ?? attrs['District_Name'];
    if (raw is! String) return null;
    return _matchDistrict(raw, districts);
  }

  Future<void> _detectDistrict({required bool requestPermission}) async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _message = 'Detecting your current district...';
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError(
          'Turn on GPS / Location services, or select a district below.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      // Some web browsers cannot report permission state. The user-initiated
      // button may still request a position through the browser prompt.
      if (permission == LocationPermission.deniedForever ||
          (permission == LocationPermission.denied && !requestPermission)) {
        throw StateError(
          'Tap Use My Location to allow GPS, or choose manually.',
        );
      }
      if (permission == LocationPermission.denied) {
        throw StateError(
          'Location permission denied. Choose a district manually.',
        );
      }
      if (permission == LocationPermission.unableToDetermine &&
          !requestPermission) {
        throw StateError('Tap Use My Location to detect your district.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      final current = LatLng(position.latitude, position.longitude);
      setState(() => _position = current);
      // A location outside Sri Lanka should never be mapped to a random
      // district by a cached/default selection.
      if (position.latitude < 5.8 ||
          position.latitude > 10.0 ||
          position.longitude < 79.3 ||
          position.longitude > 82.0) {
        throw StateError(
          'Your device is outside Sri Lanka. Select a district manually.',
        );
      }
      final districts = ref.read(gameViewModelProvider).seed.districts;
      final detected = await _districtForPosition(position, districts);
      if (!mounted) return;
      if (detected == null) {
        throw StateError(
          'District lookup unavailable. Select a district manually.',
        );
      }
      setState(() {
        _detectedDistrict = detected;
        _message = 'Current district detected from your GPS location.';
        // Do not override a selection that was manually changed meanwhile.
        if (!_manualChoice || requestPermission) {
          _selectedDistrict = detected;
          _manualChoice = false;
        }
      });
      if (!_manualChoice) {
        ref.read(gameViewModelProvider.notifier).selectDistrict(detected);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error is StateError
            ? error.message.toString()
            : 'Could not detect district. Please choose from the dropdown.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameViewModelProvider);
    final allDistricts = [...state.seed.districts]..sort();
    if (_detectedDistrict != null) {
      allDistricts.remove(_detectedDistrict);
      allDistricts.insert(0, _detectedDistrict!);
    }
    return GameShell(
      title: 'Select District',
      subtitle: 'Step 2 of 8 · Current district first',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GamePageSection(
            title: 'Current Location',
            color: gameCyan,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location, color: gameCyan, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _detectedDistrict ?? 'District not detected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _message,
                            style: const TextStyle(
                              color: Color(0xFFD0E2EB),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GameAction(
                  text: _busy ? 'Detecting...' : 'Use My Location / Refresh',
                  icon: Icons.gps_fixed,
                  outline: true,
                  color: gameCyan,
                  onTap: _busy
                      ? null
                      : () => _detectDistrict(requestPermission: true),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Location is optional. When GPS lookup runs, approximate '
                  'coordinates are sent to Sri Lanka NSDI to identify the '
                  'district. You can choose any district manually.',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
          GamePageSection(
            title: 'Sri Lanka Map',
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 205,
                    child: GoogleMap(
                      key: ValueKey(
                        _position == null
                            ? 'sri-lanka-map'
                            : '${_position!.latitude}:${_position!.longitude}',
                      ),
                      initialCameraPosition: CameraPosition(
                        target: _position ?? const LatLng(7.8700, 80.7700),
                        zoom: _position == null ? 6.8 : 11.0,
                      ),
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      markers: _position == null
                          ? <Marker>{}
                          : <Marker>{
                              Marker(
                                markerId: const MarkerId('device-position'),
                                position: _position!,
                                infoWindow: const InfoWindow(
                                  title: 'Your location',
                                ),
                              ),
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _position == null
                      ? 'Map preview · no GPS location available yet'
                      : 'Map pin shows your device position, not a hidden game location.',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          GamePageSection(
            title: 'Choose District',
            color: gamePurple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your current district is preselected when detected. '
                  'Tap below and scroll to choose another district.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'district-dropdown-${_selectedDistrict ?? 'none'}',
                  ),
                  initialValue: _selectedDistrict,
                  isExpanded: true,
                  menuMaxHeight: 280,
                  dropdownColor: const Color(0xFF062838),
                  hint: const Text(
                    'Select a district',
                    style: TextStyle(color: Colors.white70),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.location_city,
                      color: gameCyan,
                    ),
                    filled: true,
                    fillColor: const Color(0xAA064051),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  items: [
                    for (final district in allDistricts)
                      DropdownMenuItem<String>(
                        value: district,
                        child: Text(
                          district == _detectedDistrict
                              ? '$district (Current)'
                              : district,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (district) {
                    if (district == null) return;
                    setState(() {
                      _selectedDistrict = district;
                      _manualChoice = district != _detectedDistrict;
                    });
                    ref
                        .read(gameViewModelProvider.notifier)
                        .selectDistrict(district);
                  },
                ),
              ],
            ),
          ),
          GameAction(
            text: 'View District Challenges',
            color: gameGreen,
            onTap: _selectedDistrict == null
                ? null
                : () {
                    ref
                        .read(gameViewModelProvider.notifier)
                        .selectDistrict(_selectedDistrict!);
                    context.push('/game/challenges');
                  },
          ),
        ],
      ),
    );
  }
}
