import '../entities/game_models.dart';

abstract interface class GameRepository {
  GameSeed load();
}
