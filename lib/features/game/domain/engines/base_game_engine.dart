import '../models/game_state.dart';
import '../entities/game_event.dart';

/// Leg outcome enum for engine result signaling
enum LegOutcome { none, legCompleted, gameCompleted }

/// Engine result type that carries both state and outcome signals
class EngineResult {
  final GameState state;
  final LegOutcome outcome;
  final String? winnerCompetitorId;
  
  const EngineResult({
    required this.state,
    this.outcome = LegOutcome.none,
    this.winnerCompetitorId,
  });
}

/// Pure functional interface for all game engines as specified in AGENTS.md
abstract class GameEngine {
  /// Pure function that takes the current state and an event, 
  /// and returns the new state and any outcome signals.
  EngineResult apply(GameState state, GameEvent event);
  
  /// Pure function that checks if an event is valid for the given state.
  bool isValid(GameState state, GameEvent event);
}

/// Game engine status enum
enum GameEngineStatus {
  initialized,
  inProgress,
  completed,
  cancelled
}

class GameEngineException implements Exception {
  final String message;
  const GameEngineException(this.message);
  
  @override
  String toString() => 'GameEngineException: $message';
}