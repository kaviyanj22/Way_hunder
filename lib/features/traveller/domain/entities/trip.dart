import 'dart:typed_data';

import 'traveller_map_data.dart';

enum TripStatus { planned, active, completed }

enum TripMethod { manual, ai, previous }

enum PlanTab { mine, shared, completed }

enum FriendFilter { all, nearby, far }

class TripPlan {
  const TripPlan({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.stops,
    required this.startDate,
    required this.endDate,
    required this.vehicle,
    required this.people,
    required this.budget,
    this.status = TripStatus.planned,
    this.method = TripMethod.manual,
    this.customStops = const {},
  });
  final String id, ownerId, title, vehicle;
  final List<String> stops;
  final DateTime startDate, endDate;
  final int people;
  final double budget;
  final TripStatus status;
  final TripMethod method;
  final Map<String, MapCoordinate> customStops;
  int get days => endDate.difference(startDate).inDays + 1;
  TripPlan copyWith({
    String? title,
    List<String>? stops,
    DateTime? startDate,
    DateTime? endDate,
    String? vehicle,
    int? people,
    double? budget,
    TripStatus? status,
    TripMethod? method,
    Map<String, MapCoordinate>? customStops,
  }) => TripPlan(
    id: id,
    ownerId: ownerId,
    title: title ?? this.title,
    stops: stops ?? this.stops,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    vehicle: vehicle ?? this.vehicle,
    people: people ?? this.people,
    budget: budget ?? this.budget,
    status: status ?? this.status,
    method: method ?? this.method,
    customStops: customStops ?? this.customStops,
  );
}

class TripDraft {
  const TripDraft({
    this.editingId,
    this.title = '',
    this.startDate,
    this.endDate,
    this.stops = const [],
    this.vehicle = 'Car',
    this.people = 1,
    this.budget = 0,
    this.method = TripMethod.manual,
    this.customStops = const {},
  });
  final String? editingId;
  final String title, vehicle;
  final List<String> stops;
  final DateTime? startDate, endDate;
  final int people;
  final double budget;
  final TripMethod method;
  final Map<String, MapCoordinate> customStops;
  factory TripDraft.fromPlan(TripPlan plan) => TripDraft(
    editingId: plan.id,
    title: plan.title,
    startDate: plan.startDate,
    endDate: plan.endDate,
    stops: List.unmodifiable(plan.stops),
    vehicle: plan.vehicle,
    people: plan.people,
    budget: plan.budget,
    method: plan.method,
    customStops: plan.customStops,
  );
  TripDraft copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? stops,
    String? vehicle,
    int? people,
    double? budget,
    TripMethod? method,
    Map<String, MapCoordinate>? customStops,
  }) => TripDraft(
    editingId: editingId,
    title: title ?? this.title,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    stops: stops ?? this.stops,
    vehicle: vehicle ?? this.vehicle,
    people: people ?? this.people,
    budget: budget ?? this.budget,
    method: method ?? this.method,
    customStops: customStops ?? this.customStops,
  );
  String? get validationError {
    if (title.trim().length < 3) {
      return 'Enter a trip title with at least 3 characters.';
    }
    if (startDate == null || endDate == null) {
      return 'Choose both start and end dates.';
    }
    if (endDate!.isBefore(startDate!)) {
      return 'End date must be on or after the start date.';
    }
    if (stops.length < 2) return 'Choose a start and end location.';
    for (var i = 1; i < stops.length; i++) {
      if (stops[i] == stops[i - 1]) {
        return 'Consecutive stops must be different.';
      }
    }
    if (people < 1) return 'Add at least one traveller.';
    if (vehicle.trim().isEmpty) return 'Choose a vehicle.';
    if (!budget.isFinite || budget <= 0) {
      return 'Enter a finite budget above zero.';
    }
    return null;
  }
}

class PreviousRouteSegment {
  const PreviousRouteSegment({
    required this.from,
    required this.to,
    required this.sourceTripId,
    required this.distanceKm,
  });
  final String from, to, sourceTripId;
  final double distanceKm;
}

class TripPlace {
  const TripPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.district,
    required this.position,
    required this.description,
  });
  final String id, name, category, district, description;
  final MapCoordinate position;
}

class TripMember {
  const TripMember({
    required this.id,
    required this.name,
    required this.deviationMetres,
    required this.position,
  });
  final String id, name;
  final int deviationMetres;
  final MapCoordinate position;
  bool get isOffRoute => deviationMetres > 500;
}

class TripInvitation {
  const TripInvitation({
    required this.id,
    required this.name,
    this.accepted = false,
  });
  final String id, name;
  final bool accepted;
  TripInvitation accept() => TripInvitation(id: id, name: name, accepted: true);
}

class TripEvidence {
  const TripEvidence({
    required this.id,
    this.path,
    this.bytes,
    this.demo = false,
    this.video = false,
  });
  final String id;
  final String? path;
  final Uint8List? bytes;
  final bool demo, video;
}

class TripHazard {
  const TripHazard({
    required this.id,
    required this.tripId,
    required this.type,
    required this.description,
    required this.stop,
    required this.evidence,
  });
  final String id, tripId, type, description, stop;
  final List<TripEvidence> evidence;
}

class TripMemory {
  const TripMemory({
    required this.id,
    required this.tripId,
    required this.caption,
    required this.stop,
    required this.evidence,
    required this.tags,
  });
  final String id, tripId, caption, stop;
  final List<TripEvidence> evidence;
  final Set<String> tags;
}

class TravellerCatalog {
  const TravellerCatalog({
    required this.demoUserId,
    required this.plans,
    required this.cities,
    required this.segments,
    required this.members,
    required this.roadAlertType,
    required this.roadAlertDescription,
    required this.locations,
    required this.suggestions,
    required this.vehicles,
    required this.budgetOptions,
  });
  final String demoUserId;
  final List<TripPlan> plans;
  final Map<String, MapCoordinate> cities;
  final List<PreviousRouteSegment> segments;
  final List<TripMember> members;
  final String roadAlertType, roadAlertDescription;
  final List<TripPlace> locations;
  final List<TripSuggestion> suggestions;
  final List<String> vehicles;
  final List<double> budgetOptions;
}

class TripSuggestion {
  const TripSuggestion({
    required this.id,
    required this.plan,
    required this.author,
    required this.thumbnailAsset,
    this.avatarAsset,
  });
  final String id, author, thumbnailAsset;
  final String? avatarAsset;
  final TripPlan plan;
}
