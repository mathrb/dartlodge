import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/engines/base_game_engine.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/usecases/game_use_case_helpers.dart';
import '../state/active_practice_state.dart';
import '../../../../core/persistence/database_provider.dart';
import '../../../../core/utils/constants.dart';
import 'action_serializer.dart';
import 'game_replay_provider.dart';

part 'active_practice_provider.g.dart';

@riverpod
class ActivePracticeNotifier extends _$ActivePracticeNotifier {
  final ActionSerializer _serializer = ActionSerializer();

  @override
  Future<ActivePracticeState?> build(String gameId) async {
    final gs = await ref.read(loadedGameStateProvider(gameId).future);
    if (gs == null) return null;
    return ActivePracticeState(gameState: gs);
  }

  Future<void> processDart(String segment, {String inputMethod = 'manual'}) =>
      _serializer.run(() => _processDartImpl(segment, inputMethod: inputMethod));

  Future<void> _processDartImpl(String segment,
      {String inputMethod = 'manual'}) async {
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

    final isShanghai = gs.gameType == GameType.shanghai;
    final isCatch40 = gs.gameType == GameType.catch40;
    final isCheckout = gs.gameType == GameType.checkoutPractice;
    final prevCompetitor = gs.competitors[gs.currentTurnIndex];
    final prevSuccesses = prevCompetitor.practiceSuccesses;
    final prevCatch40Remaining = gs.catch40TargetRemaining;
    final prevCatch40DartsOnTarget = gs.catch40DartsOnTarget;
    final prevCheckoutScore = prevCompetitor.score;
    final dartValue = Segment.parse(segment).scoreValue;

    state = await AsyncValue.guard(() async {
      var newGs = await switch (gs.gameType) {
        GameType.aroundTheClock => ref
            .read(processAroundTheClockDartUseCaseProvider)
            .execute(gs, dart, inputMethod: inputMethod),
        GameType.bobs27 => ref
            .read(processBobs27DartUseCaseProvider)
            .execute(gs, dart, inputMethod: inputMethod),
        GameType.shanghai => ref
            .read(processShanghaiDartUseCaseProvider)
            .execute(gs, dart, inputMethod: inputMethod),
        GameType.catch40 => ref
            .read(processCatch40DartUseCaseProvider)
            .execute(gs, dart, inputMethod: inputMethod),
        GameType.checkoutPractice => ref
            .read(processCheckoutPracticeDartUseCaseProvider)
            .execute(gs, dart, inputMethod: inputMethod),
        _ => throw UnsupportedError(
            'Unsupported practice game type: ${gs.gameType}'),
      };

      // Catch-40: auto-advance to next turn on same target after 3 darts
      // (no checkout yet, < 6 darts on target). This keeps the button hidden.
      if (gs.gameType == GameType.catch40 &&
          !newGs.turnActive &&
          !newGs.isComplete &&
          newGs.catch40TargetRemaining != 0 &&
          newGs.catch40DartsOnTarget < 6) {
        newGs = await _advanceTurn(newGs);
      }

      // Checkout Practice: the engine no longer ends the drill on the first
      // checkout — it leaves `score = 0` and bumps `practiceSuccesses`, then
      // decides completion at TurnEnded time against `checkoutTargetSuccesses`
      // (#254). When the user JUST hit the quota-completing checkout, the
      // post-game screen should still land immediately — auto-advance so the
      // closing TurnEnded fires the gameCompleted outcome inside
      // `_advanceTurn` (which then emits GameCompleted atomically). For a
      // mid-drill checkout in finite mode or any checkout in ∞ mode, the
      // user taps NEXT ROUND like usual.
      final newComp = newGs.competitors[newGs.currentTurnIndex];
      final target = newGs.checkoutTargetSuccesses;
      if (gs.gameType == GameType.checkoutPractice &&
          !newGs.isComplete &&
          newComp.score == 0 &&
          target != null &&
          newComp.practiceSuccesses >= target) {
        newGs = await _advanceTurn(newGs);
      }

      final pendingGameWinnerId =
          newGs.isComplete ? newGs.winnerCompetitorId : null;

      final shanghaiBonus = isShanghai &&
          newGs.competitors[gs.currentTurnIndex].practiceSuccesses >
              prevSuccesses;

      // Catch 40 bust signature: a non-zero dart was applied
      // (catch40DartsOnTarget incremented) but remaining did NOT decrease.
      // The engine resets remaining to currentTarget on bust, so the
      // post-throw value is >= prevRemaining (equal for first-dart-of-round
      // busts where remaining was already at currentTarget, greater
      // otherwise). MISS darts (dartValue == 0) never bust — checked
      // explicitly so a 0-progress miss on a fresh round doesn't flash BUST.
      //
      // Checkout Practice bust signature: a non-zero dart was applied
      // (dartValue > 0) and the post-throw score is strictly greater than
      // the pre-throw score — only possible on bust, because the engine
      // reverts to turnStartScore. A successful checkout brings the score
      // to 0 (decrease), and a normal hit also decreases the score, so the
      // ">" inequality cleanly isolates the bust case (#340).
      final newCompetitor = newGs.competitors[gs.currentTurnIndex];
      final showBust = (isCatch40 &&
              dartValue > 0 &&
              newGs.catch40DartsOnTarget > prevCatch40DartsOnTarget &&
              newGs.catch40TargetRemaining >= prevCatch40Remaining) ||
          (isCheckout &&
              dartValue > 0 &&
              newCompetitor.score > prevCheckoutScore);

      return ActivePracticeState(
        gameState: newGs,
        pendingGameWinnerId: pendingGameWinnerId,
        showShanghaiBonus: shanghaiBonus,
        showBust: showBust,
      );
    });
  }

