import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/evidence_service.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/entities/traveller_map_data.dart';
import '../../domain/entities/trip.dart';
import '../providers/traveller_providers.dart';
export '../../domain/entities/trip.dart';

class TravellerState {
  const TravellerState({
    required this.catalog,
    required this.plans,
    required this.ownerId,
    this.draft = const TripDraft(),
    this.activeId,
    this.selectedId,
    this.finishedId,
    this.tab = PlanTab.mine,
    this.progress = 0,
    this.nearby = const [],
    this.nearbyLoaded = false,
    this.category = 'All',
    this.friendFilter = FriendFilter.all,
    this.invitations = const [],
    this.alerted = const {},
    this.alternateRoute = false,
    this.safetyAlertsEnabled = true,
    this.hazards = const [],
    this.memories = const [],
    this.hazardType = 'Blocked Road',
    this.hazardDescription = '',
    this.hazardEvidence = const [],
    this.memoryCaption = '',
    this.memoryEvidence = const [],
    this.memoryTags = const {},
    this.error,
    this.message,
  });
  final TravellerCatalog catalog;
  final List<TripPlan> plans;
  final String ownerId;
  final TripDraft draft;
  final String? activeId, selectedId, finishedId, error, message;
  final PlanTab tab;
  final int progress;
  final List<TripPlace> nearby;
  final bool nearbyLoaded, alternateRoute;
  final bool safetyAlertsEnabled;
  final String category;
  final FriendFilter friendFilter;
  final List<TripInvitation> invitations;
  final Set<String> alerted;
  final List<TripHazard> hazards;
  final List<TripMemory> memories;
  final String hazardType, hazardDescription, memoryCaption;
  final List<TripEvidence> hazardEvidence, memoryEvidence;
  final Set<String> memoryTags;
  TripPlan? get active => plans
      .where((p) => p.id == activeId && p.status == TripStatus.active)
      .firstOrNull;
  TripPlan? get selected => plans.where((p) => p.id == selectedId).firstOrNull;
  TripPlan? get finished => plans.where((p) => p.id == finishedId).firstOrNull;
  List<TripPlan> get filteredPlans => plans
      .where(
        (p) => switch (tab) {
          PlanTab.mine =>
            p.ownerId == ownerId && p.status != TripStatus.completed,
          PlanTab.shared => p.ownerId != ownerId,
          PlanTab.completed =>
            p.ownerId == ownerId && p.status == TripStatus.completed,
        },
      )
      .toList();
  List<TripPlace> get filteredNearby =>
      nearby.where((p) => category == 'All' || p.category == category).toList();
  List<TripMember> get members => [
    ...catalog.members,
    ...invitations
        .where((i) => i.accepted && !catalog.members.any((m) => m.id == i.id))
        .map(
          (i) => TripMember(
            id: i.id,
            name: i.name,
            deviationMetres: 0,
            position: catalog.cities.values.first,
          ),
        ),
  ];
  List<TripMember> get filteredMembers => members
      .where(
        (m) => switch (friendFilter) {
          FriendFilter.all => true,
          FriendFilter.nearby => !m.isOffRoute,
          FriendFilter.far => m.isOffRoute,
        },
      )
      .toList();
  String get currentStop {
    final trip = active ?? finished;
    return trip == null
        ? 'No active trip'
        : trip.stops[progress.clamp(0, trip.stops.length - 1)];
  }

