import '../models/game_state.dart';
import '../entities/game_event.dart';

/// Pure functional interface for all game engines as specified in AGENTS.md
abstract class GameEngine {
  /// Pure function that takes the current state and an event, 
  /// and returns the new state.
  GameState apply(GameState state, GameEvent event);
  
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