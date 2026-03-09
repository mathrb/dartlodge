import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/persistence/database_provider.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/game_stats.dart';
import '../../domain/entities/player_stats.dart';

part 'statistics_provider.g.dart';

@riverpod
Stream<PlayerStats> playerStats(Ref ref, String playerId) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.watchPlayerStats(playerId);
}

@riverpod
Stream<GameStats> liveGameStats(Ref ref, String gameId) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.watchGameStats(gameId);
}

@riverpod
class Leaderboard extends _$Leaderboard {
  GameType _gameType = GameType.x01;
  int _minGames = 5;
  String _metric = 'threeDartAverage';

  @override
  Future<List<PlayerStats>> build() async {
    final repository = ref.read(statisticsRepositoryProvider);
    return repository.getLeaderboard(
      gameType: _gameType,
      minGames: _minGames,
    );
  }

  void setGameType(GameType gameType) {
    _gameType = gameType;
    ref.invalidateSelf();
  }

  void setMinGames(int min) {
    _minGames = min;
    ref.invalidateSelf();
  }

  void setMetric(String metric) {
    _metric = metric;
    ref.invalidateSelf();
  }
}
