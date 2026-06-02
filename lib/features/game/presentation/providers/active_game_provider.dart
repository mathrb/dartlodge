import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/engines/base_game_engine.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/usecases/game_use_case_helpers.dart';
import '../state/active_game_state.dart';
import '../../../../core/error/repository_exception.dart';
import '../../../../core/persistence/database_provider.dart';
import 'action_serializer.dart';
import 'game_replay_provider.dart';

part 'active_game_provider.g.dart';

@riverpod
class ActiveGameNotifier extends _$ActiveGameNotifier {
  final ActionSerializer _serializer = ActionSerializer();

  @override
  Future<ActiveGameState?> build(String gameId) async {
    final gs = await ref.read(loadedGameStateProvider(gameId).future);
    if (gs == null) return null;
    return ActiveGameState(gameState: gs);
  }

  Future<void> processDart(String segment) =>
      _serializer.run(() => _processDartImpl(segment));

  Future<void> _processDartImpl(String segment) async {
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
      // The TurnEnded event was already persisted by ProcessDartUseCase when
      // the turn ended (3 darts, bust, or leg/game-completing dart). We
      // re-fetch the latest sequence so any newly emitted events here pick up
      // sequence numbers after that TurnEnded. We also re-apply TurnEnded
      // through the engine locally (NOT persisting it again) so the engine
      // outcome — round-cap, leg, or game — drives what happens next.
      int nextSeq = await ref
              .read(gameEventRepositoryProvider)
              .getLatestSequence(gs.gameId) +
          1;

      final currentCompetitor = gs.competitors[gs.currentTurnIndex];
      final actorId = currentCompetitor.playerIds.isNotEmpty
          ? currentCompetitor.playerIds.first
          : 'system';

      // Construct a transient TurnEnded matching the one already in the log
      // so the engine can compute the post-turn state (cap detection,
      // currentTurnIndex rotation). This event is NOT appended.
      final transientTurnEnded = buildTurnEndedEvent(
        gameId: gs.gameId,
        competitorId: currentCompetitor.competitorId,
        playerId: actorId,
        localSequence: -1,
        actorId: actorId,
        reason: current.showBust ? 'bust' : 'normal',
      );

      final engine = ref.read(x01EngineProvider);
      final turnEndedResult = engine.apply(gs, transientTurnEnded);
      var newGs = turnEndedResult.state;
      final eventsToStore = <GameEvent>[];

      if (turnEndedResult.outcome == LegOutcome.roundCapReached) {
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

      // Normal rotation — only TurnStarted is persisted.
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

  Future<void> undoDart() => _serializer.run(_undoDartImpl);

  Future<void> _undoDartImpl() async {
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

    final eventId = await _resolveTurnDartEventId(gs, turnDartIndex);
    if (eventId == null) return;

    final parsed = Segment.parse(newSegment);
    final oldIdx = gs.currentTurnIndex;
    final oldComp = gs.competitors[oldIdx];
    final oldLegIndex = gs.currentLegIndex;

    state = await AsyncValue.guard(() async {
      final newGs = await ref.read(correctDartUseCaseProvider).execute(
            gs,
            originalEventId: eventId,
            segment: parsed.baseNumber,
            multiplier: parsed.multiplier,
          );

      final legCompleted =
          newGs.currentLegIndex > oldLegIndex && !newGs.isComplete;
      final pendingLegWinnerId = legCompleted ? oldComp.competitorId : null;
      final pendingGameWinnerId =
          newGs.isComplete ? newGs.winnerCompetitorId : null;

      // Bust banner: an X01 bust voids the turn and restores the competitor's
      // score to its turn-start value, so detect it by comparing the post-turn
      // score to `turnStartScore` — NOT to the pre-correction score. A plain
      // downward correction in a finished turn also raises the post-turn score
      // relative to the (lower-scoring) original darts without being a bust, so
      // the old `> oldComp.score` check flashed a false bust banner.
      final oldTurnStartScore = oldComp.turnStartScore;
      final showBust = !newGs.turnActive &&
          !newGs.isComplete &&
          !legCompleted &&
          oldIdx == newGs.currentTurnIndex &&
          oldTurnStartScore != null &&
          newGs.competitors[oldIdx].score == oldTurnStartScore;

      return ActiveGameState(
        gameState: newGs,
        showBust: showBust,
        pendingLegWinnerId: pendingLegWinnerId,
        pendingGameWinnerId: pendingGameWinnerId,
      );
    });
  }

  /// Resolves the `DartThrown` event id for dart [turnDartIndex] (0-based,
  /// throw order) of the active competitor's current turn. The current turn is
  /// the last `dartsThrownInTurn` live (non-corrected, non-superseded) darts
  /// for that competitor in the log. Returns null if out of range.
  Future<String?> _resolveTurnDartEventId(
      GameState gs, int turnDartIndex) async {
    final n = gs.dartsThrownInTurn;
    if (turnDartIndex < 0 || turnDartIndex >= n) return null;
    final activeCompId = gs.competitors[gs.currentTurnIndex].competitorId;
    final events = await ref
        .read(gameEventRepositoryProvider)
        .getEventsForGame(gs.gameId);

    final correctedIds = <String>{};
    final supersededIds = <String>{};
    for (final e in events) {
      if (e.eventType != 'DartCorrected') continue;
      final origId = e.payload['original_event_id'];
      if (origId is String) correctedIds.add(origId);
      final superseded = e.payload['superseded_event_ids'];
      if (superseded is List) {
        for (final id in superseded) {
          if (id is String) supersededIds.add(id);
        }
      }
    }

    final liveForComp = [
      for (final e in events)
        if (e.eventType == 'DartThrown' &&
            e.payload['competitor_id'] == activeCompId &&
            !correctedIds.contains(e.eventId) &&
            !supersededIds.contains(e.eventId))
          e,
    ];
    if (liveForComp.length < n) return null;
    return liveForComp.sublist(liveForComp.length - n)[turnDartIndex].eventId;
  }

  void dismissBust() {
    state = state.whenData((s) => s?.copyWith(showBust: false));
  }

  void dismissLegModal() {
    state = state.whenData((s) => s?.copyWith(pendingLegWinnerId: null));
  }

  Future<void> advanceTurn() => _serializer.run(_advanceTurnImpl);

  Future<void> _advanceTurnImpl() async {
    dismissBust();
    dismissLegModal();
    var gs = state.value?.gameState;
    while (gs != null && gs.turnActive) {
      await _processDartImpl('MISS');
      gs = state.value?.gameState;
    }
    await _startNextTurn();
  }

  void dismissGameModal() {
    state = state.whenData((s) => s?.copyWith(pendingGameWinnerId: null));
  }

  /// Abandons the active X01 game from the End Game dialog.
  ///
  /// Emits `GameCompleted(winner=null)` and atomically marks the game complete
  /// via `appendEventsAndCompleteGame` — mirrors the cricket equivalent added
  /// for #252 / PR #262. Without this, abandoned X01 games persisted their
  /// per-leg events with no terminating LegCompleted/GameCompleted, so the
  /// stats projection runner never fired a leg or match reset at the game
  /// boundary and the next won game's bestLegPpr accumulated darts from the
  /// abandoned game (#280).
  Future<void> endGame() => _serializer.run(_endGameImpl);

  Future<void> _endGameImpl() async {
    final current = state.value;
    if (current == null) return;
    final gs = current.gameState;
    if (gs.isComplete) return;
    try {
      final nextSeq = await ref
              .read(gameEventRepositoryProvider)
              .getLatestSequence(gs.gameId) +
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
}
