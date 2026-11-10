import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wayhunter_mobile/features/hunter/data/mock_hunter_repository.dart';
import 'package:wayhunter_mobile/features/hunter/domain/hunter_models.dart';
import 'package:wayhunter_mobile/features/hunter/presentation/providers/hunter_routes.dart';

void main() {
  test('Hunter prototype registers each required route', () {
    final paths = hunterRoutes.whereType<GoRoute>().map((r) => r.path).toSet();
    expect(paths, containsAll([
      '/hunter', '/hunter/add', '/hunter/gps', '/hunter/duplicate',
      '/hunter/camera360', '/hunter/video-complete', '/hunter/video-attached',
      '/hunter/photo-camera', '/hunter/review', '/hunter/verification',
      '/hunter/rewards', '/hunter/leaderboard', '/hunter/admin-review',
    ]));
  });

  test('validates place metadata and checks mock duplicates', () {
    final repo = MockHunterRepository();
    expect(repo.load().district, 'Jaffna');
    expect(repo.validateDetails(const HunterDraft()), isNotNull);
    expect(repo.validateDetails(const HunterDraft(
      name: 'Coastal discovery',
      address: 'Jaffna district coast',
      description: 'A new scenic outdoor location',
    )), isNull);
    final existing = repo.load().existingPlaceNames.first;
    expect(repo.isDuplicate(existing), isTrue);
  });
}
