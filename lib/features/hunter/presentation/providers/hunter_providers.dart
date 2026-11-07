import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_hunter_repository.dart';
import '../../domain/hunter_repository.dart';
import '../../../wallet/presentation/viewmodels/wallet_view_model.dart';

final hunterRepositoryProvider = Provider<HunterRepository>(
  (ref) => MockHunterRepository(),
);
typedef HunterRewardCredit = bool Function({
  required String sourceId,
  required int hp,
  required String title,
});
final hunterRewardCreditProvider = Provider<HunterRewardCredit>(
  (ref) =>
      ({required sourceId, required hp, required title}) => ref
          .read(walletViewModelProvider.notifier)
          .creditReward(sourceId: sourceId, hp: hp, rc: 0, title: title),
);
