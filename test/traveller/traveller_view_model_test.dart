import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/core/mock/mock_data.dart';
import 'package:wayhunter_mobile/core/services/evidence_service.dart';
import 'package:wayhunter_mobile/core/storage/local_demo_storage.dart';
import 'package:wayhunter_mobile/features/traveller/data/repositories/mock_traveller_repository.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/providers/traveller_providers.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/viewmodels/traveller_view_model.dart';

class CountingRepository extends MockTravellerRepository {
  CountingRepository(super.storage);
  int lookups = 0;
  @override
  findNearby() {
    lookups++;
    return super.findNearby();
  }
}

void main() {
  late ProviderContainer container;
  late TravellerViewModel vm;
  late MemoryDemoStorage storage;
  late CountingRepository repository;
  setUp(() async {
    storage = MemoryDemoStorage();
    repository = CountingRepository(storage);
    container = ProviderContainer(
      overrides: [
        localDemoStorageProvider.overrideWithValue(storage),
        travellerRepositoryProvider.overrideWithValue(repository),
      ],
    );
    vm = container.read(travellerViewModelProvider.notifier);
    await Future<void>.delayed(Duration.zero);
  });
  tearDown(() => container.dispose());
  test(
    'separate dates validate and endpoint edits preserve intermediate stops',
    () {
      vm.newTrip();
      vm.setStartDate(DateTime(2026, 11, 10));
      expect(vm.setEndDate(DateTime(2026, 11, 9)), isFalse);
      expect(container.read(travellerViewModelProvider).draft.endDate, isNull);
      expect(vm.setEndDate(DateTime(2026, 11, 12)), isTrue);
      vm.setStartLocation('Jaffna');
      vm.setEndLocation('Kandy');
      vm.addIntermediateStop('Mannar');
      vm.addIntermediateStop('Vavuniya');
      vm.setStartLocation('Jaffna Fort');
      vm.setEndLocation('Colombo');
      expect(container.read(travellerViewModelProvider).draft.stops, [
        'Jaffna Fort',
        'Mannar',
        'Vavuniya',
        'Colombo',
      ]);
      expect(
        container.read(travellerViewModelProvider).pointsFor(['Jaffna Fort']),
        hasLength(1),
      );
    },
  );
  test('suggestions reuse catalog fixtures and map-selected coordinates persist with saved plans', () async {
    vm.newTrip();
    final suggestion = container
        .read(travellerViewModelProvider)
        .catalog
        .suggestions
        .first;
    vm.useSuggestion(suggestion);
    expect(
      container.read(travellerViewModelProvider).draft.stops,
      suggestion.plan.stops,
    );
    expect(container.read(travellerViewModelProvider).draft.editingId, isNull);
    vm.setDates(DateTime(2026, 11, 10), DateTime(2026, 11, 12));
    final point = container
        .read(travellerViewModelProvider)
        .catalog
        .cities['Jaffna']!;
    final name = vm.registerMapStop(point);
    vm.addIntermediateStop(name);
    expect(vm.saveDraft(), isTrue);
    await vm.persistenceSettled;
    final restored = await repository.restorePlans(
      MockData.currentUser['id'] as String,
    );
    final plan = restored!.firstWhere(
      (p) => p.id == container.read(travellerViewModelProvider).selectedId,
    );
    expect(plan.customStops[name]!.latitude, point.latitude);
    expect(plan.stops, contains(name));
    vm.newTrip();
    vm.setStartLocation('Jaffna Fort');
    vm.generateAi();
    expect(
      container.read(travellerViewModelProvider).draft.stops.first,
      'Jaffna Fort',
    );
  });
  test('invalid drafts cannot save, reordered multistop trip completes and persists', () async {
    expect(vm.saveDraft(), isFalse);
    vm.newTrip();
    vm.updateDraft(
      TripDraft(
        title: 'Test journey',
        startDate: DateTime(2026, 11, 10),
        endDate: DateTime(2026, 11, 12),
        budget: 15000,
        people: 3,
      ),
    );
    for (final city in ['Jaffna', 'Mannar', 'Kandy']) {
      vm.addStop(city);
    }
    vm.moveStop(1, 1);
    expect(container.read(travellerViewModelProvider).draft.stops, [
      'Jaffna',
      'Kandy',
      'Mannar',
    ]);
    vm.removeStop(1);
    vm.addStop('Kandy');
    expect(vm.saveDraft(), isTrue);
    final id = container.read(travellerViewModelProvider).selectedId!;
    expect(vm.start(id), isTrue);
    expect(repository.lookups, 0);
    vm.nextStop();
    expect(container.read(travellerViewModelProvider).progress, 1);
    expect(vm.start(id), isTrue);
    expect(container.read(travellerViewModelProvider).progress, 1);
    vm.edit(container.read(travellerViewModelProvider).active!);
    vm.addStop('Colombo');
    expect(vm.saveDraft(), isTrue);
    expect(
      container.read(travellerViewModelProvider).active!.stops.last,
      'Colombo',
    );
    expect(vm.finish(), isTrue);
    expect(vm.finish(), isFalse);
    await vm.persistenceSettled;
    final restored = await repository.restorePlans(
      MockData.currentUser['id'] as String,
    );
    expect(
      restored!.firstWhere((p) => p.id == id).status,
      TripStatus.completed,
    );
  });
  test('newly saved trip starts; switching an existing trip preserves both plans', () {
    final first = container.read(travellerViewModelProvider).plans.first;
    expect(vm.start(first.id), isTrue);
    vm.newTrip();
    vm.updateDraft(TripDraft(
      title: 'New local journey',
      startDate: DateTime(2026, 11, 6),
      endDate: DateTime(2026, 11, 9),
      stops: const ['Mannar', 'Trincomalee', 'Kandy'],
      vehicle: 'Van',
      budget: 50000,
      people: 3,
    ));
    expect(vm.saveDraft(), isTrue);
    final newId = container.read(travellerViewModelProvider).selectedId!;
    expect(vm.start(newId), isFalse); // no silent switch
    expect(container.read(travellerViewModelProvider).active?.id, first.id);
    expect(vm.start(newId, switchActive: true), isTrue);
    final state = container.read(travellerViewModelProvider);
    expect(state.active?.id, newId);
    expect(state.active?.title, 'New local journey');
    expect(state.active?.stops.first, 'Mannar');
    expect(state.plans.firstWhere((p) => p.id == first.id).status,
        TripStatus.planned);
    expect(state.plans.firstWhere((p) => p.id == newId).status,
        TripStatus.active);
  });

  test('nearby fixtures are loaded on demand, optional plans reuse only connected selected segments', () {
    expect(repository.lookups, 0);
    vm.start(container.read(travellerViewModelProvider).plans.first.id);
    expect(repository.lookups, 0);
    vm.loadNearby();
    expect(repository.lookups, 1);
    vm.category('Hospital');
    expect(
      container.read(travellerViewModelProvider).filteredNearby.single.category,
      'Hospital',
    );
    vm.newTrip();
    vm.generateAi();
    expect(
      container.read(travellerViewModelProvider).draft.method,
      TripMethod.ai,
    );
    vm.newTrip();
    expect(vm.useSegments({0, 2}), isFalse);
    expect(vm.useSegments({1}), isTrue);
    final segment = MockData.previousRouteSegments[1];
    expect(container.read(travellerViewModelProvider).draft.stops, [
      segment['from'],
      segment['to'],
    ]);
  });
  test('one active journey, independent media drafts and local invitations retain meaningful state', () {
    final plan = container.read(travellerViewModelProvider).plans.first;
    vm.start(plan.id);
    expect(vm.submitHazard(), isFalse);
    vm.hazardDraft(description: 'Demo blocked road');
    vm.addEvidence(const CapturedEvidence(demo: true), memory: false);
    expect(vm.submitHazard(), isTrue);
    expect(vm.postMemory(), isFalse);
    vm.caption('A remembered stop');
    vm.addEvidence(
      const CapturedEvidence(demo: true, video: true),
      memory: true,
    );
    vm.tag('Scenic');
    expect(vm.postMemory(), isTrue);
    expect(
      container
          .read(travellerViewModelProvider)
          .memories
          .single
          .evidence
          .single
          .demo,
      isTrue,
    );
    vm.alternativeRoute();
    expect(container.read(travellerViewModelProvider).alternateRoute, isTrue);
    expect(vm.invite('Kai'), isTrue);
    expect(vm.invite('kai'), isFalse);
    final invitation = container
        .read(travellerViewModelProvider)
        .invitations
        .single;
    vm.accept(invitation.id);
    expect(
      container
          .read(travellerViewModelProvider)
          .members
          .any((m) => m.name == 'Kai'),
      isTrue,
    );
    final offRoute = container
        .read(travellerViewModelProvider)
        .members
        .firstWhere((m) => m.isOffRoute);
    vm.alert(offRoute.id);
    expect(
      container.read(travellerViewModelProvider).alerted,
      contains(offRoute.id),
    );
    expect(container.read(travellerViewModelProvider).active!.id, plan.id);
  });
}
