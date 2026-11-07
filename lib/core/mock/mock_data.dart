/// Wayhunter UI prototype -- the ONE source of hardcoded demo content.
///
/// This contains NO real user credentials, commercial vouchers, backend calls,
/// or production verification. Repository implementations must read fixtures
/// from this file. Interactive changes belong to Riverpod state / optional
/// local-only shared_preferences, not repeated fake lists in screen widgets.
/// Coordinates and partner names below are illustrative demo content.
abstract final class MockData {
  // Suggestion metadata reuses the existing ordered trip fixtures below.
  static const tripSuggestions = <Map<String, String>>[
    {
      'id': 'idea-jaffna',
      'tripId': 'trip-002',
      'title': 'Jaffna Heritage Trail',
      'author': 'Nimal Perera',
      'thumbnailAsset': 'assets/images/backgrounds/home_background.png',
    },
    {
      'id': 'idea-northern-hills',
      'tripId': 'trip-001',
      'title': 'Northern & Hill Country Loop',
      'author': 'Thanushi Silva',
      'thumbnailAsset': 'assets/images/backgrounds/home_background.png',
    },
  ];
  static const tripVehicles = ['Car', 'Van', 'SUV', 'Motorbike', 'Bus', 'Walk'];
  static const tripBudgetOptions = <double>[15000, 25000, 36000, 65000, 92000];

  /// Initial Traveller landing viewport, not a restriction on map gestures.
  static const sriLankaMapBounds = <String, double>{
    'south': 5.85,
    'west': 79.50,
    'north': 9.95,
    'east': 82.20,
  };
  static const hunterRewardHp = 50;
  static const gameChallengeTypes = ['Treasure Hunt', 'Landmark Hunt'];
  static const gameDefaultRewardHp = 40;
  static const gameDefaultRewardRc = 20;
  static const gameDefaultInstructions =
      'Take a clear live photo of the location.';
  static const profileBio = 'Explorer · Gamer · Traveller';
  static const appVersion = '1.0.0';
  static const profileBadges = [
    'Travel Explorer',
    'Trail Starter',
    'Local Discoverer',
  ];
  static const notificationPreferences = <String, bool>{
    'Trip': true,
    'Game': true,
    'Hunter': true,
    'Hazard': true,
    'Promotions': false,
  };
  static const nearbyPlaces = <Map<String, Object?>>[
    {
      'id': 'near-hotel',
      'name': 'Northern Rest House',
      'category': 'Hotel',
      'district': 'Jaffna',
      'lat': 9.662,
      'lng': 80.025,
      'distanceKm': 0.3,
    },
    {
      'id': 'near-food',
      'name': 'Demo Garden Restaurant',
      'category': 'Food',
      'district': 'Jaffna',
      'lat': 9.663,
      'lng': 80.028,
      'distanceKm': 0.5,
    },
    {
      'id': 'near-fuel',
      'name': 'Demo Fuel Station',
      'category': 'Fuel',
      'district': 'Jaffna',
      'lat': 9.665,
      'lng': 80.029,
      'distanceKm': 0.7,
    },
    {
      'id': 'near-hospital',
      'name': 'Demo General Hospital',
      'category': 'Hospital',
      'district': 'Jaffna',
      'lat': 9.668,
      'lng': 80.024,
      'distanceKm': 0.9,
    },
    {
      'id': 'near-attraction',
      'name': 'Jaffna Fort',
      'category': 'Attraction',
      'district': 'Jaffna',
      'lat': 9.6593,
      'lng': 80.0107,
      'distanceKm': 1.0,
    },
  ];
  // Authentication: demonstration only; never ship this as real security.
  static const demoEmail = 'traveller@gmail.com';
  static const demoPassword = 'wayhunter123';
  static const demoOtp = '123456';

  static const currentUser = <String, Object?>{
    'id': 'demo-user-001',
    'name': 'Explorer_07',
    'email': demoEmail,
    'phone': '+94 70 000 0000',
    'language': 'English',
    'profileVisibility': 'Public',
    'level': 14,
    'hp': 3420,
    'rc': 1500,
    'lifetimeHp': 5860,
    'followers': 184,
    'following': 96,
    'avatarAsset': null,
  };