  MapCoordinate? positionFor(String stop) =>
      draft.customStops[stop] ??
      plans
          .map((p) => p.customStops[stop])
          .whereType<MapCoordinate>()
          .firstOrNull ??
      catalog.locations.where((p) => p.name == stop).firstOrNull?.position;
  List<MapCoordinate> pointsFor(List<String> stops) =>
      stops.map(positionFor).whereType<MapCoordinate>().toList();
  List<TripMemory> get tripMemories =>
      memories.where((m) => m.tripId == (activeId ?? finishedId)).toList();
  TravellerState copyWith({
    List<TripPlan>? plans,
    TripDraft? draft,
    String? activeId,
    String? selectedId,
    String? finishedId,
    PlanTab? tab,
    int? progress,
    List<TripPlace>? nearby,
    bool? nearbyLoaded,
    String? category,
    FriendFilter? friendFilter,
    List<TripInvitation>? invitations,
    Set<String>? alerted,
    bool? alternateRoute,
    bool? safetyAlertsEnabled,
    List<TripHazard>? hazards,
    List<TripMemory>? memories,
    String? hazardType,
    String? hazardDescription,
    List<TripEvidence>? hazardEvidence,
    String? memoryCaption,
    List<TripEvidence>? memoryEvidence,
    Set<String>? memoryTags,
    String? error,
    String? message,
  }) => TravellerState(
    catalog: catalog,
    ownerId: ownerId,
    plans: plans ?? this.plans,
    draft: draft ?? this.draft,
    activeId: activeId ?? this.activeId,
    selectedId: selectedId ?? this.selectedId,
    finishedId: finishedId ?? this.finishedId,
    tab: tab ?? this.tab,
    progress: progress ?? this.progress,
    nearby: nearby ?? this.nearby,
    nearbyLoaded: nearbyLoaded ?? this.nearbyLoaded,
    category: category ?? this.category,
    friendFilter: friendFilter ?? this.friendFilter,
    invitations: invitations ?? this.invitations,
    alerted: alerted ?? this.alerted,
    alternateRoute: alternateRoute ?? this.alternateRoute,
    safetyAlertsEnabled: safetyAlertsEnabled ?? this.safetyAlertsEnabled,
    hazards: hazards ?? this.hazards,
    memories: memories ?? this.memories,
    hazardType: hazardType ?? this.hazardType,
    hazardDescription: hazardDescription ?? this.hazardDescription,
    hazardEvidence: hazardEvidence ?? this.hazardEvidence,
    memoryCaption: memoryCaption ?? this.memoryCaption,
    memoryEvidence: memoryEvidence ?? this.memoryEvidence,
    memoryTags: memoryTags ?? this.memoryTags,
    error: error,
    message: message,
  );
}

class TravellerViewModel extends Notifier<TravellerState> {
  int _revision = 0;
  Future<void> _writes = Future.value();
  Future<void> _activityWrites = Future.value();
  @override
  TravellerState build() {
    final owner = ref.watch(authViewModelProvider.select((s) => s.user?.id));
    final repo = ref.read(travellerRepositoryProvider);
    final catalog = repo.loadCatalog();
    final seed = TravellerState(
      catalog: catalog,
      plans: catalog.plans,
      ownerId: owner ?? catalog.demoUserId,
    );
    final revision = ++_revision;
    Future.microtask(() async {
      final saved = await repo.restorePlans(seed.ownerId);
      if (ref.mounted && revision == _revision && saved != null) {
        final active = saved
            .where(
              (p) => p.status == TripStatus.active && p.ownerId == seed.ownerId,
            )
            .firstOrNull;
        state = state.copyWith(plans: saved, activeId: active?.id);
      }
    });
    // Posts and hazards are owned by the same signed-in user as the plans.
    Future.microtask(() async {
      final activity = await ref
          .read(travellerActivityStoreProvider)
          .restore(seed.ownerId);
      if (!ref.mounted || activity == null || state.ownerId != seed.ownerId) {
        return;
      }
      if (state.memories.isEmpty && state.hazards.isEmpty) {
        state = state.copyWith(
          memories: activity.memories,
          hazards: activity.hazards,
        );
      }
    });
    return seed;
  }

  Future<void> get persistenceSettled async {
    await _writes;
    await _activityWrites;
  }

  void _saveActivity() {
    final userId = state.ownerId;
    final memories = [...state.memories];
    final hazards = [...state.hazards];
    final store = ref.read(travellerActivityStoreProvider);
    _activityWrites = _activityWrites
        .then((_) => store.save(userId, memories, hazards))
        .catchError((Object _) {});
  }

  void _save() {
    _revision++;
    final plans = state.plans;
    final id = state.ownerId;
    final repo = ref.read(travellerRepositoryProvider);
    _writes = _writes.then((_) => repo.savePlans(id, plans)).catchError((_) {});
  }

  void newTrip() {
    state = state.copyWith(
      draft: const TripDraft(),
      message: 'Create a new journey. Your saved plans are unchanged.',
    );
  }

  void updateDraft(TripDraft draft) => state = state.copyWith(draft: draft);
  void setTitle(String value) =>
      updateDraft(state.draft.copyWith(title: value));
  void setDates(DateTime start, DateTime end) =>
      updateDraft(state.draft.copyWith(startDate: start, endDate: end));
  void setStartDate(DateTime date) {
    final draft = state.draft.copyWith(startDate: date);
    state = state.copyWith(
      draft: draft,
      error: draft.endDate != null && draft.endDate!.isBefore(date)
          ? 'End date must be on or after the start date.'
          : null,
    );
  }

