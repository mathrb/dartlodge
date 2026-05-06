import 'base_game_engine.dart';
import 'stateless_x01_engine.dart';
import 'stateless_cricket_engine.dart';
import 'stateless_around_the_clock_engine.dart';
import 'stateless_bobs_27_engine.dart';
import 'stateless_shanghai_engine.dart';
import 'stateless_catch_40_engine.dart';
import 'stateless_checkout_practice_engine.dart';
import 'stateless_count_up_engine.dart';
import 'package:dart_lodge/core/utils/constants.dart';

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
      case GameType.shanghai:
        return StatelessShanghaiEngine();
      case GameType.catch40:
        return StatelessCatch40Engine();
      case GameType.checkoutPractice:
        return StatelessCheckoutPracticeEngine();
      case GameType.countUp:
        return StatelessCountUpEngine();
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
      GameType.shanghai,
      GameType.catch40,
      GameType.checkoutPractice,
      GameType.countUp,
    ];
  }
  
  /// Check if a game type is supported
  static bool isGameTypeSupported(GameType gameType) {
    return getSupportedGameTypes().contains(gameType);
  }
}