class MapCoordinate {
  const MapCoordinate({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
}

class TravellerMapMarker {
  const TravellerMapMarker({
    required this.id,
    required this.name,
    required this.position,
  });
  final String id;
  final String name;
  final MapCoordinate position;
}

class TravellerMapData {
  const TravellerMapData({required this.center, required this.marker});
  final MapCoordinate center;
  final TravellerMapMarker marker;
}

enum TravellerLocationAccess {
  notRequested,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
}
