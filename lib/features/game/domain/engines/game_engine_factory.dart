import 'base_game_engine.dart';
import 'stateless_x01_engine.dart';
import 'package:my_darts/core/utils/constants.dart';

/// Game Engine Factory
/// Responsible for creating the appropriate game engine based on game type
class GameEngineFactory {
  /// Create a game engine for the specified game type
  static GameEngine createEngine(GameType gameType) {
    switch (gameType) {
      case GameType.x01:
        return StatelessX01Engine();
      case GameType.cricket:
        // TODO: Implement StatelessCricketEngine
        throw UnimplementedError('Cricket not yet implemented');
      default:
        throw GameEngineException('Game type $gameType not supported');
    }
  }
  
  /// Get a list of all supported game types
  static List<GameType> getSupportedGameTypes() {
    return [
      GameType.x01,
    ];
  }
  
  /// Check if a game type is supported
  static bool isGameTypeSupported(GameType gameType) {
    return getSupportedGameTypes().contains(gameType);
  }
}