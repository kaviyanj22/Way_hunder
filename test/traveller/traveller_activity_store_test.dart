import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/core/storage/local_demo_storage.dart';
import 'package:wayhunter_mobile/features/traveller/data/traveller_activity_store.dart';
import 'package:wayhunter_mobile/features/traveller/domain/entities/trip.dart';

void main() {
  test('local memories and hazards round-trip with user isolation', () async {
    final storage = MemoryDemoStorage();
    final store = TravellerActivityStore(storage);
    final memories = [
      TripMemory(
        id: 'memory-1', tripId: 'trip-1', caption: 'Jaffna',
        stop: 'Jaffna', evidence: [const TripEvidence(id: 'demo-photo', demo: true)],
        tags: {'Scenic'},
      ),
    ];
    final hazards = [
      TripHazard(
        id: 'hazard-1', tripId: 'trip-1', type: 'Blocked Road',
        description: 'Tree across road', stop: 'Jaffna',
        evidence: [const TripEvidence(id: 'demo-video', demo: true, video: true)],
      ),
    ];
    await store.save('alice', memories, hazards);
    expect(await store.restore('bob'), isNull);
    final restored = await store.restore('alice');
    expect(restored!.memories.single.caption, 'Jaffna');
    expect(restored.memories.single.tags, contains('Scenic'));
    expect(restored.hazards.single.type, 'Blocked Road');
    expect(restored.hazards.single.evidence.single.video, isTrue);
  });
}
