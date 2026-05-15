// Process Dart Use Case
// Business logic for handling a dart throw event

import '../entities/game_event.dart';
import '../entities/dart_throw.dart';
import '../repositories/game_repository.dart';
import '../repositories/game_event_repository.dart';
import '../repositories/dart_throw_repository.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../engines/base_game_engine.dart';
import '../../../../core/error/repository_exception.dart';
import 'game_use_case_helpers.dart';

class ProcessDartUseCase {
  final GameRepository _gameRepository;
  final GameEventRepository _eventRepository;
  final DartThrowRepository _dartThrowRepository;
  final GameEngine _engine;

  ProcessDartUseCase(
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
    final currentPlayerId = getCurrentPlayerId(currentState, dartThrow.competitorId);

    var dartEvent = buildDartThrownEvent(
      gameId: currentState.gameId,
      dartId: dartThrow.dartId,
      competitorId: dartThrow.competitorId,
      actorId: currentPlayerId,
      localSequence: nextSeq++,
      segment: segmentValue,
      multiplier: multiplier,
      score: parsedSegment.scoreValue,
      playerId: currentPlayerId,
    );

    // 5. Validate
    if (!_engine.isValid(currentState, dartEvent)) {
      throw const InvalidGameStateException('Invalid dart throw for current game state');
    }

    // 6. Apply DartThrown through engine
    final result = _engine.apply(currentState, dartEvent);

    // 7. Annotate DartThrown payload with bust flag if applicable
    if (result.isBust) {
      dartEvent = dartEvent.copyWith(
        payload: {...dartEvent.payload, 'bust': true},
      );
    }

    // 8. Build event list and final state
    final eventsToStore = <GameEvent>[dartEvent];
    var finalState = result.state;
    bool needsCompleteGame = false;

    if (!finalState.turnActive) {
      // Turn ended (normal 3-dart end, bust, or leg/game-completing dart) —
      // always append TurnEnded eagerly so the event log is coherent without
      // waiting for the UI to tap NEXT ROUND. Mirrors cricket's structure.
      eventsToStore.add(buildTurnEndedEvent(
        gameId: currentState.gameId,
        competitorId: dartThrow.competitorId,
        playerId: currentPlayerId,
        localSequence: nextSeq++,
      ));

      if (result.outcome == LegOutcome.gameCompleted) {
        // Append LegCompleted + GameCompleted; call completeGame()
        final winnerPlayerId = getPlayerIdForCompetitor(currentState, result.winnerCompetitorId);
        eventsToStore.add(buildLegCompletedEvent(
          gameId: currentState.gameId,
          winnerCompetitorId: result.winnerCompetitorId,
          localSequence: nextSeq++,
          winnerPlayerId: winnerPlayerId,
        ));
        eventsToStore.add(buildGameCompletedEvent(
          gameId: currentState.gameId,
          winnerCompetitorId: result.winnerCompetitorId,
          localSequence: nextSeq++,
          winnerPlayerId: winnerPlayerId,
        ));
        needsCompleteGame = true;
        // finalState stays as result.state (game is over, no TurnStarted)

      } else if (result.outcome == LegOutcome.legCompleted) {
        // Append LegCompleted + TurnStarted for first player of new leg
        final winnerPlayerId = getPlayerIdForCompetitor(currentState, result.winnerCompetitorId);
        eventsToStore.add(buildLegCompletedEvent(
          gameId: currentState.gameId,
          winnerCompetitorId: result.winnerCompetitorId,
          localSequence: nextSeq++,
          winnerPlayerId: winnerPlayerId,
        ));

        // After _resetLeg, currentTurnIndex == 0 (first player of next leg)
        final nextCompetitor = finalState.competitors[finalState.currentTurnIndex];
        final nextPlayerId = nextCompetitor.playerIds.isNotEmpty
            ? nextCompetitor.playerIds.first
            : 'system';
        final turnStartedEvent = buildTurnStartedEvent(
          gameId: currentState.gameId,
          competitorId: nextCompetitor.competitorId,
          playerId: nextPlayerId,
          localSequence: nextSeq++,
          turnIndex: finalState.currentTurnIndex,
          legIndex: finalState.currentLegIndex,
          startingScore: nextCompetitor.score,
        );
        eventsToStore.add(turnStartedEvent);
        finalState = _engine.apply(finalState, turnStartedEvent).state;
      }
      // Normal 3-dart turn end or bust: only DartThrown + TurnEnded persisted
      // here. ActiveGameNotifier._startNextTurn appends the TurnStarted for
      // the next player on tap.
    }

    // 9. Persist: dart first, then events (+ completeGame atomically when
    //    the game ends, so the event log and games.is_complete can't diverge
    //    on a crash between the two writes — see #188).
    await _dartThrowRepository.insertDart(dartThrow);

    if (needsCompleteGame) {
      await _gameRepository.appendEventsAndCompleteGame(
        events: eventsToStore,
        gameId: currentState.gameId,
        winnerCompetitorId: result.winnerCompetitorId,
        endTime: DateTime.now(),
      );
    } else {
      await _eventRepository.appendEvents(eventsToStore);
    }

    return finalState;
  }

}