  bool setEndDate(DateTime date) {
    final start = state.draft.startDate;
    if (start != null && date.isBefore(start)) {
      state = state.copyWith(
        error: 'End date must be on or after the start date.',
      );
      return false;
    }
    updateDraft(state.draft.copyWith(endDate: date));
    return true;
  }

  void setStartLocation(String stop) {
    final stops = [...state.draft.stops];
    if (stops.isEmpty) {
      stops.add(stop);
    } else {
      stops[0] = stop;
    }
    updateDraft(state.draft.copyWith(stops: stops));
  }

  bool setEndLocation(String stop) {
    if (state.draft.stops.isEmpty) {
      state = state.copyWith(error: 'Choose a start location first.');
      return false;
    }
    final stops = [...state.draft.stops];
    if (stops.length == 1) {
      stops.add(stop);
    } else {
      stops[stops.length - 1] = stop;
    }
    updateDraft(state.draft.copyWith(stops: stops));
    return true;
  }

  bool addIntermediateStop(String stop) {
    if (state.draft.stops.length < 2) {
      state = state.copyWith(
        error: 'Choose start and end locations before adding a stop.',
      );
      return false;
    }
    final stops = [...state.draft.stops]
      ..insert(state.draft.stops.length - 1, stop);
    updateDraft(state.draft.copyWith(stops: stops));
    return true;
  }

