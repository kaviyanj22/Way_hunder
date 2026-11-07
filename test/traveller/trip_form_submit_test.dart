import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/core/services/evidence_service.dart';
import 'package:wayhunter_mobile/core/storage/local_demo_storage.dart';
import 'package:wayhunter_mobile/features/traveller/data/traveller_activity_store.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/viewmodels/traveller_view_model.dart';

void main() {
  test('hazard and memory save locally; Profile Posts uses the same memories',
      () async {
    final storage = MemoryDemoStorage();
    final container = ProviderContainer(
      overrides: [localDemoStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final vm = container.read(travellerViewModelProvider.notifier);
    final initial = container.read(travellerViewModelProvider);
    final plan = initial.plans.firstWhere((p) => p.ownerId == initial.ownerId);
    expect(vm.start(plan.id), isTrue);

    expect(vm.submitHazard(), isFalse);
    expect(container.read(travellerViewModelProvider).error,
        contains('Describe the hazard'));
    vm.hazardDraft(description: 'Tree across the road');
    vm.addEvidence(const CapturedEvidence(demo: true), memory: false);
    expect(vm.submitHazard(), isTrue);

    expect(vm.postMemory(), isFalse);
    vm.caption('Beautiful local journey at Jaffna');
    vm.addEvidence(const CapturedEvidence(demo: true), memory: true);
    vm.tag('Scenic');
    expect(vm.postMemory(), isTrue);

    // The Profile -> Posts tab reads travellerViewModelProvider.memories.
    final visiblePosts = container.read(travellerViewModelProvider).memories;
    expect(visiblePosts, hasLength(1));
    expect(visiblePosts.single.caption,
        'Beautiful local journey at Jaffna');
    expect(visiblePosts.single.tripId, plan.id);
    expect(container.read(travellerViewModelProvider).hazards, hasLength(1));

    await vm.persistenceSettled;
    final restored =
        await TravellerActivityStore(storage).restore(initial.ownerId);
    expect(restored, isNotNull);
    expect(restored!.memories.single.caption, visiblePosts.single.caption);
    expect(restored.hazards.single.description, 'Tree across the road');
  });
}
