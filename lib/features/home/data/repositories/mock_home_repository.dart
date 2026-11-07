import '../../../../core/mock/mock_data.dart';
import '../../domain/entities/home_content.dart';
import '../../domain/repositories/home_repository.dart';

class MockHomeRepository implements HomeRepository {
  @override
  HomeContent load() => HomeContent(
    places: List.unmodifiable(
      MockData.places.map(
        (p) => DemoPlace(
          id: p['id'] as String,
          name: p['name'] as String,
          district: p['district'] as String,
          category: p['category'] as String,
          latitude: p['lat'] as double,
          longitude: p['lng'] as double,
        ),
      ),
    ),
    advertisements: List.unmodifiable(
      MockData.advertisements.map(
        (ad) => DemoAdvertisement(
          title: ad['title'] as String,
          description: ad['description'] as String,
        ),
      ),
    ),
    notifications: List.unmodifiable(
      MockData.notifications.map(
        (n) => DemoNotification(
          id: n['id'] as String,
          title: n['title'] as String,
          body: n['body'] as String,
        ),
      ),
    ),
    rankings: List.unmodifiable(
      MockData.leaderboard.map(
        (r) => DemoRanking(
          name: r['name'] as String,
          rank: r['rank'] as int,
          hp: r['hp'] as int,
        ),
      ),
    ),
  );
}
