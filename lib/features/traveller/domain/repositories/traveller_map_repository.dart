import '../entities/traveller_map_data.dart';

abstract interface class TravellerMapRepository {
  TravellerMapData loadInitialMap();
}

abstract interface class TravellerLocationRepository {
  Future<TravellerLocationAccess> requestAccess();
  Future<bool> openAppSettings();
}
