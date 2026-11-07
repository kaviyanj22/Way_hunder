class DemoPlace {
  const DemoPlace({
    required this.id,
    required this.name,
    required this.district,
    required this.category,
    required this.latitude,
    required this.longitude,
  });
  final String id;
  final String name;
  final String district;
  final String category;
  final double latitude;
  final double longitude;
}

class DemoAdvertisement {
  const DemoAdvertisement({required this.title, required this.description});
  final String title;
  final String description;
}

class DemoNotification {
  const DemoNotification({
    required this.id,
    required this.title,
    required this.body,
  });
  final String id;
  final String title;
  final String body;
}

class DemoRanking {
  const DemoRanking({required this.name, required this.rank, required this.hp});
  final String name;
  final int rank;
  final int hp;
}

class HomeContent {
  const HomeContent({
    required this.places,
    required this.advertisements,
    required this.notifications,
    required this.rankings,
  });
  final List<DemoPlace> places;
  final List<DemoAdvertisement> advertisements;
  final List<DemoNotification> notifications;
  final List<DemoRanking> rankings;
}
