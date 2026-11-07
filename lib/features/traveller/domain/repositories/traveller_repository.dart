import '../entities/trip.dart';

abstract interface class TravellerRepository {
  TravellerCatalog loadCatalog();
  List<TripPlace> findNearby();
  Future<List<TripPlan>?> restorePlans(String userId);
  Future<void> savePlans(String userId, List<TripPlan> plans);
}