  static const districtNames = <String>[
    'Jaffna',
    'Kilinochchi',
    'Mannar',
    'Mullaitivu',
    'Vavuniya',
    'Anuradhapura',
    'Polonnaruwa',
    'Trincomalee',
    'Batticaloa',
    'Ampara',
    'Puttalam',
    'Kurunegala',
    'Matale',
    'Kandy',
    'Nuwara Eliya',
    'Badulla',
    'Monaragala',
    'Ratnapura',
    'Kegalle',
    'Gampaha',
    'Colombo',
    'Kalutara',
    'Galle',
    'Matara',
    'Hambantota',
  ];

  /// Latitude/longitude for UI preview only, not turn-by-turn route guidance.
  static const demoCities = <String, Map<String, double>>{
    'Jaffna': {'lat': 9.6615, 'lng': 80.0255},
    'Kilinochchi': {'lat': 9.3803, 'lng': 80.3770},
    'Mannar': {'lat': 8.9800, 'lng': 79.9040},
    'Vavuniya': {'lat': 8.7514, 'lng': 80.4971},
    'Anuradhapura': {'lat': 8.3114, 'lng': 80.4037},
    'Trincomalee': {'lat': 8.5874, 'lng': 81.2152},
    'Kandy': {'lat': 7.2906, 'lng': 80.6337},
    'Colombo': {'lat': 6.9271, 'lng': 79.8612},
  };

  static const places = <Map<String, Object?>>[
    {
      'id': 'place-001',
      'name': 'Jaffna Fort',
      'district': 'Jaffna',
      'category': 'Historical',
      'lat': 9.6593,
      'lng': 80.0107,
      'rating': 4.6,
      'verified': true,
      'description': 'Historic coastal fort -- sample place description.',
    },
    {
      'id': 'place-002',
      'name': 'Nallur Kandaswamy Temple',
      'district': 'Jaffna',
      'category': 'Temple',
      'lat': 9.6758,
      'lng': 80.0298,
      'rating': 4.8,
      'verified': true,
      'description': 'Cultural landmark -- sample place description.',
    },
    {
      'id': 'place-003',
      'name': 'Mannar Fort',
      'district': 'Mannar',
      'category': 'Historical',
      'lat': 8.9809,
      'lng': 79.9020,
      'rating': 4.4,
      'verified': true,
      'description': 'Mannar location -- demo content.',
    },
    {
      'id': 'place-004',
      'name': 'Kandy Lake',
      'district': 'Kandy',
      'category': 'Nature',
      'lat': 7.2909,
      'lng': 80.6427,
      'rating': 4.7,
      'verified': true,
      'description': 'Scenic lakeside destination -- demo content.',
    },
  ];

  static const tripPlans = <Map<String, Object?>>[
    {
      'id': 'trip-001',
      'title': 'Northern Heritage Adventure',
      'ownerId': 'demo-user-001',
      'status': 'Planned',
      'planningMethod': 'Manual',
      'vehicle': 'Car',
      'people': 4,
      'budgetLkr': 25000,
      'startDate': '2026-11-10',
      'endDate': '2026-11-14',
      'stops': ['Jaffna', 'Kilinochchi', 'Mannar', 'Anuradhapura', 'Kandy'],
    },
    {
      'id': 'trip-002',
      'title': 'Jaffna Heritage Trail',
      'ownerId': 'sample-traveller-002',
      'status': 'Completed',
      'planningMethod': 'Previous Traveller',
      'vehicle': 'Van',
      'people': 6,
      'budgetLkr': 36000,
      'startDate': '2026-10-10',
      'endDate': '2026-10-14',
      'stops': ['Jaffna', 'Kilinochchi', 'Vavuniya', 'Trincomalee', 'Colombo'],
    },
  ];

