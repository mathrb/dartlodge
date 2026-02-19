// Process Dart Use Case
// Business logic for handling a dart throw event

import '../entities/game_event.dart';
import '../entities/dart_throw.dart';
import '../repositories/game_event_repository.dart';
import '../repositories/dart_throw_repository.dart';
import '../engines/game_engine_factory.dart';
import '../models/game_state.dart';

class ProcessDartUseCase {
  final GameEventRepository _eventRepository;
  final DartThrowRepository _dartThrowRepository;

  ProcessDartUseCase(
    this._eventRepository,
    this._dartThrowRepository,
  );

  Future<GameState> execute(GameState currentState, DartThrow dartThrow) async {
    // 1. Validate the throw using the engine
    final engine = GameEngineFactory.createEngine(currentState.gameType);
    
    int multiplier = 1;
    if (dartThrow.segment.startsWith('D')) {
      multiplier = 2;
    } else if (dartThrow.segment.startsWith('T')) {
      multiplier = 3;
    } else if (dartThrow.segment == 'DB') {
      multiplier = 2;
    }

    final event = GameEvent(
      eventId: dartThrow.dartId,
      gameId: currentState.gameId,
      eventType: 'DartThrown',
      localSequence: await _eventRepository.getLatestSequence(currentState.gameId) + 1,
      occurredAt: DateTime.now(),
      payload: {
        'competitor_id': dartThrow.competitorId,
        'segment': dartThrow.segment,
        'multiplier': multiplier,
        'input_method': 'manual',
      },
      synced: false,
    );

    if (!engine.isValid(currentState, event)) {
      throw Exception('Invalid dart throw for current game state');
    }

    // 2. Persist the dart throw
    await _dartThrowRepository.insertDart(dartThrow);

    // 3. Append the event
    await _eventRepository.appendEvent(event);

    // 4. Apply the event to get the new state
    final newState = engine.apply(currentState, event);

    // 5. Update game state in database if needed (derived state)
    // In this architecture, game_state_json is just a snapshot for resumption
    // We can save it here or wait for a specific trigger
    
    return newState;
  }
}
