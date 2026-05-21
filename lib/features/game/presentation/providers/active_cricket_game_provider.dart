import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/engines/base_game_engine.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/usecases/game_use_case_helpers.dart';
import '../state/active_cricket_game_state.dart';
import '../../../../core/persistence/database_provider.dart';
import 'action_serializer.dart';
import 'game_replay_provider.dart';

part 'active_cricket_game_provider.g.dart';

@riverpod
class ActiveCricketGameNotifier extends _$ActiveCricketGameNotifier {
  final ActionSerializer _serializer = ActionSerializer();
  // Crazy Cricket: turn-start RNG. Held as a notifier field for stable
  // replay in widget tests (override the family if a deterministic seed
  // is needed).
  final math.Random _random = math.Random();

  @override
  Future<ActiveCricketGameState?> build(String gameId) async {
    final gs = await ref.read(loadedGameStateProvider(gameId).future);
    if (gs == null) return null;
    return ActiveCricketGameState(gameState: gs);
  }

  Future<void> processDart(String segment) =>
      _serializer.run(() => _processDartImpl(segment));

  Future<void> _processDartImpl(String segment) async {
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

  Future<void> undoDart() => _serializer.run(_undoDartImpl);

  Future<void> _undoDartImpl() async {
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

  Future<void> nextPlayer() => _serializer.run(_nextPlayerImpl);

  Future<void> _nextPlayerImpl() async {
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

      // The TurnEnded event was already persisted by ProcessCricketDartUseCase
      // when the turn ended (3rd real dart or MISS-fill in the loop above).
      // Re-fetch the latest sequence so any newly emitted events here pick up
      // sequence numbers after that TurnEnded. We re-apply a TRANSIENT
      // TurnEnded through the engine locally (NOT persisting it again) so the
      // engine outcome — round-cap, leg, or game — drives what happens next.
      // Mirrors the X01 ActiveGameNotifier._startNextTurn pattern.
      int nextSeq = await ref
              .read(gameEventRepositoryProvider)
              .getLatestSequence(updated.gameId) +
          1;

      final currentCompetitor = updated.competitors[updated.currentTurnIndex];
      final actorId = currentCompetitor.playerIds.isNotEmpty
          ? currentCompetitor.playerIds.first
          : 'system';

      // Construct a transient TurnEnded matching the one already in the log
      // so the engine can compute the post-turn state. NOT appended.
      final transientTurnEnded = buildTurnEndedEvent(
        gameId: updated.gameId,
        competitorId: currentCompetitor.competitorId,
        playerId: actorId,
        localSequence: -1,
        actorId: actorId,
      );

      final engine = ref.read(cricketEngineProvider);
      final turnEndedResult = engine.apply(updated, transientTurnEnded);
      updated = turnEndedResult.state;
      final eventsToStore = <GameEvent>[];

      if (turnEndedResult.outcome == LegOutcome.roundCapReached) {
        return ActiveCricketGameState(
          gameState: updated,
          pendingCapSelection: true,
        );
      }

      if (turnEndedResult.outcome == LegOutcome.gameCompleted) {
        final winnerId = turnEndedResult.winnerCompetitorId;
        final winnerPlayerId = getPlayerIdForCompetitor(updated, winnerId);
        eventsToStore.add(buildLegCompletedEvent(
          gameId: updated.gameId,
          winnerCompetitorId: winnerId,
          localSequence: nextSeq++,
          winnerPlayerId: winnerPlayerId,
        ));
        eventsToStore.add(buildGameCompletedEvent(
          gameId: updated.gameId,
          winnerCompetitorId: winnerId,
          localSequence: nextSeq++,
          winnerPlayerId: winnerPlayerId,
        ));
        await ref
            .read(gameEventRepositoryProvider)
            .appendEvents(eventsToStore);
        await ref.read(gameRepositoryProvider).completeGame(
              gameId: updated.gameId,
              winnerCompetitorId: winnerId,
              endTime: DateTime.now(),
            );
        return ActiveCricketGameState(
          gameState: updated,
          pendingGameWinnerId: winnerId,
        );
      }

      if (turnEndedResult.outcome == LegOutcome.legCompleted) {
        final winnerId = turnEndedResult.winnerCompetitorId;
        final winnerPlayerId = getPlayerIdForCompetitor(updated, winnerId);
        eventsToStore.add(buildLegCompletedEvent(
          gameId: updated.gameId,
          winnerCompetitorId: winnerId,
          localSequence: nextSeq++,
          winnerPlayerId: winnerPlayerId,
        ));

        final nextCompetitor = updated.competitors[updated.currentTurnIndex];
        final nextActorId = nextCompetitor.playerIds.isNotEmpty
            ? nextCompetitor.playerIds.first
            : 'system';
        final turnStartedEvent = buildTurnStartedEvent(
          gameId: updated.gameId,
          competitorId: nextCompetitor.competitorId,
          playerId: nextActorId,
          localSequence: nextSeq++,
          actorId: nextActorId,
          turnIndex: updated.currentTurnIndex,
          legIndex: updated.currentLegIndex,
        );
        eventsToStore.add(turnStartedEvent);
        updated = engine.apply(updated, turnStartedEvent).state;

        if (updated.cricketTargetMode == 'crazy') {
          final rollEvent = buildCrazyTargetsRolledEvent(
            gameId: updated.gameId,
            competitorId: nextCompetitor.competitorId,
            round: updated.currentRoundInLeg,
            openTargets: rollCrazyOpenTargets(
              locked: updated.cricketLockedTargets,
              random: _random,
            ),
            localSequence: nextSeq++,
          );
          eventsToStore.add(rollEvent);
          updated = engine.apply(updated, rollEvent).state;
        }

        await ref
            .read(gameEventRepositoryProvider)
            .appendEvents(eventsToStore);
        return ActiveCricketGameState(
          gameState: updated,
          pendingLegWinnerId: winnerId,
        );
      }

      final nextCompetitor = updated.competitors[updated.currentTurnIndex];
      final nextActorId = nextCompetitor.playerIds.isNotEmpty
          ? nextCompetitor.playerIds.first
          : 'system';

      final turnStartedEvent = buildTurnStartedEvent(
        gameId: updated.gameId,
        competitorId: nextCompetitor.competitorId,
        playerId: nextActorId,
        localSequence: nextSeq++,
        actorId: nextActorId,
        turnIndex: updated.currentTurnIndex,
        legIndex: updated.currentLegIndex,
      );

      updated = engine.apply(updated, turnStartedEvent).state;
      eventsToStore.add(turnStartedEvent);

      if (updated.cricketTargetMode == 'crazy') {
        final rollEvent = buildCrazyTargetsRolledEvent(
          gameId: updated.gameId,
          competitorId: nextCompetitor.competitorId,
          round: updated.currentRoundInLeg,
          openTargets: rollCrazyOpenTargets(
            locked: updated.cricketLockedTargets,
            random: _random,
          ),
          localSequence: nextSeq++,
        );
        eventsToStore.add(rollEvent);
        updated = engine.apply(updated, rollEvent).state;
      }

      await ref
          .read(gameEventRepositoryProvider)
          .appendEvents(eventsToStore);

      return ActiveCricketGameState(gameState: updated);
    });
  }

