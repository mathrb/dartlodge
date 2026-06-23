import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/engines/base_game_engine.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/models/game_config.dart';
import '../../domain/usecases/game_use_case_helpers.dart';
import '../state/active_count_up_state.dart';
import '../../../../core/persistence/database_provider.dart';
import 'action_serializer.dart';
import 'game_replay_provider.dart';

part 'active_count_up_provider.g.dart';

/// Active-game notifier for count-up.
///
/// Mirrors [ActiveGameNotifier] (X01) but trimmed for count-up's simpler
/// rules: no bust, single leg, no round-cap dialog. The game ends only on
/// the TurnEnded that follows the last competitor of the last round; the
/// engine's [LegOutcome.gameCompleted] result drives that transition.
@riverpod
class ActiveCountUpNotifier extends _$ActiveCountUpNotifier {
  final ActionSerializer _serializer = ActionSerializer();

  @override
  Future<ActiveCountUpState?> build(String gameId) async {
    final gs = await ref.read(loadedGameStateProvider(gameId).future);
    if (gs == null) return null;
    return ActiveCountUpState(gameState: gs);
  }

  Future<void> processDart(String segment) =>
      _serializer.run(() => _processDartImpl(segment));

  Future<void> _processDartImpl(String segment) async {
    final current = state.value;
    if (current == null) return;

    final gs = current.gameState;
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
          await ref.read(processCountUpDartUseCaseProvider).execute(gs, dart);
      return ActiveCountUpState(
        gameState: newGs,
        pendingGameWinnerId:
            newGs.isComplete ? newGs.winnerCompetitorId : null,
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

  Future<void> undoDart() => _serializer.run(_undoDartImpl);

  Future<void> _undoDartImpl() async {
    if (!canUndo) return;
    final current = state.value;
    if (current == null) return;
    state = await AsyncValue.guard(() async {
      final newGs = await ref
          .read(undoCountUpLastDartUseCaseProvider)
          .execute(current.gameState);
      return ActiveCountUpState(gameState: newGs);
    });
  }

  /// Fills the current turn with MISS darts (if needed) then advances the turn.
  /// If the engine reports gameCompleted, persist LegCompleted + GameCompleted
  /// and finalize the game; otherwise emit TurnStarted for the next competitor.
  Future<void> advanceTurn() => _serializer.run(_advanceTurnImpl);

  Future<void> _advanceTurnImpl() async {
    var gs = state.value?.gameState;
    while (gs != null && gs.turnActive) {
      await _processDartImpl('MISS');
      gs = state.value?.gameState;
    }
    await _startNextTurn();
  }

  Future<void> _startNextTurn() async {
    final current = state.value;
    if (current == null) return;
    final gs = current.gameState;
    if (gs.isComplete || gs.turnActive) return;

    state = await AsyncValue.guard(() async {
      int nextSeq = await ref
              .read(gameEventRepositoryProvider)
              .getLatestSequence(gs.gameId) +
          1;

      final currentCompetitor = gs.competitors[gs.currentTurnIndex];
      final actorId = currentCompetitor.playerIds.isNotEmpty
          ? currentCompetitor.playerIds.first
          : 'system';

      // The TurnEnded that closes this turn was ALREADY persisted by
      // ProcessDartUseCase when the 3rd dart landed (turnActive went false) —
      // count-up reuses that X01-shaped use case. Re-apply a TRANSIENT copy
      // (localSequence -1, NOT appended) so the engine computes the post-turn
      // state — round advance + game-completion — without writing a SECOND
      // TurnEnded. A duplicate persisted TurnEnded is replayed by both
      // cold-load and undo, double-advancing currentRoundInLeg (#656 / the
      // undo regression that surfaced it). Mirrors ActiveGameNotifier
      // (X01) _startNextTurn.
      final transientTurnEnded = buildTurnEndedEvent(
        gameId: gs.gameId,
        competitorId: currentCompetitor.competitorId,
        playerId: actorId,
        localSequence: -1,
        actorId: actorId,
      );

      final engine = ref.read(countUpEngineProvider);
      final result = engine.apply(gs, transientTurnEnded);
      var newGs = result.state;
      final eventsToStore = <GameEvent>[];

      if (result.outcome == LegOutcome.gameCompleted) {
        final winnerId = result.winnerCompetitorId;
        final winnerPlayerId = getPlayerIdForCompetitor(gs, winnerId);
        eventsToStore.add(buildLegCompletedEvent(
          gameId: gs.gameId,
          winnerCompetitorId: winnerId,
          localSequence: nextSeq++,
          winnerPlayerId: winnerPlayerId,
        ));
        eventsToStore.add(buildGameCompletedEvent(
          gameId: gs.gameId,
          winnerCompetitorId: winnerId,
          localSequence: nextSeq++,
          winnerPlayerId: winnerPlayerId,
        ));
        await ref
            .read(gameEventRepositoryProvider)
            .appendEvents(eventsToStore);
        await ref.read(gameRepositoryProvider).completeGame(
              gameId: gs.gameId,
              winnerCompetitorId: winnerId,
              endTime: DateTime.now(),
            );
        return ActiveCountUpState(
          gameState: newGs,
          pendingGameWinnerId: winnerId,
        );
      }

      // Mid-game: kick off the next competitor's turn.
      final nextCompetitor = newGs.competitors[newGs.currentTurnIndex];
      final nextActorId = nextCompetitor.playerIds.isNotEmpty
          ? nextCompetitor.playerIds.first
          : 'system';
      final turnStartedEvent = buildTurnStartedEvent(
        gameId: gs.gameId,
        competitorId: nextCompetitor.competitorId,
        playerId: nextActorId,
        localSequence: nextSeq++,
        actorId: nextActorId,
        turnIndex: newGs.currentTurnIndex,
        legIndex: newGs.currentLegIndex,
        startingScore: nextCompetitor.score,
      );
      eventsToStore.add(turnStartedEvent);
      newGs = engine.apply(newGs, turnStartedEvent).state;

      await ref
          .read(gameEventRepositoryProvider)
          .appendEvents(eventsToStore);

      return ActiveCountUpState(gameState: newGs);
    });
  }

  void dismissGameModal() {
    state = state.whenData((s) => s?.copyWith(pendingGameWinnerId: null));
  }
}