  /// Clear the transient `showBust` flag. Called by the board page after
  /// the BUST snackbar fades.
  void dismissBust() {
    final current = state.value;
    if (current == null || !current.showBust) return;
    state = AsyncValue.data(current.copyWith(showBust: false));
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

    final gs = current.gameState;

    state = await AsyncValue.guard(() async {
      final newGs = await switch (gs.gameType) {
        GameType.aroundTheClock =>
          ref.read(undoPracticeAroundTheClockLastDartUseCaseProvider).execute(gs),
        GameType.bobs27 =>
          ref.read(undoPracticeBobs27LastDartUseCaseProvider).execute(gs),
        GameType.shanghai =>
          ref.read(undoPracticeShanghaiLastDartUseCaseProvider).execute(gs),
        GameType.catch40 =>
          ref.read(undoPracticeCatch40LastDartUseCaseProvider).execute(gs),
        GameType.checkoutPractice =>
          ref.read(undoPracticeCheckoutPracticeLastDartUseCaseProvider).execute(gs),
        _ => throw UnsupportedError(
            'Unsupported practice game type: ${gs.gameType}'),
      };
      return ActivePracticeState(gameState: newGs);
    });
  }

  /// Per-dart correction (#427 — practice parity with X01/Cricket): replace dart
  /// [turnDartIndex] of the current turn via the engine-specific
  /// [CorrectDartUseCase] (rewind + re-throw). No-op on a completed game or an
  /// out-of-range index. Note: unlike [_processDartImpl] this does not re-run the
  /// notifier's convenience auto-advance (Catch 40 same-target / Checkout quota)
  /// — the recomputed engine state is authoritative and the user taps NEXT.
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

    state = await AsyncValue.guard(() async {
      final corrector = switch (gs.gameType) {
        GameType.aroundTheClock =>
          ref.read(correctAroundTheClockDartUseCaseProvider),
        GameType.bobs27 => ref.read(correctBobs27DartUseCaseProvider),
        GameType.shanghai => ref.read(correctShanghaiDartUseCaseProvider),
        GameType.catch40 => ref.read(correctCatch40DartUseCaseProvider),
        GameType.checkoutPractice =>
          ref.read(correctCheckoutPracticeDartUseCaseProvider),
        _ => throw UnsupportedError(
            'Unsupported practice game type: ${gs.gameType}'),
      };
      final newGs = await corrector.execute(
        gs,
        originalEventId: eventId,
        segment: parsed.baseNumber,
        multiplier: parsed.multiplier,
      );
      return ActivePracticeState(
        gameState: newGs,
        pendingGameWinnerId:
            newGs.isComplete ? newGs.winnerCompetitorId : null,
      );
    });

