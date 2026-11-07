import '../../auth/domain/auth_user.dart';
import 'wallet_models.dart';

abstract interface class WalletRepository {
  WalletState initial(AuthUser? user);
  Future<WalletState?> restore(String userId, WalletState seed);
  Future<void> save(String userId, WalletState state);
}
