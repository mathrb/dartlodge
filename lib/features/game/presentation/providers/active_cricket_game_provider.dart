import 'dart:math' as math;

import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/engines/base_game_engine.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/turn_dart_resolver.dart';
import '../../domain/usecases/game_use_case_helpers.dart';
import '../state/active_cricket_game_state.dart';
import '../../../../core/error/repository_exception.dart';
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

  Future<void> processDart(String segment,
          {String inputMethod = 'manual', double? x, double? y}) =>
      _serializer.run(
          () => _processDartImpl(segment, inputMethod: inputMethod, x: x, y: y));

  Future<void> _processDartImpl(String segment,
      {String inputMethod = 'manual', double? x, double? y}) async {
    final current = state.value;
    if (current == null) return;

    final gs = current.gameState;

    // A stray camera dart on a full/ended turn (or completed game) must never
    // flip the provider to AsyncError — it is best-effort input. The turn/game
    // can be ahead of the tracker after a manual entry + later re-detection
    // (#538). Return before AsyncValue.guard so the error channel is untouched;
    // manual entry is unaffected (its UI is already gated on turnActive).
    if (inputMethod == 'camera' && (gs.isComplete || !gs.turnActive)) {
      return;
    }

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
      x: x,
      y: y,
    );

    state = await AsyncValue.guard(() async {
      final newGs = await ref
          .read(processCricketDartUseCaseProvider)
          .execute(gs, dart, inputMethod: inputMethod);

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

  /// Per-dart correction (#376): replaces dart [turnDartIndex] of the active
  /// turn (0-based, throw order) with [newSegment]. Resolves the dart's
  /// `DartThrown` event id on demand from the log, then delegates to
  /// `CorrectDartUseCase`. No-op on a completed game or an out-of-range index.
  Future<void> correctTurnDart(int turnDartIndex, String newSegment) =>
      _serializer.run(() => _correctTurnDartImpl(turnDartIndex, newSegment));

  Future<void> _correctTurnDartImpl(
      int turnDartIndex, String newSegment) async {
    final current = state.value;
    if (current == null) return;
    final gs = current.gameState;
    if (gs.isComplete) return;

    final turnDart = await _resolveTurnDart(gs, turnDartIndex);
    if (turnDart == null) return;
    final eventId = turnDart.eventId;

    final parsed = Segment.parse(newSegment);
    final pendingGameWinnerId = gs.winnerCompetitorId;

    state = await AsyncValue.guard(() async {
      final newGs = await ref.read(correctCricketDartUseCaseProvider).execute(
            gs,
            originalEventId: eventId,
            segment: parsed.baseNumber,
            multiplier: parsed.multiplier,
          );
      // Cricket: legsToWin == 1, so a leg win coincides with the game win;
      // there is no separate pending-leg modal to surface here.
      return ActiveCricketGameState(
        gameState: newGs,
        pendingGameWinnerId:
            newGs.isComplete ? newGs.winnerCompetitorId : pendingGameWinnerId,
      );
    });

    // Best-effort: propagate the correction into the auto-scorer capture for
    // this (current-turn) dart, only if the correction itself succeeded (#456).
    // Skip a manually-entered dart — it has no camera capture (#469). No-op
    // when no auto-scoring session is bound.
    final cameraOrdinal = turnDart.cameraDartOrdinal;
    if (!state.hasError && cameraOrdinal != null) {
      ref.read(activeCaptureCorrectionSinkProvider)?.correctDart(
            cameraDartOrdinal: cameraOrdinal,
            segment: newSegment,
          );
    }
  }

  /// Resolves the live current-turn dart at [turnDartIndex] (0-based, throw
  /// order) — its event id plus the camera-only ordinal the auto-scorer keys
  /// captures on (null for a manual dart). See [resolveTurnDart].
  Future<TurnDartRef?> _resolveTurnDart(
      GameState gs, int turnDartIndex) async {
    final events = await ref
        .read(gameEventRepositoryProvider)
        .getEventsForGame(gs.gameId);
    return resolveTurnDart(
      events: events,
      competitorId: gs.competitors[gs.currentTurnIndex].competitorId,
      dartsThrownInTurn: gs.dartsThrownInTurn,
      turnDartIndex: turnDartIndex,
    );
  }

  void dismissLegModal() {
    state = state.whenData((s) => s?.copyWith(pendingLegWinnerId: null));
  }

  void dismissGameModal() {
    state = state.whenData((s) => s?.copyWith(pendingGameWinnerId: null));
  }

  /// Abandons the current game: emits a `GameCompleted(winner=null)` event
  /// AND atomically marks the game complete so it appears in history
  /// (issue #252). No-op if the game has already finished naturally through
  /// play (engine-driven completion already ran the proper
  /// `appendEventsAndCompleteGame` path).
  ///
  /// Goes through `appendEventsAndCompleteGame` — not bare `completeGame` —
  /// to honour the #188 invariant: events + `games.is_complete` must never
  /// diverge. Mirrors `EndPracticeUseCase.execute`.
  Future<void> endGame() => _serializer.run(_endGameImpl);

  Future<void> _endGameImpl() async {
    final current = state.value;
    if (current == null) return;
    final gs = current.gameState;
    if (gs.isComplete) return;
    try {
      final nextSeq =
          await ref.read(gameEventRepositoryProvider).getLatestSequence(gs.gameId) +
              1;
      final gameCompleted = buildGameCompletedEvent(
        gameId: gs.gameId,
        winnerCompetitorId: null,
        localSequence: nextSeq,
      );
      await ref.read(gameRepositoryProvider).appendEventsAndCompleteGame(
            events: [gameCompleted],
            gameId: gs.gameId,
            winnerCompetitorId: null,
            endTime: DateTime.now(),
          );
    } on GameAlreadyCompleteException {
      // Idempotent — another path (e.g. concurrent navigation) already
      // abandoned the game.
    }
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