  static const previousRouteSegments = <Map<String, Object?>>[
    {
      'from': 'Jaffna',
      'to': 'Kilinochchi',
      'sourceTripId': 'trip-002',
      'estimatedDistanceKm': 70,
    },
    {
      'from': 'Kilinochchi',
      'to': 'Vavuniya',
      'sourceTripId': 'trip-002',
      'estimatedDistanceKm': 80,
    },
    {
      'from': 'Vavuniya',
      'to': 'Trincomalee',
      'sourceTripId': 'trip-002',
      'estimatedDistanceKm': 110,
    },
  ];

  static const groupMembers = <Map<String, Object?>>[
    {
      'userId': 'demo-user-001',
      'name': 'Explorer_07',
      'status': 'On route',
      'deviationMetres': 0,
      'lat': 9.6615,
      'lng': 80.0255,
    },
    {
      'userId': 'demo-user-002',
      'name': 'Kavi',
      'status': 'On route',
      'deviationMetres': 120,
      'lat': 9.6625,
      'lng': 80.0265,
    },
    {
      'userId': 'demo-user-003',
      'name': 'Aru',
      'status': 'Off route',
      'deviationMetres': 650,
      'lat': 9.6675,
      'lng': 80.0305,
    },
  ];

  static const hazardReports = <Map<String, Object?>>[
    {
      'id': 'hazard-demo-01',
      'type': 'Blocked Road',
      'district': 'Mannar',
      'status': 'Demo alert',
      'description': 'Example hazard; not a live safety warning.',
    },
  ];

  static const hunterSubmissions = <Map<String, Object?>>[
    {
      'id': 'hunter-001',
      'userId': 'demo-user-001',
      'placeName': 'Hidden Coast Viewpoint',
      'district': 'Jaffna',
      'category': 'Nature',
      'status': 'Pending',
      'hasLivePhoto': true,
      'has360Video': true,
    },
    {
      'id': 'hunter-002',
      'userId': 'demo-user-001',
      'placeName': 'Northern Heritage Spot',
      'district': 'Jaffna',
      'category': 'Historical',
      'status': 'Verified',
      'hasLivePhoto': true,
      'has360Video': true,
    },
  ];

  static const games = <Map<String, Object?>>[
    {
      'id': 'game-001',
      'title': 'Find the Northern Landmark',
      'district': 'Jaffna',
      'status': 'Active',
      'creatorId': 'sample-creator-01',
      'hint': 'Near a historic coastal landmark.',
      'rewardHp': 40,
      'rewardRc': 20,
      'proofRequired': true,
    },
    {
      'id': 'game-002',
      'title': 'Mannar Discovery Hunt',
      'district': 'Mannar',
      'status': 'Active',
      'creatorId': 'sample-creator-02',
      'hint': 'Look for an old stone structure.',
      'rewardHp': 50,
      'rewardRc': 0,
      'proofRequired': true,
    },
  ];

  static const leaderboard = <Map<String, Object?>>[
    {'name': 'HunterStar', 'rank': 1, 'hp': 5120},
    {'name': 'Explorer_07', 'rank': 2, 'hp': 3420},
    {'name': 'WaySeeker', 'rank': 3, 'hp': 2850},
  ];

  /// Sample commercial-looking offers are NON-REDEEMABLE DEMO data.
  static const walletLevelTargetHp = 5000;
  static const walletVoucherValidityDays = 180;
  static const demoVoucherInventory = <Map<String, String>>[
    {'id': 'stock-500-a', 'offerId': 'reward-500', 'code': '500-A'},
    {'id': 'stock-500-b', 'offerId': 'reward-500', 'code': '500-B'},
    {'id': 'stock-500-c', 'offerId': 'reward-500', 'code': '500-C'},
    {'id': 'stock-1000-a', 'offerId': 'reward-1000', 'code': '1000-A'},
    {'id': 'stock-1000-b', 'offerId': 'reward-1000', 'code': '1000-B'},
    {'id': 'stock-1000-c', 'offerId': 'reward-1000', 'code': '1000-C'},
    {'id': 'stock-2000-a', 'offerId': 'reward-2000', 'code': '2000-A'},
    {'id': 'stock-2000-b', 'offerId': 'reward-2000', 'code': '2000-B'},
    {'id': 'stock-2000-c', 'offerId': 'reward-2000', 'code': '2000-C'},
  ];
  static const rewards = <Map<String, Object?>>[
    {
      'id': 'reward-500',
      'partner': 'Thyaga (demo)',
      'name': 'Thyaga Gift Voucher',
      'valueLkr': 500,
      'costRc': 500,
      'category': 'Shopping',
      'demoOnly': true,
    },
    {
      'id': 'reward-1000',
      'partner': 'Thyaga (demo)',
      'name': 'Thyaga Gift Voucher',
      'valueLkr': 1000,
      'costRc': 1000,
      'category': 'Shopping',
      'demoOnly': true,
    },
    {
      'id': 'reward-2000',
      'partner': 'Thyaga (demo)',
      'name': 'Thyaga Gift Voucher',
      'valueLkr': 2000,
      'costRc': 2000,
      'category': 'Shopping',
      'demoOnly': true,
    },
  ];

