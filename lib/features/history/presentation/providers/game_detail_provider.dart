import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
import 'package:dart_lodge/features/history/presentation/state/game_detail_state.dart';

part 'game_detail_provider.g.dart';

@riverpod
class GameDetailNotifier extends _$GameDetailNotifier {
  @override
  Future<GameDetailState?> build(String gameId) async {
    final gameRepo = ref.read(gameRepositoryProvider);
    final eventRepo = ref.read(gameEventRepositoryProvider);
    final statsRepo = ref.read(statisticsRepositoryProvider);
    final computeLegStats = ref.read(computeLegStatsUseCaseProvider);

    Game? game;
    List<Competitor> competitors = [];
    List<GameEvent> events = [];
    GameStats? gameStats;

    await Future.wait([
      gameRepo.getGame(gameId).then((v) => game = v),
      gameRepo.getCompetitors(gameId).then((v) => competitors = v),
      eventRepo.getEventsForGame(gameId).then((v) => events = v),
      statsRepo.getGameStats(gameId).then((v) => gameStats = v),
    ]);

    if (game == null) return null;

    final sortedEvents = [...events]
      ..sort((a, b) => a.localSequence.compareTo(b.localSequence));

    final legStats = computeLegStats.execute(
      events: sortedEvents,
      competitors: competitors,
      gameType: game!.gameType,
    );

    return GameDetailState(
      game: game,
      competitors: competitors,
      events: sortedEvents,
      gameStats: gameStats,
      legStats: legStats,
    );
  }
}
