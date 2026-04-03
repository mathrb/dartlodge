import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../state/active_cricket_game_state.dart';
import '../../../../core/persistence/database_provider.dart';
import '../../../../core/utils/constants.dart';
import 'game_replay_provider.dart';

part 'active_cricket_game_provider.g.dart';

@riverpod
class ActiveCricketGameNotifier extends _$ActiveCricketGameNotifier {
  @override
  Future<ActiveCricketGameState?> build(String gameId) async {
    final gs = await ref.read(loadedGameStateProvider(gameId).future);
    if (gs == null) return null;
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
    if (updated.isComplete) return;

    state = await AsyncValue.guard(() async {
      // Fill any remaining darts in this turn with MISS
      while (updated.dartsThrownInTurn < 3 && !updated.isComplete) {
        updated = await ref.read(processCricketDartUseCaseProvider).execute(
              updated,
              _makeMissDart(updated),
            );
      }

      if (updated.isComplete) {
        return ActiveCricketGameState(
          gameState: updated,
          pendingGameWinnerId: updated.winnerCompetitorId,
        );
      }

      // Emit TurnEnded + TurnStarted for next player
      int nextSeq = await ref
              .read(gameEventRepositoryProvider)
              .getLatestSequence(updated.gameId) +
          1;

      final currentCompetitor = updated.competitors[updated.currentTurnIndex];
      final actorId = currentCompetitor.playerIds.isNotEmpty
          ? currentCompetitor.playerIds.first
          : 'system';

      final turnEndedEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: updated.gameId,
        eventType: 'TurnEnded',
        localSequence: nextSeq++,
        occurredAt: DateTime.now(),
        payload: {
          'competitor_id': currentCompetitor.competitorId,
          'player_id': actorId,
          'reason': 'normal',
        },
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );

      final engine = ref.read(cricketEngineProvider);
      updated = engine.apply(updated, turnEndedEvent).state;

      final nextCompetitor = updated.competitors[updated.currentTurnIndex];
      final nextActorId = nextCompetitor.playerIds.isNotEmpty
          ? nextCompetitor.playerIds.first
          : 'system';

      final turnStartedEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: updated.gameId,
        eventType: 'TurnStarted',
        localSequence: nextSeq++,
        occurredAt: DateTime.now(),
        payload: {
          'competitor_id': nextCompetitor.competitorId,
          'player_id': nextActorId,
          'turn_index': updated.currentTurnIndex,
          'leg_index': updated.currentLegIndex,
        },
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );

      updated = engine.apply(updated, turnStartedEvent).state;

      await ref.read(gameEventRepositoryProvider).appendEvents([
        turnEndedEvent,
        turnStartedEvent,
      ]);

      return ActiveCricketGameState(gameState: updated);
    });
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
