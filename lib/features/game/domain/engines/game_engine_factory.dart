import 'base_game_engine.dart';
import 'stateless_x01_engine.dart';
import 'stateless_cricket_engine.dart';
import 'stateless_around_the_clock_engine.dart';
import 'stateless_bobs_27_engine.dart';
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
        return StatelessCricketEngine();
      case GameType.aroundTheClock:
        return StatelessAroundTheClockEngine();
      case GameType.bobs27:
        return StatelessBobs27Engine();
      default:
        throw GameEngineException('Game type $gameType not supported');
    }
  }

  /// Get a list of all supported game types
  static List<GameType> getSupportedGameTypes() {
    return [
      GameType.x01,
      GameType.cricket,
      GameType.aroundTheClock,
      GameType.bobs27,
    ];
  }
  
  /// Check if a game type is supported
  static bool isGameTypeSupported(GameType gameType) {
    return getSupportedGameTypes().contains(gameType);
  }
}