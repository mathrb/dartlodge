// Undo Last Dart Use Case
// Corrects the most-recently thrown dart in the current turn by appending a
// DartCorrected event, deleting the dart throw record, and replaying all
// remaining events to rebuild the authoritative GameState.

import '../entities/game_event.dart';
import '../models/game_state.dart';
import '../repositories/game_event_repository.dart';
import '../repositories/dart_throw_repository.dart';
import '../engines/base_game_engine.dart';
import '../../../../core/error/repository_exception.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_lodge/core/utils/constants.dart';

class UndoLastDartUseCase {
  final GameEventRepository _eventRepository;
  final DartThrowRepository _dartThrowRepository;
  final GameEngine _engine;

  UndoLastDartUseCase(
    this._eventRepository,
    this._dartThrowRepository,
    this._engine,
  );

  Future<GameState> execute(GameState currentState) async {
    // 1. Guard: completed games are read-only
    if (currentState.isComplete) {
      throw GameAlreadyCompleteException(currentState.gameId);
    }

    // 2. Fetch the full event log
    final events = await _eventRepository.getEventsForGame(currentState.gameId);

    // 3. Build skip sets from prior DartCorrected events:
    //    - alreadyCorrectedIds: DartThrown ids retired by past undos
    //    - alreadySupersededIds: TurnStarted/TurnEnded/LegCompleted ids that
    //      bracketed a previously-undone dart and were tombstoned with it.
    //    Persisting supersededIds is what fixes #108: without it, a stale
    //    TurnStarted from an earlier undo silently shifts currentTurnIndex
    //    in any later replay and re-attributes new darts to the wrong player.
    final alreadyCorrectedIds = <String>{};
    final alreadySupersededIds = <String>{};
    for (final e in events) {
      if (e.eventType != 'DartCorrected') continue;
      final origId = e.payload['original_event_id'];
      if (origId is String) alreadyCorrectedIds.add(origId);
      final superseded = e.payload['superseded_event_ids'];
      if (superseded is List) {
        for (final id in superseded) {
          if (id is String) alreadySupersededIds.add(id);
        }
      }
    }

    // 4. Find the most recent DartThrown that has not been corrected
    GameEvent? lastDartEvent;
    for (final event in events.reversed) {
      if (event.eventType == 'DartThrown' &&
          !alreadyCorrectedIds.contains(event.eventId)) {
        lastDartEvent = event;
        break;
      }
    }

    if (lastDartEvent == null) {
      // dartsThrownInTurn > 0 guarantees this can't normally happen,
      // but guard defensively.
      throw NoDartsToUndoException(currentState.gameId);
    }

    // 5. Collect turn-boundary events between the undone dart and the next
    //    non-corrected DartThrown. If the next dart is in a fresh turn, the
    //    TurnEnded + TurnStarted (and possibly LegCompleted) bracketing that
    //    fresh turn are now stale — undoing the prior dart returns play to
    //    the previous turn, so those boundary events must not be re-applied.
    final newSupersededIds = <String>{};
    bool pastLastDart = false;
    for (final event in events) {
      if (event.eventId == lastDartEvent.eventId) {
        pastLastDart = true;
        continue;
      }
      if (!pastLastDart) continue;
      if (event.eventType == 'DartThrown' &&
          !alreadyCorrectedIds.contains(event.eventId)) {
        // A non-corrected dart exists after the target — this is a mid-turn
        // undo; nothing to supersede.
        break;
      }
      if (event.eventType == 'TurnStarted' ||
          event.eventType == 'TurnEnded' ||
          event.eventType == 'LegCompleted' ||
          event.eventType == 'GameCompleted' ||
          // Crazy Cricket: every TurnStarted is followed by a
          // CrazyTargetsRolled carrying that turn's rolled set. If we
          // supersede the TurnStarted, we must also supersede the trailing
          // roll — otherwise replay applies the cancelled turn's targets
          // and leaves `cricketTargets` pointing at the wrong set
          // (discard-on-rotate would also wipe legitimate marks against
          // a fabricated rotation). See design §4.
          event.eventType == 'CrazyTargetsRolled') {
        newSupersededIds.add(event.eventId);
      }
    }

    // 6. Append DartCorrected event — event log is updated before deletion so
    //    the audit trail remains complete even if deletion subsequently fails.
    final nextSeq =
        await _eventRepository.getLatestSequence(currentState.gameId) + 1;

    final correctionEvent = GameEvent(
      eventId: const Uuid().v4(),
      gameId: currentState.gameId,
      eventType: 'DartCorrected',
      localSequence: nextSeq,
      occurredAt: DateTime.now(),
      payload: {
        'original_event_id': lastDartEvent.eventId,
        'corrected_dart_id': lastDartEvent.eventId, // dartId == eventId by spec
        'superseded_event_ids': newSupersededIds.toList(),
      },
      synced: false,
      actorId: 'system',
      source: EventSource.client,
    );

    await _eventRepository.appendEvent(correctionEvent);

    // 7. Delete the physical dart throw record
    await _dartThrowRepository.deleteDart(lastDartEvent.eventId);

    // 8. Full replay to rebuild authoritative state
    //    - Skip ALL corrected DartThrown events (prior corrections + this one)
    //    - Skip TurnEnded / LegCompleted / GameCompleted — the engine folds
    //      these transitions into _applyDartThrown; applying them again during
    //      replay would double-count legsWon / double-advance turn state.
    //    - Skip TurnStarted entries marked as superseded (current + prior).
    //    - Skip DartCorrected — they carry no engine state change.
    final allCorrectedIds = {...alreadyCorrectedIds, lastDartEvent.eventId};
    final allSupersededIds = {...alreadySupersededIds, ...newSupersededIds};
    var replayState = _buildInitialState(currentState);

    for (final event in events) {
      if (event.eventType == 'DartThrown' &&
          allCorrectedIds.contains(event.eventId)) {
        continue;
      }
      if (event.eventType == 'TurnEnded' ||
          event.eventType == 'LegCompleted' ||
          event.eventType == 'GameCompleted' ||
          event.eventType == 'DartCorrected') {
        continue;
      }
      if (event.eventType == 'TurnStarted' &&
          allSupersededIds.contains(event.eventId)) {
        continue;
      }
      // Crazy Cricket: a superseded CrazyTargetsRolled would otherwise
      // overwrite `cricketTargets` with the cancelled turn's rolls.
      if (event.eventType == 'CrazyTargetsRolled' &&
          allSupersededIds.contains(event.eventId)) {
        continue;
      }
      replayState = _engine.apply(replayState, event).state;
    }

    return replayState;
  }

