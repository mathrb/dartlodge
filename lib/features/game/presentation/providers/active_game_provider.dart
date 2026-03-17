import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/models/game_config.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/models/game_state.dart';
import '../state/active_game_state.dart';
import '../../../../core/persistence/database_provider.dart';

part 'active_game_provider.g.dart';

@riverpod
class ActiveGameNotifier extends _$ActiveGameNotifier {
  @override
  Future<ActiveGameState?> build(String gameId) async {
    final game = await ref.read(gameRepositoryProvider).getGame(gameId);
    if (game == null) return null;

    final competitors =
        await ref.read(gameRepositoryProvider).getCompetitors(gameId);
    final events =
        await ref.read(gameEventRepositoryProvider).getEventsForGame(gameId);

    final engine = ref.read(x01EngineProvider);
    var gs = GameState.initial(game, competitors);
    for (final event in events) {
      gs = engine.apply(gs, event).state;
    }

    return ActiveGameState(gameState: gs);
  }

  Future<void> processDart(String segment) async {
    final current = state.value;
    if (current == null) return;

    final gs = current.gameState;
    final oldTurnIndex = gs.currentTurnIndex;
    final oldLegIndex = gs.currentLegIndex;
    final oldDartsThrownInTurn = gs.dartsThrownInTurn;
    final competitor = gs.competitors[oldTurnIndex];

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
          await ref.read(processDartUseCaseProvider).execute(gs, dart);

      // Bust: turn ended before player had a chance to throw 3 full darts
      // (engine forces dartsThrownInTurn=3 on bust), OR the 3rd dart restored
      // the score to a higher value (turnStartScore recovery).
      final showBust = !newGs.turnActive &&
          !newGs.isComplete &&
          (
            // Bust on 1st or 2nd dart: count jumped to 3 immediately
            (oldDartsThrownInTurn < 2 && newGs.dartsThrownInTurn == 3) ||
            // Bust on 3rd dart: score was restored (higher than pre-dart score)
            newGs.competitors[oldTurnIndex].score >
                gs.competitors[oldTurnIndex].score
          );

      final legCompleted =
          newGs.currentLegIndex > oldLegIndex && !newGs.isComplete;
      final pendingLegWinnerId =
          legCompleted ? competitor.competitorId : null;

      final pendingGameWinnerId =
          newGs.isComplete ? newGs.winnerCompetitorId : null;

      return ActiveGameState(
        gameState: newGs,
        showBust: showBust,
        pendingLegWinnerId: pendingLegWinnerId,
        pendingGameWinnerId: pendingGameWinnerId,
      );
    });
  }

  /// Advances to the next player's turn. Called when the user taps NEXT ROUND
  /// after all 3 darts have been thrown (or after a bust). Appends TurnEnded
  /// and TurnStarted events to the event log.
  Future<void> startNextTurn() async {
    final current = state.value;
    if (current == null) return;
    final gs = current.gameState;
    if (gs.isComplete || gs.turnActive) return;

    state = await AsyncValue.guard(() async {
      int nextSeq =
          await ref.read(gameEventRepositoryProvider).getLatestSequence(gs.gameId) + 1;

      final currentCompetitor = gs.competitors[gs.currentTurnIndex];
      final actorId = currentCompetitor.playerIds.isNotEmpty
          ? currentCompetitor.playerIds.first
          : 'system';

      final turnEndedEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: gs.gameId,
        eventType: 'TurnEnded',
        localSequence: nextSeq++,
        occurredAt: DateTime.now(),
        payload: {
          'competitor_id': currentCompetitor.competitorId,
          'player_id': actorId,
          'reason': current.showBust ? 'bust' : 'normal',
        },
        synced: false,
        actorId: actorId,
        source: EventSource.client,
      );

      final engine = ref.read(x01EngineProvider);
      var newGs = engine.apply(gs, turnEndedEvent).state;

      final nextCompetitor = newGs.competitors[newGs.currentTurnIndex];
      final nextActorId = nextCompetitor.playerIds.isNotEmpty
          ? nextCompetitor.playerIds.first
          : 'system';

      final turnStartedEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: gs.gameId,
        eventType: 'TurnStarted',
        localSequence: nextSeq++,
        occurredAt: DateTime.now(),
        payload: {
          'competitor_id': nextCompetitor.competitorId,
          'player_id': nextActorId,
          'starting_score': nextCompetitor.score,
          'turn_index': newGs.currentTurnIndex,
          'leg_index': newGs.currentLegIndex,
        },
        synced: false,
        actorId: nextActorId,
        source: EventSource.client,
      );

      newGs = engine.apply(newGs, turnStartedEvent).state;

      await ref
          .read(gameEventRepositoryProvider)
          .appendEvents([turnEndedEvent, turnStartedEvent]);

      return ActiveGameState(gameState: newGs);
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
          .read(undoLastDartUseCaseProvider)
          .execute(current.gameState);
      return ActiveGameState(gameState: newGs);
    });
  }

  void dismissBust() {
    state = state.whenData((s) => s?.copyWith(showBust: false));
  }

  void dismissLegModal() {
    state = state.whenData((s) => s?.copyWith(pendingLegWinnerId: null));
  }

  void dismissGameModal() {
    state = state.whenData((s) => s?.copyWith(pendingGameWinnerId: null));
  }
}
