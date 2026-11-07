import '../../../../core/mock/mock_data.dart';
import '../../domain/entities/traveller_map_data.dart';
import '../../domain/repositories/traveller_map_repository.dart';

/// Application coordinates and landmark data come only from MockData.
class MockTravellerMapRepository implements TravellerMapRepository {
  @override
  TravellerMapData loadInitialMap() {
    final city = MockData.demoCities['Jaffna']!;
    final landmark = MockData.places.firstWhere(
      (place) => place['id'] == 'place-001',
    );
    return TravellerMapData(
      center: MapCoordinate(latitude: city['lat']!, longitude: city['lng']!),
      marker: TravellerMapMarker(
        id: landmark['id']! as String,
        name: landmark['name']! as String,
        position: MapCoordinate(
          latitude: (landmark['lat']! as num).toDouble(),
          longitude: (landmark['lng']! as num).toDouble(),
        ),
      ),
    );
  }
}