  /// Finalizes an ambiguous round-cap leg after the UI picks a winner. Emits
  /// a synthetic LegCompleted through the engine so Table J / K / L fire
  /// uniformly.
  Future<void> selectCapWinner(String competitorId) =>
      _serializer.run(() => _selectCapWinnerImpl(competitorId));

  Future<void> _selectCapWinnerImpl(String competitorId) async {
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

      final engine = ref.read(cricketEngineProvider);
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
        return ActiveCricketGameState(
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
      );
      eventsToStore.add(turnStartedEvent);
      newGs = engine.apply(newGs, turnStartedEvent).state;

      if (newGs.cricketTargetMode == 'crazy') {
        final rollEvent = buildCrazyTargetsRolledEvent(
          gameId: newGs.gameId,
          competitorId: nextCompetitor.competitorId,
          round: newGs.currentRoundInLeg,
          openTargets: rollCrazyOpenTargets(
            locked: newGs.cricketLockedTargets,
            random: _random,
          ),
          localSequence: nextSeq++,
        );
        eventsToStore.add(rollEvent);
        newGs = engine.apply(newGs, rollEvent).state;
      }

      await ref.read(gameEventRepositoryProvider).appendEvents(eventsToStore);
      return ActiveCricketGameState(
        gameState: newGs,
        pendingCapSelection: false,
        pendingLegWinnerId: competitorId,
      );
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
