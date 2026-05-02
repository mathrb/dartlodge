// End Checkout Practice Use Case
// Allows explicit early exit from a checkout practice session before the
// engine auto-completes. Marks the game complete with no winner.

import '../entities/game_event.dart';
import '../repositories/game_repository.dart';
import '../repositories/game_event_repository.dart';
import '../models/game_state.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_lodge/core/utils/constants.dart';

class EndCheckoutPracticeUseCase {
  final GameRepository _gameRepository;
  final GameEventRepository _eventRepository;

  EndCheckoutPracticeUseCase(
    this._gameRepository,
    this._eventRepository,
  );

  Future<GameState> execute(GameState currentState) async {
    // No-op if already complete
    if (currentState.isComplete) {
      return currentState;
    }

    final nextSeq =
        await _eventRepository.getLatestSequence(currentState.gameId) + 1;

    final gameCompletedEvent = GameEvent(
      eventId: const Uuid().v4(),
      gameId: currentState.gameId,
      eventType: 'GameCompleted',
      localSequence: nextSeq,
      occurredAt: DateTime.now(),
      payload: {'winner_id': null},
      synced: false,
      actorId: 'system',
      source: EventSource.client,
    );

    await _eventRepository.appendEvent(gameCompletedEvent);

    await _gameRepository.completeGame(
      gameId: currentState.gameId,
      winnerCompetitorId: null,
      endTime: DateTime.now(),
    );

    return currentState.copyWith(isComplete: true);
  }
}
