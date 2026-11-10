import 'dart:convert';

import '../../../../core/mock/mock_data.dart';
import '../../../../core/storage/local_demo_storage.dart';
import '../../domain/entities/traveller_map_data.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/traveller_repository.dart';

class MockTravellerRepository implements TravellerRepository {
  MockTravellerRepository(this.storage);
  final LocalDemoStorage storage;
  @override
  TravellerCatalog loadCatalog() {
    final cities = MockData.demoCities.map(
      (name, value) => MapEntry(
        name,
        MapCoordinate(latitude: value['lat']!, longitude: value['lng']!),
      ),
    );
    final anchor = cities['Jaffna']!;
    final alert = MockData.hazardReports.first;
    final plans = MockData.tripPlans.map(_decodePlan).toList(growable: false);
    return TravellerCatalog(
      demoUserId: MockData.currentUser['id']! as String,
      plans: plans,
      vehicles: MockData.tripVehicles,
      budgetOptions: MockData.tripBudgetOptions,
      suggestions: MockData.tripSuggestions
          .map(
            (idea) => TripSuggestion(
              id: idea['id']!,
              author: idea['author']!,
              thumbnailAsset: idea['thumbnailAsset']!,
              avatarAsset: idea['avatarAsset'],
              plan: plans
                  .firstWhere((p) => p.id == idea['tripId'])
                  .copyWith(title: idea['title']),
            ),
          )
          .toList(growable: false),
      locations: [
        for (final city in cities.entries)
          TripPlace(
            id: 'city-${city.key}',
            name: city.key,
            category: 'City',
            district: city.key,
            position: city.value,
            description: '',
          ),
        for (final p in MockData.places)
          TripPlace(
            id: p['id']! as String,
            name: p['name']! as String,
            category: p['category']! as String,
            district: p['district']! as String,
            position: MapCoordinate(
              latitude: (p['lat']! as num).toDouble(),
              longitude: (p['lng']! as num).toDouble(),
            ),
            description: p['description']! as String,
          ),
      ],
      cities: Map.unmodifiable(cities),
      segments: MockData.previousRouteSegments
          .map(
            (s) => PreviousRouteSegment(
              from: s['from']! as String,
              to: s['to']! as String,
              sourceTripId: s['sourceTripId']! as String,
              distanceKm: (s['estimatedDistanceKm']! as num).toDouble(),
            ),
          )
          .toList(growable: false),
      members: MockData.groupMembers
          .map(
            (m) => TripMember(
              id: m['userId']! as String,
              name: m['name']! as String,
              deviationMetres: m['deviationMetres']! as int,
              position: MapCoordinate(
                latitude: (m['lat'] as num?)?.toDouble() ?? anchor.latitude,
                longitude: (m['lng'] as num?)?.toDouble() ?? anchor.longitude,
              ),
            ),
          )
          .toList(growable: false),
      roadAlertType: alert['type']! as String,
      roadAlertDescription: alert['description']! as String,
    );
  }

  @override
  List<TripPlace> findNearby() => MockData.nearbyPlaces
      .map(
        (p) => TripPlace(
          id: p['id']! as String,
          name: p['name']! as String,
          category: p['category']! as String,
          district: p['district']! as String,
          position: MapCoordinate(
            latitude: (p['lat']! as num).toDouble(),
            longitude: (p['lng']! as num).toDouble(),
          ),
          description:
              '${p['distanceKm']} km away · local DEMO suggestion, not live nearby search.',
        ),
      )
      .toList(growable: false);
  TripPlan _decodePlan(Map<String, Object?> value) {
    final now = DateTime.now();
    return TripPlan(
      id: value['id']! as String,
      ownerId: value['ownerId']! as String,
      title: value['title']! as String,
      stops: (value['stops']! as List).cast<String>().toList(growable: false),
      friendIds: List<String>.from(value['friendIds'] as List? ?? const []),
      startDate:
          DateTime.tryParse(value['startDate'] as String? ?? '') ??
          DateTime(now.year, now.month, now.day),
      endDate:
          DateTime.tryParse(value['endDate'] as String? ?? '') ??
          DateTime(now.year, now.month, now.day),
      vehicle: value['vehicle']! as String,
      people: value['people']! as int,
      budget: ((value['budgetLkr'] ?? value['budget'])! as num).toDouble(),
      status: switch (value['status']) {
        'Completed' => TripStatus.completed,
        'Active' => TripStatus.active,
        _ => TripStatus.planned,
      },
      method: switch (value['planningMethod']) {
        'AI' => TripMethod.ai,
        'Previous Traveller' => TripMethod.previous,
        _ => TripMethod.manual,
      },
      customStops: {
        for (final entry in (value['customStops'] as Map? ?? {}).entries)
          entry.key as String: MapCoordinate(
            latitude: (entry.value['lat'] as num).toDouble(),
            longitude: (entry.value['lng'] as num).toDouble(),
          ),
      },
    );
  }

  Map<String, Object?> _encodePlan(TripPlan p) => {
    'id': p.id,
    'ownerId': p.ownerId,
    'title': p.title,
    'stops': p.stops,
    'friendIds': p.friendIds,
    'startDate': p.startDate.toIso8601String(),
    'endDate': p.endDate.toIso8601String(),
    'vehicle': p.vehicle,
    'people': p.people,
    'budgetLkr': p.budget,
    'customStops': {
      for (final entry in p.customStops.entries)
        entry.key: {'lat': entry.value.latitude, 'lng': entry.value.longitude},
    },
    'status': switch (p.status) {
      TripStatus.completed => 'Completed',
      TripStatus.active => 'Active',
      TripStatus.planned => 'Planned',
    },
    'planningMethod': switch (p.method) {
      TripMethod.ai => 'AI',
      TripMethod.previous => 'Previous Traveller',
      TripMethod.manual => 'Manual',
    },
  };
  @override
  Future<List<TripPlan>?> restorePlans(String userId) async {
    final raw = await storage.readString('traveller-plans:$userId');
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .map((p) => _decodePlan(Map<String, Object?>.from(p as Map)))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlans(String userId, List<TripPlan> plans) =>
      storage.writeString(
        'traveller-plans:$userId',
        jsonEncode(plans.map(_encodePlan).toList(growable: false)),
      );
}