    // Best-effort: propagate the correction into the auto-scorer capture for
    // this (current-turn) dart, only if the correction itself succeeded (#456).
    // No-op when no auto-scoring session is bound.
    if (!state.hasError) {
      ref.read(activeCaptureCorrectionSinkProvider)?.correctDart(
            dartInTurnOrdinal: turnDartIndex + 1,
            segment: newSegment,
          );
    }
  }

  /// Resolves the `DartThrown` event id for dart [turnDartIndex] (0-based,
  /// throw order) of the active competitor's current turn — the last
  /// `dartsThrownInTurn` live (non-corrected, non-superseded) darts. Returns
  /// null if out of range. Mirrors the X01/Cricket resolver.
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

  /// Apply TurnEnded + TurnStarted events and persist them. Used for
  /// same-target auto-advance in Catch-40 and for the NEXT ROUND/TARGET button.
  ///
  /// TurnEnded carries `player_id` and a `reason` field (and, for Catch 40,
  /// `darts_on_target`) so the stats projection can attribute the turn to
  /// the right player and classify checkouts vs failed targets (#253). If
  /// applying TurnEnded triggers natural game completion (the Catch 40
  /// engine marks `isComplete` only on TurnEnded after target 40), this also
  /// emits GameCompleted and calls `appendEventsAndCompleteGame` atomically
  /// — otherwise the game record would stay `is_complete = 0` and History
  /// would never show the drill.
  Future<GameState> _advanceTurn(GameState gs) async {
    final engine = _engineFor(gs.gameType);
    int nextSeq =
        await ref.read(gameEventRepositoryProvider).getLatestSequence(gs.gameId) + 1;

    final currentCompetitor = gs.competitors[gs.currentTurnIndex];
    final actorId = currentCompetitor.playerIds.isNotEmpty
        ? currentCompetitor.playerIds.first
        : 'system';
    final currentPlayerId = currentCompetitor.playerIds.isNotEmpty
        ? currentCompetitor.playerIds.first
        : 'system';

    final reason = _turnEndedReason(gs);
    final turnEndedPayload = <String, dynamic>{
      'competitor_id': currentCompetitor.competitorId,
      'player_id': currentPlayerId,
      'reason': reason,
    };
    if (gs.gameType == GameType.catch40) {
      // Total darts spent on the just-finished target — projection uses this
      // to bucket checkouts (2-dart / 3-dart / 4-6 dart) when a checkout
      // straddles two turns and `turnDarts` alone would under-count.
      turnEndedPayload['darts_on_target'] = gs.catch40DartsOnTarget;
    }

    final turnEndedEvent = buildGameEvent(
      gameId: gs.gameId,
      eventType: 'TurnEnded',
      localSequence: nextSeq++,
      actorId: actorId,
      payload: turnEndedPayload,
    );

    final turnEndedResult = engine.apply(gs, turnEndedEvent);
    var newGs = turnEndedResult.state;
    final eventsToStore = <GameEvent>[turnEndedEvent];

    // Catch 40 (and any other practice engine that signals completion via
    // TurnEnded) drives game-over from this code path — the DartThrown
    // handler in ProcessPracticeDartUseCase only catches engines that
    // complete on a dart. Without this branch, completing all 40 targets
    // would leave the game stuck `is_complete = 0` in storage (#253).
    if (turnEndedResult.outcome == LegOutcome.gameCompleted) {
      final winnerCompetitorId = turnEndedResult.winnerCompetitorId;
      final gameCompletedEvent = buildGameCompletedEvent(
        gameId: gs.gameId,
        winnerCompetitorId: winnerCompetitorId,
        localSequence: nextSeq++,
        winnerPlayerId:
            getPlayerIdForCompetitor(newGs, winnerCompetitorId),
      );
      eventsToStore.add(gameCompletedEvent);
      newGs = engine.apply(newGs, gameCompletedEvent).state;

      await ref.read(gameRepositoryProvider).appendEventsAndCompleteGame(
            events: eventsToStore,
            gameId: gs.gameId,
            winnerCompetitorId: winnerCompetitorId,
            endTime: DateTime.now(),
          );

      return newGs;
    }

    final nextCompetitor = newGs.competitors[newGs.currentTurnIndex];
    final nextActorId = nextCompetitor.playerIds.isNotEmpty
        ? nextCompetitor.playerIds.first
        : 'system';
    final nextPlayerId = nextCompetitor.playerIds.isNotEmpty
        ? nextCompetitor.playerIds.first
        : 'system';

    final turnStartedEvent = buildGameEvent(
      gameId: gs.gameId,
      eventType: 'TurnStarted',
      localSequence: nextSeq++,
      actorId: nextActorId,
      payload: {
        'competitor_id': nextCompetitor.competitorId,
        'player_id': nextPlayerId,
      },
    );

    newGs = engine.apply(newGs, turnStartedEvent).state;
    eventsToStore.add(turnStartedEvent);

    await ref.read(gameEventRepositoryProvider).appendEvents(eventsToStore);

    return newGs;
  }

  /// Reason tag used by stats projections.
  ///
  /// - Catch 40: distinguishes target-completion turns ('checkout' / 'failed')
  ///   from intra-target auto-advance ('normal').
  /// - Checkout Practice: 'checkout' iff the player's score is 0 — the
  ///   engine resets to `startingScore` only on the *next* TurnStarted, so
  ///   `score == 0` at TurnEnded time is the canonical post-checkout
  ///   signature. Busts revert score to `turnStartScore` (≠ 0) and partial
  ///   attempts leave score somewhere between 0 and startingScore; both fall
  ///   through to 'normal'. This drives `_computeCheckoutStats` (#254).
  /// - Other practice modes: always 'normal'.
  String _turnEndedReason(GameState gs) {
    if (gs.gameType == GameType.catch40) {
      if (gs.catch40TargetRemaining == 0) return 'checkout';
      if (gs.catch40DartsOnTarget >= 6) return 'failed';
      return 'normal';
    }
    if (gs.gameType == GameType.checkoutPractice) {
      final comp = gs.competitors[gs.currentTurnIndex];
      if (comp.score == 0) return 'checkout';
      return 'normal';
    }
    return 'normal';
  }

  GameEngine _engineFor(GameType type) => switch (type) {
    GameType.aroundTheClock => ref.read(aroundTheClockEngineProvider),
    GameType.bobs27 => ref.read(bobs27EngineProvider),
    GameType.shanghai => ref.read(shanghaiEngineProvider),
    GameType.catch40 => ref.read(catch40EngineProvider),
    GameType.checkoutPractice => ref.read(checkoutPracticeEngineProvider),
    _ => throw UnsupportedError('Unsupported practice game type: $type'),
  };

  /// Fills any unfilled dart slots in the current turn with MISS darts,
  /// persisting them as events. Stops early if the game completes.
  ///
  /// Skipped for Catch 40: feeding MISS through `ProcessPracticeDartUseCase`
  /// would route through `_applyDartThrownWithOutcome`, which treats
  /// `newRemaining == 0 && !isDouble` as a bust and silently resets the
  /// target. After a sub-3-dart checkout that flips `catch40TargetRemaining`
  /// to non-zero, so `_applyTurnEnded` sees `checkedOut = false` and awards
  /// 0 points — exactly the symptom in #253. The engine advances the target
  /// purely from `catch40DartsOnTarget >= 6 || catch40TargetRemaining == 0`
  /// at TurnEnded time, so the fill is unnecessary anyway.
  Future<GameState> _fillTurnWithMisses(GameState gs) async {
    if (gs.gameType == GameType.catch40) return gs;
    var current = gs;
    while (current.dartsThrownInTurn < 3 && !current.isComplete) {
      final competitor = current.competitors[current.currentTurnIndex];
      final dart = DartThrow(
        dartId: const Uuid().v4(),
        gameId: current.gameId,
        competitorId: competitor.competitorId,
        playerId: competitor.playerIds.isNotEmpty
            ? competitor.playerIds.first
            : 'sentinel',
        turnNumber: current.currentLegIndex,
        dartNumber: current.dartsThrownInTurn + 1,
        segment: 'MISS',
        score: 0,
      );
      current = await switch (current.gameType) {
        GameType.aroundTheClock =>
          ref.read(processAroundTheClockDartUseCaseProvider).execute(current, dart),
        GameType.bobs27 =>
          ref.read(processBobs27DartUseCaseProvider).execute(current, dart),
        GameType.shanghai =>
          ref.read(processShanghaiDartUseCaseProvider).execute(current, dart),
        GameType.catch40 =>
          ref.read(processCatch40DartUseCaseProvider).execute(current, dart),
        GameType.checkoutPractice =>
          ref.read(processCheckoutPracticeDartUseCaseProvider).execute(current, dart),
        _ => throw UnsupportedError(
            'Unsupported practice game type: ${current.gameType}'),
      };
    }
    return current;
  }

  Future<void> startNextTurn() => _serializer.run(_startNextTurnImpl);

  Future<void> _startNextTurnImpl() async {
    final current = state.value;
    if (current == null) return;
    final gs = current.gameState;
    if (gs.isComplete) return;

    state = await AsyncValue.guard(() async {
      final filled = await _fillTurnWithMisses(gs);
      final newGs = filled.isComplete ? filled : await _advanceTurn(filled);
      return ActivePracticeState(
        gameState: newGs,
        pendingGameWinnerId:
            newGs.isComplete ? newGs.winnerCompetitorId : null,
        showShanghaiBonus: false,
      );
    });
  }

  void dismissGameModal() {
    state = state.whenData((s) => s?.copyWith(pendingGameWinnerId: null));
  }

  Future<void> endDrill() => _serializer.run(_endDrillImpl);

  Future<void> _endDrillImpl() async {
    final current = state.value;
    if (current == null) return;

    final gs = current.gameState;

    state = await AsyncValue.guard(() async {
      final newGs =
          await ref.read(endPracticeUseCaseProvider).execute(gs);
      return ActivePracticeState(
        gameState: newGs,
        pendingGameWinnerId: newGs.winnerCompetitorId,
        wasEndedManually: true,
      );
    });
  }
}
