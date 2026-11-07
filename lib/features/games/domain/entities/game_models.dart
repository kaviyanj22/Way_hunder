import 'dart:typed_data';

class GameEvidence {
  const GameEvidence({this.bytes, this.path, this.demo = false});
  final Uint8List? bytes;
  final String? path;
  final bool demo;
  Map<String, Object?> toJson() => {'path': path, 'demo': demo};
  factory GameEvidence.fromJson(Map<String, dynamic> value) =>
      GameEvidence(path: value['path'] as String?, demo: value['demo'] == true);
}

class GameChallenge {
  const GameChallenge({
    required this.id,
    required this.title,
    required this.district,
    required this.creatorId,
    required this.hint,
    required this.instructions,
    required this.type,
    required this.rewardHp,
    required this.rewardRc,
    this.photo,
    this.winnerId,
  });
  final String id, title, district, creatorId, hint, instructions, type;
  final int rewardHp, rewardRc;
  final GameEvidence? photo;
  final String? winnerId;
  bool get finished => winnerId != null;
  GameChallenge withWinner(String userId) => GameChallenge(
    id: id,
    title: title,
    district: district,
    creatorId: creatorId,
    hint: hint,
    instructions: instructions,
    type: type,
    rewardHp: rewardHp,
    rewardRc: rewardRc,
    photo: photo,
    winnerId: userId,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'district': district,
    'creatorId': creatorId,
    'hint': hint,
    'instructions': instructions,
    'type': type,
    'rewardHp': rewardHp,
    'rewardRc': rewardRc,
    'photo': photo?.toJson(),
    'winnerId': winnerId,
  };
  factory GameChallenge.fromJson(Map<String, dynamic> value) => GameChallenge(
    id: value['id'] as String,
    title: value['title'] as String,
    district: value['district'] as String,
    creatorId: value['creatorId'] as String,
    hint: value['hint'] as String,
    instructions: value['instructions'] as String,
    type: value['type'] as String,
    rewardHp: (value['rewardHp'] as num).toInt(),
    rewardRc: (value['rewardRc'] as num).toInt(),
    photo: value['photo'] == null
        ? null
        : GameEvidence.fromJson(
            Map<String, dynamic>.from(value['photo'] as Map),
          ),
    winnerId: value['winnerId'] as String?,
  );
}

class GameDraft {
  const GameDraft({
    this.title = '',
    this.district = '',
    this.type = '',
    this.rewardHp = 0,
    this.rewardRc = 0,
    this.hint = '',
    this.instructions = '',
    this.rewardsEnabled = true,
    this.photo,
  });
  final String title, district, type, hint, instructions;
  final int rewardHp, rewardRc;
  final bool rewardsEnabled;
  final GameEvidence? photo;
  GameDraft copyWith({
    String? title,
    String? district,
    String? type,
    int? rewardHp,
    int? rewardRc,
    String? hint,
    String? instructions,
    bool? rewardsEnabled,
    GameEvidence? photo,
    bool clearPhoto = false,
  }) => GameDraft(
    title: title ?? this.title,
    district: district ?? this.district,
    type: type ?? this.type,
    rewardHp: rewardHp ?? this.rewardHp,
    rewardRc: rewardRc ?? this.rewardRc,
    hint: hint ?? this.hint,
    instructions: instructions ?? this.instructions,
    rewardsEnabled: rewardsEnabled ?? this.rewardsEnabled,
    photo: clearPhoto ? null : photo ?? this.photo,
  );
}

class GameRanking {
  const GameRanking({required this.name, required this.rank, required this.hp});
  final String name;
  final int rank, hp;
}

class GameOffer {
  const GameOffer({
    required this.id,
    required this.name,
    required this.costRc,
    required this.valueLkr,
  });
  final String id, name;
  final int costRc, valueLkr;
}

class GameSponsor {
  const GameSponsor({required this.title, required this.description});
  final String title, description;
}

class GameSeed {
  const GameSeed({
    required this.games,
    required this.districts,
    required this.types,
    required this.rankings,
    required this.offers,
    required this.sponsors,
    required this.defaultRewardHp,
    required this.defaultRewardRc,
    required this.defaultInstructions,
    required this.defaultUserId,
    required this.participantIds,
  });
  final List<GameChallenge> games;
  final List<String> districts, types, participantIds;
  final List<GameRanking> rankings;
  final List<GameOffer> offers;
  final List<GameSponsor> sponsors;
  final int defaultRewardHp, defaultRewardRc;
  final String defaultInstructions, defaultUserId;
}

enum GameVerificationOutcome { valid, otherWinner, invalid }

class GameRules {
  static String? setupError(GameDraft draft, GameSeed seed) {
    if (draft.title.trim().length < 3) {
      return 'Enter a challenge title with at least 3 characters.';
    }
    if (!seed.districts.contains(draft.district)) return 'Choose a district.';
    if (!seed.types.contains(draft.type)) return 'Choose a challenge type.';
    if (draft.rewardHp < 0 || draft.rewardRc < 0) {
      return 'Rewards cannot be negative.';
    }
    if (draft.rewardHp > 10000 || draft.rewardRc > 10000) {
      return 'Use demo rewards of 10,000 or less.';
    }
    return null;
  }

  static String? rulesError(GameDraft draft) {
    if (draft.hint.trim().length < 8) {
      return 'Write a useful hint with at least 8 characters.';
    }
    if (draft.instructions.trim().length < 8) {
      return 'Write clear proof instructions.';
    }
    return null;
  }

  static String? joinError(GameChallenge game, String userId) {
    if (game.creatorId == userId) {
      return 'The creator cannot join their own challenge.';
    }
    if (game.finished) {
      return 'This challenge has ended. Its first demo winner is already recorded.';
    }
    return null;
  }
}
