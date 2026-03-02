import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../state/active_cricket_game_state.dart';
import '../../../../core/persistence/database_provider.dart';

part 'active_cricket_game_provider.g.dart';

@riverpod
class ActiveCricketGameNotifier extends _$ActiveCricketGameNotifier {
  @override
  Future<ActiveCricketGameState?> build(String gameId) async {
    final game = await ref.read(gameRepositoryProvider).getGame(gameId);
    if (game == null) return null;

    final competitors =
        await ref.read(gameRepositoryProvider).getCompetitors(gameId);
    final events =
        await ref.read(gameEventRepositoryProvider).getEventsForGame(gameId);

    final engine = ref.read(cricketEngineProvider);
    var gs = GameState.initial(game, competitors);
    for (final event in events) {
      gs = engine.apply(gs, event).state;
    }

    return ActiveCricketGameState(gameState: gs);
  }

  Future<void> processDart(String segment) async {
    final current = state.value;
    if (current == null) return;

    final gs = current.gameState;
    final oldLegIndex = gs.currentLegIndex;
    final competitor = gs.competitors[gs.currentTurnIndex];

    final dart = DartThrow(
      dartId: const Uuid().v4(),
      gameId: gs.gameId,
      competitorId: competitor.competitorId,
      playerId: competitor.playerIds.isNotEmpty
          ? competitor.playerIds.first
          : 'sentinel',
      turnNumber: gs.currentLegIndex,
      dartNumber: gs.dartsThrownInTurn + 1,
      segment: segment,
      score: Segment.parse(segment).scoreValue,
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newGs =
          await ref.read(processCricketDartUseCaseProvider).execute(gs, dart);

      final legCompleted =
          newGs.currentLegIndex > oldLegIndex && !newGs.isComplete;
      final pendingLegWinnerId =
          legCompleted ? competitor.competitorId : null;

      final pendingGameWinnerId =
          newGs.isComplete ? newGs.winnerCompetitorId : null;

      return ActiveCricketGameState(
        gameState: newGs,
        pendingLegWinnerId: pendingLegWinnerId,
        pendingGameWinnerId: pendingGameWinnerId,
      );
    });
  }

  Future<void> undoDart() async {
    final current = state.value;
    if (current == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newGs = await ref
          .read(undoCricketLastDartUseCaseProvider)
          .execute(current.gameState);
      return ActiveCricketGameState(gameState: newGs);
    });
  }

  void dismissLegModal() {
    state = state.whenData((s) => s?.copyWith(pendingLegWinnerId: null));
  }

  void dismissGameModal() {
    state = state.whenData((s) => s?.copyWith(pendingGameWinnerId: null));
  }
}
