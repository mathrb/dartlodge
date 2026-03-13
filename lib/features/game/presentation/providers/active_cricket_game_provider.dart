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

  bool get canUndo {
    final s = state.value;
    if (s == null) return false;
    final gs = s.gameState;
    return gs.dartsThrownInTurn > 0 ||
        gs.competitors.any((c) => c.dartThrows.isNotEmpty);
  }

  Future<void> undoDart() async {
    if (!canUndo) return;
    final current = state.value;
    if (current == null) return;

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

  Future<void> nextPlayer() async {
    final current = state.value;
    if (current == null) return;
    var updated = current.gameState;
    while (updated.dartsThrownInTurn < 3 && !updated.isComplete) {
      updated = await ref.read(processCricketDartUseCaseProvider).execute(
            updated,
            _makeMissDart(updated),
          );
    }
    final pendingGameWinnerId =
        updated.isComplete ? updated.winnerCompetitorId : null;
    state = AsyncData(ActiveCricketGameState(
      gameState: updated,
      pendingGameWinnerId: pendingGameWinnerId,
    ));
  }

  DartThrow _makeMissDart(GameState gs) {
    final competitor = gs.competitors[gs.currentTurnIndex];
    return DartThrow(
      dartId: const Uuid().v4(),
      gameId: gs.gameId,
      competitorId: competitor.competitorId,
      playerId: competitor.playerIds.isNotEmpty
          ? competitor.playerIds.first
          : 'sentinel',
      turnNumber: gs.currentLegIndex,
      dartNumber: gs.dartsThrownInTurn + 1,
      segment: 'MISS',
      score: 0,
    );
  }
}
