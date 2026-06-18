// App Constants and Enums
// Centralized constants and enumerations used throughout the application

// Game Types
enum GameType {
  x01,
  cricket,
  aroundTheClock,
  shanghai,
  catch40,
  bobs27,
  checkoutPractice,
  countUp;

  /// Maximum number of players allowed for this game type, or null if unlimited.
  /// Exhaustive over every enum case so that adding a new GameType is a
  /// compile error here rather than a silent default to "unlimited" (#169).
  int? get maxPlayers => switch (this) {
        GameType.x01 => 6,
        GameType.cricket => 6,
        GameType.aroundTheClock => null,
        GameType.shanghai => null,
        GameType.catch40 => 1,
        GameType.bobs27 => 1,
        GameType.checkoutPractice => 1,
        GameType.countUp => 6,
      };
}

// Competitor Types
enum CompetitorType { solo, team }

// Event Source Enum
enum EventSource {
  client(0),
  server(1),
  vision(2);

  final int value;
  const EventSource(this.value);

  static EventSource fromValue(int value) {
    switch (value) {
      case 0:
        return EventSource.client;
      case 1:
        return EventSource.server;
      case 2:
        return EventSource.vision;
      default:
        throw ArgumentError('Invalid EventSource value: $value');
    }
  }
}

// Database Constants
class DatabaseConstants {
  static const String databaseName = 'darts_app.db';
  // v2 (#522): add unlocked_achievements (first schema migration).
  static const int databaseVersion = 2;
}

// Game Configuration Constants
class GameConfigurationConstants {
  static const List<int> x01StartingScores = [301, 501, 701, 901];
  static const List<String> x01InStrategies = ['straight', 'double', 'master'];
  static const List<String> x01OutStrategies = ['straight', 'double', 'master'];

  static const List<String> cricketNumbers = [
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    'bull',
  ];

  // Count-up game (rounds-based, additive scoring with optional handicap).
  static const List<int> countUpAllowedRounds = [8, 12, 16, 20];
  static const int countUpDefaultRounds = 8;
  static const List<int> countUpAllowedHandicaps = [0, 50, 100, 150, 200];
}
