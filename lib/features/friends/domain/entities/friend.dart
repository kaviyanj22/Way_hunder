/// Demo social profile. Replace the local data source with authenticated API data
/// when the Wayhunter friends backend is implemented.
class WayhunterFriend {
  const WayhunterFriend({
    required this.id,
    required this.name,
    required this.handle,
    required this.location,
    required this.mutualCount,
  });

  final String id;
  final String name;
  final String handle;
  final String location;
  final int mutualCount;
}

const demoWayhunterFriends = <WayhunterFriend>[
  WayhunterFriend(
    id: 'demo-kaviyan',
    name: 'Kaviyan',
    handle: '@kaviyan',
    location: 'Jaffna',
    mutualCount: 12,
  ),
  WayhunterFriend(
    id: 'demo-thuvarathan',
    name: 'Thuvarathan',
    handle: '@thuvarathan',
    location: 'Jaffna',
    mutualCount: 8,
  ),
  WayhunterFriend(
    id: 'demo-anusha',
    name: 'Anusha',
    handle: '@anusha_p',
    location: 'Colombo',
    mutualCount: 5,
  ),
  WayhunterFriend(
    id: 'demo-niroshan',
    name: 'Niroshan',
    handle: '@niroshan',
    location: 'Kandy',
    mutualCount: 3,
  ),
  WayhunterFriend(
    id: 'demo-explorer',
    name: 'Explorer_07',
    handle: '@explorer_07',
    location: 'Ella',
    mutualCount: 14,
  ),
  WayhunterFriend(
    id: 'demo-dilan',
    name: 'Dilan Perera',
    handle: '@dilan_perera',
    location: 'Galle',
    mutualCount: 3,
  ),
  WayhunterFriend(
    id: 'demo-ishara',
    name: 'Ishara Fernando',
    handle: '@ishara_f',
    location: 'Jaffna',
    mutualCount: 5,
  ),
  WayhunterFriend(
    id: 'demo-meena',
    name: 'Meena Perera',
    handle: '@meena_perera',
    location: 'Colombo',
    mutualCount: 2,
  ),
  WayhunterFriend(
    id: 'demo-ravindu',
    name: 'Ravindu Silva',
    handle: '@ravindu_s',
    location: 'Matara',
    mutualCount: 4,
  ),
];

WayhunterFriend? findDemoFriend(String id) {
  for (final friend in demoWayhunterFriends) {
    if (friend.id == id) return friend;
  }
  return null;
}
