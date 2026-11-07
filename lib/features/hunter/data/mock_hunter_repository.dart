import '../../../core/mock/mock_data.dart';
import '../domain/hunter_models.dart';
import '../domain/hunter_repository.dart';

class MockHunterRepository implements HunterRepository {
  @override
  HunterSeed load() => HunterSeed(
    userId: MockData.currentUser['id']! as String,
    district: MockData.demoCities.keys.first,
    rewardHp: MockData.hunterRewardHp,
    existingPlaceNames: List.unmodifiable(
      MockData.places.map((p) => p['name']! as String),
    ),
    submissions: List.unmodifiable(
      MockData.hunterSubmissions.map(
        (s) => HunterSubmission(
          id: s['id']! as String,
          userId: s['userId']! as String,
          name: s['placeName']! as String,
          district: s['district']! as String,
          category: s['category']! as String,
          description: '',
          address: s['district']! as String,
          status: s['status'] == 'Verified'
              ? HunterStatus.approved
              : HunterStatus.pending,
        ),
      ),
    ),
    rankings: List.unmodifiable(
      MockData.leaderboard.map(
        (r) => HunterRanking(
          name: r['name']! as String,
          rank: r['rank']! as int,
          hp: r['hp']! as int,
        ),
      ),
    ),
  );
  @override
  bool isDuplicate(String name) {
    final normalized = name.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return load().existingPlaceNames.any(
          (p) => p.toLowerCase() == normalized,
        ) ||
        load().submissions.any((p) => p.name.toLowerCase() == normalized);
  }

  @override
  String? validateDetails(HunterDraft draft) {
    if (draft.name.trim().length < 3) {
      return 'Enter a place name with at least 3 characters.';
    }
    if (draft.address.trim().length < 3) {
      return 'Enter an address or location description.';
    }
    if (draft.description.trim().length < 10) {
      return 'Describe this place in at least 10 characters.';
    }
    return null;
  }
}
