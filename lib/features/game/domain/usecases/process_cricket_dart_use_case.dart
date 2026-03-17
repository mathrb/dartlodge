// Process Cricket Dart Use Case
// Business logic for handling a dart throw event in Cricket game types.
// Mirrors ProcessDartUseCase but omits the bust path — cricket has no bust.

import '../entities/game_event.dart';
import '../entities/dart_throw.dart';
import '../repositories/game_repository.dart';
import '../repositories/game_event_repository.dart';
import '../repositories/dart_throw_repository.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../engines/base_game_engine.dart';
import '../engines/stateless_cricket_engine.dart';
import '../../../../core/error/repository_exception.dart';
import 'package:uuid/uuid.dart';
import 'package:my_darts/core/utils/constants.dart';

class ProcessCricketDartUseCase {
  final GameRepository _gameRepository;
  final GameEventRepository _eventRepository;
  final DartThrowRepository _dartThrowRepository;
  final StatelessCricketEngine _engine;

  ProcessCricketDartUseCase(
    this._gameRepository,
    this._eventRepository,
    this._dartThrowRepository,
    this._engine,
  );

  Future<GameState> execute(GameState currentState, DartThrow dartThrow) async {
    // 1. Guard: game already complete
    if (currentState.isComplete) {
      throw GameAlreadyCompleteException(currentState.gameId);
    }

    // 2. Parse segment to extract base number and multiplier
    final parsedSegment = Segment.parse(dartThrow.segment);
    final segmentValue = parsedSegment.baseNumber;
    final multiplier = parsedSegment.multiplier;

    // 3. Fetch sequence counter once
    int nextSeq = await _eventRepository.getLatestSequence(currentState.gameId) + 1;

    // 4. Create DartThrown event (eventId == dartId per spec)
    final currentPlayerId = _getCurrentPlayerId(currentState, dartThrow.competitorId);

    final dartEvent = GameEvent(
      eventId: dartThrow.dartId,
      gameId: currentState.gameId,
      eventType: 'DartThrown',
      localSequence: nextSeq++,
      occurredAt: DateTime.now(),
      payload: {
        'competitor_id': dartThrow.competitorId,
        'player_id': currentPlayerId,
        'segment': segmentValue,
        'multiplier': multiplier,
        'score': parsedSegment.scoreValue,
        'input_method': 'manual',
      },
      synced: false,
      actorId: currentPlayerId,
      source: EventSource.client,
    );

    // 5. Validate
    if (!_engine.isValid(currentState, dartEvent)) {
      throw const InvalidGameStateException('Invalid dart throw for current game state');
    }

    // 6. Apply DartThrown through engine
    final result = _engine.apply(currentState, dartEvent);

    // 7. Build event list and final state
    final eventsToStore = <GameEvent>[dartEvent];
    var finalState = result.state;
    bool needsCompleteGame = false;

    if (!finalState.turnActive) {
      // Turn ended — append TurnEnded (reason always 'normal'; cricket has no bust)
      final turnEndedEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: currentState.gameId,
        eventType: 'TurnEnded',
        localSequence: nextSeq++,
        occurredAt: DateTime.now(),
        payload: {
          'competitor_id': dartThrow.competitorId,
          'player_id': currentPlayerId,
          'reason': 'normal',
        },
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );
      eventsToStore.add(turnEndedEvent);

      if (result.outcome == LegOutcome.gameCompleted) {
        // Append LegCompleted + GameCompleted; call completeGame()
        final winnerPlayerId = _getPlayerIdForCompetitor(currentState, result.winnerCompetitorId);
        final legCompletedEvent = GameEvent(
          eventId: const Uuid().v4(),
          gameId: currentState.gameId,
          eventType: 'LegCompleted',
          localSequence: nextSeq++,
          occurredAt: DateTime.now(),
          payload: {
            'winner_competitor_id': result.winnerCompetitorId,
            'winner_player_id': winnerPlayerId,
          },
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        );
        eventsToStore.add(legCompletedEvent);

        final gameCompletedEvent = GameEvent(
          eventId: const Uuid().v4(),
          gameId: currentState.gameId,
          eventType: 'GameCompleted',
          localSequence: nextSeq++,
          occurredAt: DateTime.now(),
          payload: {
            'winner_id': result.winnerCompetitorId,
            'winner_player_id': winnerPlayerId,
          },
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        );
        eventsToStore.add(gameCompletedEvent);
        needsCompleteGame = true;
        // finalState stays as result.state (game is over, no TurnStarted)

      } else if (result.outcome == LegOutcome.legCompleted) {
        // Append LegCompleted + TurnStarted for first player of new leg
        final winnerPlayerId = _getPlayerIdForCompetitor(currentState, result.winnerCompetitorId);
        final legCompletedEvent = GameEvent(
          eventId: const Uuid().v4(),
          gameId: currentState.gameId,
          eventType: 'LegCompleted',
          localSequence: nextSeq++,
          occurredAt: DateTime.now(),
          payload: {
            'winner_competitor_id': result.winnerCompetitorId,
            'winner_player_id': winnerPlayerId,
          },
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        );
        eventsToStore.add(legCompletedEvent);

        // After _resetLeg, currentTurnIndex == 0 (first player of next leg)
        final nextCompetitor = finalState.competitors[finalState.currentTurnIndex];
        final nextPlayerId = nextCompetitor.playerIds.isNotEmpty
            ? nextCompetitor.playerIds.first
            : 'system';
        final turnStartedEvent = GameEvent(
          eventId: const Uuid().v4(),
          gameId: currentState.gameId,
          eventType: 'TurnStarted',
          localSequence: nextSeq++,
          occurredAt: DateTime.now(),
          payload: {
            'competitor_id': nextCompetitor.competitorId,
            'player_id': nextPlayerId,
            'turn_index': finalState.currentTurnIndex,
            'leg_index': finalState.currentLegIndex,
          },
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        );
        eventsToStore.add(turnStartedEvent);
        finalState = _engine.apply(finalState, turnStartedEvent).state;

      } else {
        // Normal 3-dart turn end — TurnStarted for next player
        final nextIndex = (finalState.currentTurnIndex + 1) % finalState.competitors.length;
        final nextCompetitor = finalState.competitors[nextIndex];
        final nextPlayerId = nextCompetitor.playerIds.isNotEmpty
            ? nextCompetitor.playerIds.first
            : 'system';
        final turnStartedEvent = GameEvent(
          eventId: const Uuid().v4(),
          gameId: currentState.gameId,
          eventType: 'TurnStarted',
          localSequence: nextSeq++,
          occurredAt: DateTime.now(),
          payload: {
            'competitor_id': nextCompetitor.competitorId,
            'player_id': nextPlayerId,
            'turn_index': nextIndex,
            'leg_index': finalState.currentLegIndex,
          },
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        );
        eventsToStore.add(turnStartedEvent);
        finalState = _engine.apply(finalState, turnStartedEvent).state;
      }
    }

    // 8. Persist: dart first, then events
    await _dartThrowRepository.insertDart(dartThrow);
    await _eventRepository.appendEvents(eventsToStore);

    if (needsCompleteGame) {
      await _gameRepository.completeGame(
        gameId: currentState.gameId,
        winnerCompetitorId: result.winnerCompetitorId,
        endTime: DateTime.now(),
      );
    }

    return finalState;
  }

  String _getCurrentPlayerId(GameState state, String competitorId) {
    final competitor = state.competitors.firstWhere(
      (c) => c.competitorId == competitorId,
      orElse: () => throw const InvalidGameStateException('Competitor not found'),
    );
    if (competitor.playerIds.isNotEmpty) {
      return competitor.playerIds.first;
    }
    return 'system';
  }

  String _getPlayerIdForCompetitor(GameState state, String? competitorId) {
    if (competitorId == null) return '';
    final competitor = state.competitors.firstWhere(
      (c) => c.competitorId == competitorId,
      orElse: () => state.competitors.first,
    );
    return competitor.playerIds.isNotEmpty ? competitor.playerIds.first : '';
  }
}
