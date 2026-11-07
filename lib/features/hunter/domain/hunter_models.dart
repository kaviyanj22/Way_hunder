import 'dart:typed_data';

enum HunterStatus { pending, approved, rejected }

enum HunterCategory {
  nature,
  heritage,
  beach,
  food,
  adventure,
  hidden,
  viewpoint,
  other,
}

extension HunterCategoryLabel on HunterCategory {
  String get label => switch (this) {
    HunterCategory.nature => 'Nature',
    HunterCategory.heritage => 'Heritage',
    HunterCategory.beach => 'Beach',
    HunterCategory.food => 'Food',
    HunterCategory.adventure => 'Adventure',
    HunterCategory.hidden => 'Hidden',
    HunterCategory.viewpoint => 'Viewpoint',
    HunterCategory.other => 'Other',
  };
}

extension HunterStatusLabel on HunterStatus {
  String get label => switch (this) {
    HunterStatus.pending => 'Pending',
    HunterStatus.approved => 'Approved',
    HunterStatus.rejected => 'Rejected',
  };
}

class HunterEvidence {
  const HunterEvidence({this.bytes, this.path, required this.demo});
  final Uint8List? bytes;
  final String? path;
  final bool demo;
}

class HunterDraft {
  const HunterDraft({
    this.name = '',
    this.address = '',
    this.description = '',
    this.category = HunterCategory.nature,
    this.gpsChecked = false,
    this.duplicateChecked = false,
    this.restricted = false,
    this.simulateDuplicate = false,
    this.has360 = false,
    this.photo,
  });
  final String name;
  final String address;
  final String description;
  final HunterCategory category;
  final bool gpsChecked;
  final bool duplicateChecked;
  final bool restricted;
  final bool simulateDuplicate;
  final bool has360;
  final HunterEvidence? photo;
  HunterDraft copyWith({
    String? name,
    String? address,
    String? description,
    HunterCategory? category,
    bool? gpsChecked,
    bool? duplicateChecked,
    bool? restricted,
    bool? simulateDuplicate,
    bool? has360,
    HunterEvidence? photo,
    bool clearPhoto = false,
  }) => HunterDraft(
    name: name ?? this.name,
    address: address ?? this.address,
    description: description ?? this.description,
    category: category ?? this.category,
    gpsChecked: gpsChecked ?? this.gpsChecked,
    duplicateChecked: duplicateChecked ?? this.duplicateChecked,
    restricted: restricted ?? this.restricted,
    simulateDuplicate: simulateDuplicate ?? this.simulateDuplicate,
    has360: has360 ?? this.has360,
    photo: clearPhoto ? null : photo ?? this.photo,
  );
}

class HunterSubmission {
  const HunterSubmission({
    required this.id,
    required this.userId,
    required this.name,
    required this.district,
    required this.category,
    required this.description,
    required this.address,
    required this.status,
    this.demoEvidence = true,
    this.reason,
    this.photo,
  });
  final String id;
  final String userId;
  final String name;
  final String district;
  final String category;
  final String description;
  final String address;
  final HunterStatus status;
  final bool demoEvidence;
  final String? reason;
  final HunterEvidence? photo;
  HunterSubmission withStatus(HunterStatus value, {String? reason}) =>
      HunterSubmission(
        id: id,
        userId: userId,
        name: name,
        district: district,
        category: category,
        description: description,
        address: address,
        status: value,
        demoEvidence: demoEvidence,
        reason: reason,
        photo: photo,
      );
  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'district': district,
    'category': category,
    'description': description,
    'address': address,
    'status': status.name,
    'demoEvidence': demoEvidence,
    'reason': reason,
  };
  factory HunterSubmission.fromJson(Map<String, Object?> json) =>
      HunterSubmission(
        id: json['id']! as String,
        userId: json['userId']! as String,
        name: json['name']! as String,
        district: json['district']! as String,
        category: json['category']! as String,
        description: json['description']! as String,
        address: json['address']! as String,
        status: HunterStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => HunterStatus.pending,
        ),
        demoEvidence: json['demoEvidence'] as bool? ?? true,
        reason: json['reason'] as String?,
      );
}

class HunterRanking {
  const HunterRanking({
    required this.name,
    required this.rank,
    required this.hp,
  });
  final String name;
  final int rank;
  final int hp;
}

class HunterSeed {
  const HunterSeed({
    required this.userId,
    required this.district,
    required this.submissions,
    required this.rankings,
    required this.existingPlaceNames,
    required this.rewardHp,
  });
  final String district;
  final String userId;
  final List<HunterSubmission> submissions;
  final List<HunterRanking> rankings;
  final List<String> existingPlaceNames;
  final int rewardHp;
}