  String registerMapStop(MapCoordinate position) {
    final name =
        'Pin ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    updateDraft(
      state.draft.copyWith(
        customStops: {...state.draft.customStops, name: position},
      ),
    );
    return name;
  }

  void useSuggestion(TripSuggestion suggestion) {
    final d = state.draft;
    updateDraft(
      d.copyWith(
        title: d.title.trim().isEmpty ? suggestion.plan.title : d.title,
        stops: List.unmodifiable(suggestion.plan.stops),
        vehicle: suggestion.plan.vehicle,
        people: suggestion.plan.people,
        budget: suggestion.plan.budget,
        method: TripMethod.previous,
      ),
    );
  }

  void addStop(String stop) {
    updateDraft(state.draft.copyWith(stops: [...state.draft.stops, stop]));
  }

  void changeStop(int index, String value) {
    final stops = [...state.draft.stops];
    stops[index] = value;
    updateDraft(state.draft.copyWith(stops: stops));
  }

  void removeStop(int index) {
    final stops = [...state.draft.stops]..removeAt(index);
    updateDraft(state.draft.copyWith(stops: stops));
  }

  void moveStop(int index, int delta) {
    final next = index + delta;
    if (next < 0 || next >= state.draft.stops.length) return;
    final stops = [...state.draft.stops];
    final item = stops.removeAt(index);
    stops.insert(next, item);
    updateDraft(state.draft.copyWith(stops: stops));
  }

  void edit(TripPlan plan) {
    state = state.copyWith(
      draft: TripDraft.fromPlan(plan),
      selectedId: plan.id,
    );
  }

  void select(String id) => state = state.copyWith(selectedId: id);
  void setTab(PlanTab tab) => state = state.copyWith(tab: tab);
  bool saveDraft() {
    final error = state.draft.validationError;
    if (error != null) {
      state = state.copyWith(error: error);
      return false;
    }
    final d = state.draft;
    final existing = state.plans
        .where((p) => p.id == d.editingId && p.ownerId == state.ownerId)
        .firstOrNull;
    final p = TripPlan(
      id: existing?.id ?? const Uuid().v4(),
      ownerId: state.ownerId,
      title: d.title.trim(),
      stops: List.unmodifiable(d.stops),
      startDate: d.startDate!,
      endDate: d.endDate!,
      vehicle: d.vehicle,
      people: d.people,
      budget: d.budget,
      method: d.method,
      friendIds: List.unmodifiable(d.friendIds),
      customStops: Map.unmodifiable({
        for (final entry in d.customStops.entries)
          if (d.stops.contains(entry.key)) entry.key: entry.value,
      }),
      status: existing?.status ?? TripStatus.planned,
    );
    state = state.copyWith(
      plans: [...state.plans.where((q) => q.id != p.id), p],
      selectedId: p.id,
      tab: p.status == TripStatus.completed ? PlanTab.completed : PlanTab.mine,
      message: 'Trip saved locally.',
    );
    _save();
    return true;
  }

  bool generateAi() {
    final base = state.catalog.plans.first;
    final d = state.draft;
    if (d.startDate != null &&
        d.endDate != null &&
        d.endDate!.isBefore(d.startDate!)) {
      state = state.copyWith(
        error: 'End date must be on or after the start date.',
      );
      return false;
    }
    final start = d.startDate ?? DateTime.now();
    updateDraft(
      d.copyWith(
        title: d.title.isEmpty ? '${base.title} · AI plan' : d.title,
        stops: d.stops.length >= 2
            ? d.stops
            : [...d.stops, ...base.stops.where((s) => !d.stops.contains(s))],
        startDate: start,
        endDate: d.endDate ?? start.add(Duration(days: base.days - 1)),
        vehicle: d.vehicle,
        people: d.people,
        budget: d.budget > 0 ? d.budget : base.budget,
        method: TripMethod.ai,
      ),
    );
    return true;
  }

  bool useSegments(Set<int> selected) {
    if (selected.isEmpty) {
      state = state.copyWith(error: 'Select at least one route segment.');
      return false;
    }
    final ordered = selected.toList()..sort();
    final stops = <String>[];
    for (final i in ordered) {
      final segment = state.catalog.segments[i];
      if (stops.isNotEmpty && stops.last != segment.from) {
        state = state.copyWith(
          error: 'Select connected segments in route order.',
        );
        return false;
      }
      if (stops.isEmpty) stops.add(segment.from);
      stops.add(segment.to);
    }
    final base = state.catalog.plans.last;
    final start = state.draft.startDate ?? DateTime.now();
    updateDraft(
      state.draft.copyWith(
        title: state.draft.title.isEmpty ? base.title : state.draft.title,
        stops: stops,
        startDate: start,
        endDate:
            state.draft.endDate ?? start.add(Duration(days: stops.length - 1)),
        budget: state.draft.budget > 0 ? state.draft.budget : base.budget,
        method: TripMethod.previous,
      ),
    );
    return true;
  }

  // A user may switch between demo trips only after explicit confirmation
  // from the My Plans screen. Switching keeps the previous trip as Planned.
  bool start(String id, {bool switchActive = false}) {
    if (state.activeId == id && state.active != null) {
      state = state.copyWith(selectedId: id);
      return true;
    }
    final p = state.plans
        .where(
          (q) =>
              q.id == id &&
              q.ownerId == state.ownerId &&
              q.status != TripStatus.completed,
        )
        .firstOrNull;
    if (p == null) {
      state = state.copyWith(error: 'Reuse a shared plan before starting it.');
      return false;
    }
    final current = state.active;
    if (current != null && current.id != id && !switchActive) {
      state = state.copyWith(
        error:
            'Another trip is active: ${current.title}. '
            'Resume it or choose Switch Trip to start this plan.',
      );
      return false;
    }
    state = state.copyWith(
      // The previous active journey is paused, not deleted, when switching.
      plans: state.plans.map((q) {
        if (q.id == id) return q.copyWith(status: TripStatus.active);
        if (current != null && q.id == current.id && switchActive) {
          return q.copyWith(status: TripStatus.planned);
        }
        return q;
      }).toList(),
      activeId: id,
      selectedId: id,
      progress: 0,
      nearby: [],
      nearbyLoaded: false,
      alternateRoute: false,
      message: 'Journey started. Progress and route are DEMO.',
    );
    _save();
    return true;
  }

  void nextStop() {
    final trip = state.active;
    if (trip == null) return;
    state = state.copyWith(
      progress: (state.progress + 1).clamp(0, trip.stops.length - 1),
      message: 'Demo progress advanced to the next stop.',
    );
  }

  void loadNearby() {
    if (state.active == null) return;
    state = state.copyWith(
      nearby: ref.read(travellerRepositoryProvider).findNearby(),
      nearbyLoaded: true,
    );
  }

  void category(String value) => state = state.copyWith(category: value);
  void alternativeRoute() => state = state.copyWith(
    alternateRoute: !state.alternateRoute,
    message: 'Estimated alternative route demonstration selected; not verified road directions.',
  );
  void hazardDraft({String? type, String? description}) =>
      state = state.copyWith(hazardType: type, hazardDescription: description);
  TripEvidence _evidence(CapturedEvidence e) => TripEvidence(
    id: const Uuid().v4(),
    path: e.path,
    bytes: e.bytes,
    demo: e.demo,
    video: e.video,
  );
  void addEvidence(CapturedEvidence e, {required bool memory}) {
    if (memory) {
      state = state.copyWith(
        memoryEvidence: [...state.memoryEvidence, _evidence(e)],
      );
    } else if (state.hazardEvidence.length < 5) {
      state = state.copyWith(
        hazardEvidence: [...state.hazardEvidence, _evidence(e)],
      );
    } else {
      state = state.copyWith(error: 'Attach at most 5 hazard items.');
    }
  }

  void removeEvidence(String id, {required bool memory}) => state = memory
      ? state.copyWith(
          memoryEvidence: state.memoryEvidence
              .where((e) => e.id != id)
              .toList(),
        )
      : state.copyWith(
          hazardEvidence: state.hazardEvidence
              .where((e) => e.id != id)
              .toList(),
        );
  bool submitHazard() {
    if (state.active == null) return false;
    if (state.hazardDescription.trim().isEmpty ||
        state.hazardEvidence.isEmpty) {
      state = state.copyWith(
        error: 'Describe the hazard and attach photo/video evidence or labeled DEMO evidence.',
      );
      return false;
    }
    state = state.copyWith(
      hazards: [
        ...state.hazards,
        TripHazard(
          id: const Uuid().v4(),
          tripId: state.activeId!,
          type: state.hazardType,
          description: state.hazardDescription.trim(),
          stop: state.currentStop,
          evidence: state.hazardEvidence,
        ),
      ],
      hazardDescription: '',
      hazardEvidence: [],
      message: 'Hazard saved locally; no live safety warning was sent.',
    );
    _saveActivity();
    return true;
  }

  void caption(String value) => state = state.copyWith(memoryCaption: value);
  void tag(String tag) {
    final tags = {...state.memoryTags};
    if (!tags.add(tag)) tags.remove(tag);
    state = state.copyWith(memoryTags: tags);
  }

  bool postMemory() {
    if (state.active == null) return false;
    if (state.memoryCaption.trim().isEmpty || state.memoryEvidence.isEmpty) {
      state = state.copyWith(
        error: 'Add a caption and at least one photo/video or DEMO attachment.',
      );
      return false;
    }
    state = state.copyWith(
      memories: [
        ...state.memories,
        TripMemory(
          id: const Uuid().v4(),
          tripId: state.activeId!,
          caption: state.memoryCaption.trim(),
          stop: state.currentStop,
          evidence: state.memoryEvidence,
          tags: state.memoryTags,
        ),
      ],
      memoryCaption: '',
      memoryEvidence: [],
      memoryTags: {},
      message: 'Memory added to this trip.',
    );
    _saveActivity();
    return true;
  }

  void friendFilter(FriendFilter value) =>
      state = state.copyWith(friendFilter: value);
  void safetyAlerts(bool value) =>
      state = state.copyWith(safetyAlertsEnabled: value);
  void alert(String id) {
    if (!state.safetyAlertsEnabled) return;
    state = state.copyWith(
      alerted: {...state.alerted, id},
      message: 'DEMO check-in alert recorded locally. No message was sent.',
    );
  }

  bool invite(String name) {
    if (name.trim().length < 2) {
      state = state.copyWith(error: 'Enter a friend name.');
      return false;
    }
    if (state.invitations.any(
      (i) => i.name.toLowerCase() == name.trim().toLowerCase(),
    )) {
      state = state.copyWith(error: 'That friend already has an invitation.');
      return false;
    }
    state = state.copyWith(
      invitations: [
        ...state.invitations,
        TripInvitation(id: const Uuid().v4(), name: name.trim()),
      ],
      message: 'Local demo invitation created.',
    );
    return true;
  }

  void accept(String id) => state = state.copyWith(
    invitations: state.invitations
        .map((i) => i.id == id ? i.accept() : i)
        .toList(),
    message: 'Invitation accepted in this local demo.',
  );
  bool finish() {
    final trip = state.active;
    if (trip == null) return false;
    state = state.copyWith(
      plans: state.plans
          .map(
            (p) =>
                p.id == trip.id ? p.copyWith(status: TripStatus.completed) : p,
          )
          .toList(),
      finishedId: trip.id,
      tab: PlanTab.completed,
      message: 'Trip completed and saved to Completed.',
    );
    _save();
    return true;
  }
}

final travellerViewModelProvider =
    NotifierProvider<TravellerViewModel, TravellerState>(
      TravellerViewModel.new,
    );
