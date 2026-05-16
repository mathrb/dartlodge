// End Practice Use Case
// Allows explicit early exit ("End Drill") from any practice session before
// the engine auto-completes. Marks the game complete with no winner. The
// logic is game-type agnostic: every practice engine's GameCompleted handler
// accepts a null winner.

import '../engines/base_game_engine.dart';
import '../entities/game_event.dart';
import '../repositories/game_repository.dart';
import '../repositories/game_event_repository.dart';
import '../models/game_state.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_lodge/core/utils/constants.dart';

class EndPracticeUseCase {
  final GameRepository _gameRepository;
  final GameEventRepository _eventRepository;

  EndPracticeUseCase(
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
      // Aligned with `buildGameCompletedEvent`'s payload key. Reader
      // fallback handles the legacy `winner_id` form for older events.
      payload: {'winner_competitor_id': null},
      synced: false,
      actorId: 'system',
      source: EventSource.client,
    );

    // Atomic: append GameCompleted AND mark the game complete in one
    // transaction so a crash between them can't leave the event log and
    // games.is_complete in disagreement (#188).
    await _gameRepository.appendEventsAndCompleteGame(
      events: [gameCompletedEvent],
      gameId: currentState.gameId,
      winnerCompetitorId: null,
      endTime: DateTime.now(),
    );

    return currentState.copyWith(
      isComplete: true,
      // Match what the engines do on game completion — keeps the status
      // field's invariant aligned with isComplete so anything keyed on
      // `state.status == GameEngineStatus.completed` (e.g. future UI
      // gates) doesn't diverge from `state.isComplete == true`.
      status: GameEngineStatus.completed,
    );
  }
}