  static const sampleVoucherRequests = <Map<String, Object?>>[
    {
      'id': 'WH-RWD-000125',
      'rewardId': 'reward-1000',
      'costRc': 1000,
      'status': 'Pending',
      'userId': 'demo-user-001',
      'createdAt': '2026-11-05T09:00:00',
    },
  ];

  static const sampleVouchers = <Map<String, Object?>>[
    {
      'id': 'voucher-demo-expired-001',
      'rewardId': 'reward-1000',
      'valueLkr': 1000,
      'status': 'Expired',
      'issueDate': '2026-01-10',
      'expiryDate': '2026-07-10',
      'code': 'DEMO-EXPIRED-NOT-VALID',
      'demoOnly': true,
    },
    {
      'id': 'voucher-demo-used-001',
      'rewardId': 'reward-500',
      'valueLkr': 500,
      'status': 'Used',
      'issueDate': '2026-01-12',
      'expiryDate': '2026-07-12',
      'code': 'DEMO-USED-NOT-VALID',
      'demoOnly': true,
    },
  ];

  static const transactionHistory = <Map<String, Object?>>[
    {
      'id': 'tx-001',
      'type': 'HP',
      'title': 'Demo game reward',
      'amount': 40,
      'status': 'Completed',
      'createdAt': '2026-11-02',
    },
    {
      'id': 'tx-002',
      'type': 'RC',
      'title': 'Demo sponsored game reward',
      'amount': 20,
      'status': 'Completed',
      'createdAt': '2026-11-03',
    },
    {
      'id': 'tx-003',
      'requestId': 'WH-RWD-000125',
      'type': 'Voucher',
      'title': 'Demo voucher request',
      'amount': 0,
      'status': 'Pending',
      'createdAt': '2026-11-05',
    },
  ];

  static const notifications = <Map<String, Object?>>[
    {
      'id': 'n-1',
      'type': 'Trip',
      'title': 'Your trip is ready',
      'body': 'Continue your Northern Heritage plan.',
    },
    {
      'id': 'n-2',
      'type': 'Wallet',
      'title': 'Voucher request pending',
      'body': 'Demo approval is pending. No real merchant voucher is issued.',
    },
  ];

  static const advertisements = <Map<String, Object?>>[
    {
      'id': 'ad-demo-1',
      'title': 'Explore Sri Lanka',
      'description': 'Demo travel banner',
      'isSponsored': true,
    },
    {
      'id': 'ad-demo-2',
      'title': 'Adventure Rewards',
      'description': 'Demo sponsor campaign',
      'isSponsored': true,
    },
  ];

  static const languageOptions = <String>['English', 'தமிழ்', 'සිංහල'];

  static const helpSections = <Map<String, String>>[
    {
      'title': 'Getting Started',
      'text': 'Sign in, set permissions, explore modes.',
    },
    {
      'title': 'Traveller',
      'text': 'Plan routes, add stops, start and finish trips.',
    },
    {
      'title': 'Location Hunter',
      'text': 'Use live evidence, GPS and review submission.',
    },
    {'title': 'Game', 'text': 'Create or join a location challenge.'},
    {
      'title': 'Wallet',
      'text': 'Submit demo RC requests and inspect voucher status.',
    },
  ];
}
