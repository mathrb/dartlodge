// Undo Last Dart Use Case
// Corrects the most-recently thrown dart in the current turn by appending a
// DartCorrected event, deleting the dart throw record, and replaying all
// remaining events to rebuild the authoritative GameState.

import '../entities/game_event.dart';
import '../models/game_state.dart';
import '../repositories/game_repository.dart';
import '../repositories/game_event_repository.dart';
import '../repositories/dart_throw_repository.dart';
import '../engines/base_game_engine.dart';
import '../../../../core/error/repository_exception.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_lodge/core/utils/constants.dart';

class UndoLastDartUseCase {
  final GameRepository _gameRepository;
  final GameEventRepository _eventRepository;
  final DartThrowRepository _dartThrowRepository;
  final GameEngine _engine;

  UndoLastDartUseCase(
    this._gameRepository,
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

    // 4. Build the set of already-corrected event IDs
    final alreadyCorrectedIds = events
        .where((e) => e.eventType == 'DartCorrected')
        .map((e) => e.payload['original_event_id'] as String)
        .toSet();

    // 5. Find the most recent DartThrown that has not been corrected
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

    // 6. Collect TurnStarted events that came after the undone dart and before
    //    any subsequent non-corrected DartThrown. These events started the
    //    current (empty) turn and must also be excluded from replay so the
    //    result correctly lands on the previous turn at the undone dart.
    final Set<String> turnStartedIdsToSkip = {};
    bool pastLastDart = false;
    for (final event in events) {
      if (event.eventId == lastDartEvent.eventId) {
        pastLastDart = true;
        continue;
      }
      if (pastLastDart) {
        if (event.eventType == 'DartThrown' &&
            !alreadyCorrectedIds.contains(event.eventId)) {
          // A non-corrected dart exists after the target — this is a mid-turn
          // undo; no TurnStarted exclusion needed.
          break;
        }
        if (event.eventType == 'TurnStarted') {
          turnStartedIdsToSkip.add(event.eventId);
        }
      }
    }

    // 7. Append DartCorrected event — event log is updated before deletion so
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
      },
      synced: false,
      actorId: 'system',
      source: EventSource.client,
    );

    await _eventRepository.appendEvent(correctionEvent);

    // 8. Delete the physical dart throw record
    await _dartThrowRepository.deleteDart(lastDartEvent.eventId);

    // 9. Full replay to rebuild authoritative state
    //    - Skip ALL corrected DartThrown events (prior corrections + this one)
    //    - Skip TurnEnded / LegCompleted / GameCompleted — the engine folds
    //      these transitions into _applyDartThrown; applying them again during
    //      replay would double-count legsWon / double-advance turn state.
    //    - Skip DartCorrected — they carry no engine state change.
    final allCorrectedIds = {...alreadyCorrectedIds, lastDartEvent.eventId};
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
          turnStartedIdsToSkip.contains(event.eventId)) {
        continue;
      }
      replayState = _engine.apply(replayState, event).state;
    }

    return replayState;
  }

  /// Builds a blank initial GameState for replay, seeded from the static
  /// configuration fields of [source] (strategies, legsToWin, startingScore,
  /// and competitor identities). All dynamic fields are reset to zero.
  GameState _buildInitialState(GameState source) {
    final initialCompetitors = source.competitors
        .map(
          (c) => CompetitorState(
            competitorId: c.competitorId,
            name: c.name,
            playerIds: c.playerIds,
            score: source.startingScore,
            isIn: false,
            legsWon: 0,
            isComplete: false,
            dartThrows: const [],
            turnStartScore: null,
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
    );
  }
}
