// Process Dart Use Case
// Business logic for handling a dart throw event

import '../entities/game_event.dart';
import '../entities/dart_throw.dart';
import '../repositories/game_event_repository.dart';
import '../repositories/dart_throw_repository.dart';
import '../engines/game_engine_factory.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../engines/base_game_engine.dart';
import 'package:uuid/uuid.dart';

class ProcessDartUseCase {
  final GameEventRepository _eventRepository;
  final DartThrowRepository _dartThrowRepository;

  ProcessDartUseCase(
    this._eventRepository,
    this._dartThrowRepository,
  );

  Future<GameState> execute(GameState currentState, DartThrow dartThrow) async {
    // 1. Get engine and validate
    final engine = GameEngineFactory.createEngine(currentState.gameType);
    
    // 2. Parse segment to extract base number and multiplier
    final parsedSegment = Segment.parse(dartThrow.segment);
    final segmentValue = parsedSegment.baseNumber;
    final multiplier = parsedSegment.multiplier;

    // 3. Fetch sequence counter ONCE
    int nextSeq = await _eventRepository.getLatestSequence(currentState.gameId) + 1;

    // 4. Create DartThrown event
    final dartEvent = GameEvent(
      eventId: dartThrow.dartId,
      gameId: currentState.gameId,
      eventType: 'DartThrown',
      localSequence: nextSeq++, // Use counter
      occurredAt: DateTime.now(),
      payload: {
        'competitor_id': dartThrow.competitorId,
        'segment': segmentValue,
        'multiplier': multiplier,
        'input_method': 'manual',
      },
      synced: false,
    );

    if (!engine.isValid(currentState, dartEvent)) {
      throw Exception('Invalid dart throw for current game state');
    }

    // 5. Apply and orchestrate
    var result = engine.apply(currentState, dartEvent);
    final eventsToStore = [dartEvent];

    // Handle leg completion
    if (result.outcome == LegOutcome.legCompleted) {
      final legEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: currentState.gameId,
        eventType: 'LegCompleted',
        localSequence: nextSeq++, // Use counter
        occurredAt: DateTime.now(),
        payload: {
          'winner_competitor_id': result.winnerCompetitorId,
        },
        synced: false,
      );

      result = engine.apply(result.state, legEvent);
      eventsToStore.add(legEvent);
    }

    // Handle game completion
    if (result.outcome == LegOutcome.gameCompleted) {
      final gameEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: currentState.gameId,
        eventType: 'GameCompleted',
        localSequence: nextSeq++, // Use counter
        occurredAt: DateTime.now(),
        payload: {
          'winner_id': result.winnerCompetitorId,
        },
        synced: false,
      );

      result = engine.apply(result.state, gameEvent);
      eventsToStore.add(gameEvent);
    }

    // 6. Persist and return
    await _dartThrowRepository.insertDart(dartThrow);
    await _eventRepository.appendEvents(eventsToStore);
    return result.state;
  }
}
