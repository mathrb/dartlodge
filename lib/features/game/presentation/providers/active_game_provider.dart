import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/engines/base_game_engine.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/models/game_config.dart';
import '../../domain/usecases/game_use_case_helpers.dart';
import '../state/active_game_state.dart';
import '../../../../core/persistence/database_provider.dart';
import 'game_replay_provider.dart';

part 'active_game_provider.g.dart';

@riverpod
class ActiveGameNotifier extends _$ActiveGameNotifier {
  @override
  Future<ActiveGameState?> build(String gameId) async {
    final gs = await ref.read(loadedGameStateProvider(gameId).future);
    if (gs == null) return null;
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

        // Bust: dartsThrownInTurn jumped to 3 before 3 darts were thrown, or
      // score was restored (bust on 3rd dart).
      final showBust = !newGs.turnActive &&
          !newGs.isComplete &&
          ((oldDartsThrownInTurn < 2 && newGs.dartsThrownInTurn == 3) ||
              newGs.competitors[oldTurnIndex].score >
                  gs.competitors[oldTurnIndex].score);

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

  Future<void> _startNextTurn() async {
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

      final turnEndedEvent = buildTurnEndedEvent(
        gameId: gs.gameId,
        competitorId: currentCompetitor.competitorId,
        playerId: actorId,
        localSequence: nextSeq++,
        actorId: actorId,
        reason: current.showBust ? 'bust' : 'normal',
      );

      final engine = ref.read(x01EngineProvider);
      final turnEndedResult = engine.apply(gs, turnEndedEvent);
      var newGs = turnEndedResult.state;
      final eventsToStore = <GameEvent>[turnEndedEvent];

      if (turnEndedResult.outcome == LegOutcome.roundCapReached) {
        await ref
            .read(gameEventRepositoryProvider)
            .appendEvents([turnEndedEvent]);
        return ActiveGameState(
          gameState: newGs,
          pendingCapSelection: true,
        );
      }

      if (turnEndedResult.outcome == LegOutcome.gameCompleted) {
        final winnerId = turnEndedResult.winnerCompetitorId;
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
        return ActiveGameState(
          gameState: newGs,
          pendingGameWinnerId: winnerId,
        );
      }

      if (turnEndedResult.outcome == LegOutcome.legCompleted) {
        final winnerId = turnEndedResult.winnerCompetitorId;
        final winnerPlayerId = getPlayerIdForCompetitor(gs, winnerId);
        eventsToStore.add(buildLegCompletedEvent(
          gameId: gs.gameId,
          winnerCompetitorId: winnerId,
          localSequence: nextSeq++,
          winnerPlayerId: winnerPlayerId,
        ));

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
        return ActiveGameState(
          gameState: newGs,
          pendingLegWinnerId: winnerId,
        );
      }

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

      newGs = engine.apply(newGs, turnStartedEvent).state;
      eventsToStore.add(turnStartedEvent);

      await ref
          .read(gameEventRepositoryProvider)
          .appendEvents(eventsToStore);

      return ActiveGameState(gameState: newGs);
    });
  }

  /// Finalizes an ambiguous round-cap leg after the UI picks a winner. Emits
  /// a synthetic LegCompleted through the engine so Table J / K / L fire
  /// uniformly.
  Future<void> selectCapWinner(String competitorId) async {
    final current = state.value;
    if (current == null || !current.pendingCapSelection) return;
    final gs = current.gameState;

    state = await AsyncValue.guard(() async {
      int nextSeq = await ref
              .read(gameEventRepositoryProvider)
              .getLatestSequence(gs.gameId) +
          1;

      final winnerPlayerId = getPlayerIdForCompetitor(gs, competitorId);
      final legCompletedEvent = buildLegCompletedEvent(
        gameId: gs.gameId,
        winnerCompetitorId: competitorId,
        localSequence: nextSeq++,
        winnerPlayerId: winnerPlayerId,
      );

      final engine = ref.read(x01EngineProvider);
      final legResult = engine.apply(gs, legCompletedEvent);
      var newGs = legResult.state;
      final eventsToStore = <GameEvent>[legCompletedEvent];

      if (legResult.outcome == LegOutcome.gameCompleted) {
        eventsToStore.add(buildGameCompletedEvent(
          gameId: gs.gameId,
          winnerCompetitorId: competitorId,
          localSequence: nextSeq++,
          winnerPlayerId: winnerPlayerId,
        ));
        await ref
            .read(gameEventRepositoryProvider)
            .appendEvents(eventsToStore);
        await ref.read(gameRepositoryProvider).completeGame(
              gameId: gs.gameId,
              winnerCompetitorId: competitorId,
              endTime: DateTime.now(),
            );
        return ActiveGameState(
          gameState: newGs,
          pendingCapSelection: false,
          pendingGameWinnerId: competitorId,
        );
      }

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

      await ref.read(gameEventRepositoryProvider).appendEvents(eventsToStore);
      return ActiveGameState(
        gameState: newGs,
        pendingCapSelection: false,
        pendingLegWinnerId: competitorId,
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

  Future<void> advanceTurn() async {
    dismissBust();
    dismissLegModal();
    var gs = state.value?.gameState;
    while (gs != null && gs.turnActive) {
      await processDart('MISS');
      gs = state.value?.gameState;
    }
    await _startNextTurn();
  }

  void dismissGameModal() {
    state = state.whenData((s) => s?.copyWith(pendingGameWinnerId: null));
  }
}
