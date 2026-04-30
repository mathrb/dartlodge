import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
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
    final dartRepo = ref.read(dartThrowRepositoryProvider);
    final statsRepo = ref.read(statisticsRepositoryProvider);
    final computeLegStats = ref.read(computeLegStatsUseCaseProvider);

    Game? game;
    List<Competitor> competitors = [];
    List<GameEvent> events = [];
    List<DartThrow> darts = [];
    GameStats? gameStats;

    await Future.wait([
      gameRepo.getGame(gameId).then((v) => game = v),
      gameRepo.getCompetitors(gameId).then((v) => competitors = v),
      eventRepo.getEventsForGame(gameId).then((v) => events = v),
      dartRepo.getDartsForGame(gameId).then((v) => darts = v),
      statsRepo.getGameStats(gameId).then((v) => gameStats = v),
    ]);

    if (game == null) return null;

    final sortedEvents = [...events]
      ..sort((a, b) => a.localSequence.compareTo(b.localSequence));
    final sortedDarts = [...darts]
      ..sort((a, b) {
        final t = a.turnNumber.compareTo(b.turnNumber);
        return t != 0 ? t : a.dartNumber.compareTo(b.dartNumber);
      });

    final legStats = computeLegStats.execute(
      events: sortedEvents,
      competitors: competitors,
      gameType: game!.gameType,
    );

    return GameDetailState(
      game: game,
      competitors: competitors,
      events: sortedEvents,
      darts: sortedDarts,
      gameStats: gameStats,
      legStats: legStats,
    );
  }
}
