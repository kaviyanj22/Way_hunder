import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_hunter_repository.dart';
import '../../domain/hunter_repository.dart';
import '../../../wallet/coins/coin_wallet_view_model.dart';

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
          .read(coinWalletProvider.notifier)
          .recordEarning(
            sourceId: sourceId,
            title: title,
            coins: 200,
            approved: true,
          ),
);