  /// Builds a blank initial GameState for replay, seeded from the static
  /// configuration fields of [source] (strategies, legsToWin, startingScore,
  /// variants, and competitor identities). All dynamic fields are reset to
  /// zero. Game-type-specific seeds (e.g. `currentTarget` for Around the
  /// Clock) mirror [GameState.initial] so the engine sees the same starting
  /// conditions during replay as it did when the game was first created.
  GameState _buildInitialState(GameState source) {
    // Around the Clock: starting target depends on the variant. Without this
    // seed, the engine's hit validation rejects every dart during replay and
    // `currentTarget` stays null after undo (issue #116).
    final int? initialTarget = source.gameType == GameType.aroundTheClock
        ? (source.aroundTheClockVariant == 'reverse' ? 20 : 1)
        : null;

    final initialCompetitors = source.competitors
        .map(
          (c) => CompetitorState(
            competitorId: c.competitorId,
            name: c.name,
            playerIds: c.playerIds,
            // Per-competitor starting score, set by GameState.initial to
            // include any X01 handicap. Reusing source.startingScore here
            // (the game-level field) drops the handicap and — worse — when
            // CompetitorState.startingScore is left to its 0 default,
            // engine._resetLeg restarts every subsequent leg at 0.
            score: c.startingScore,
            startingScore: c.startingScore,
            isIn: false,
            legsWon: 0,
            isComplete: false,
            dartThrows: const [],
            turnStartScore: null,
            currentTarget: initialTarget,
          ),
        )
        .toList();

    return GameState(
      gameId: source.gameId,
      gameType: source.gameType,
      competitors: initialCompetitors,
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      status: GameEngineStatus.initialized,
      turnActive: false,
      legsToWin: source.legsToWin,
      currentLegIndex: 0,
      inStrategy: source.inStrategy,
      outStrategy: source.outStrategy,
      startingScore: source.startingScore,
      cricketScoring: source.cricketScoring,
      cricketTargetMode: source.cricketTargetMode,
      cricketTargets: source.cricketTargets,
      cricketLockedTargets: source.cricketLockedTargets,
      aroundTheClockVariant: source.aroundTheClockVariant,
      shanghaiTotalRounds: source.shanghaiTotalRounds,
      catch40TargetRemaining:
          source.gameType == GameType.catch40 ? 61 : 0,
      x01TotalRounds: source.x01TotalRounds,
      cricketTotalRounds: source.cricketTotalRounds,
      countUpTotalRounds: source.countUpTotalRounds,
    );
  }
}
