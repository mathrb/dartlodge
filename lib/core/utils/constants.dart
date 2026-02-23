// App Constants and Enums
// Centralized constants and enumerations used throughout the application

// Game Types
enum GameType {
  x01,
  cricket,
  aroundTheClock,
  killer,
  baseball,
  golf,
  shanghai,
  scram,
  halveIt,
  highScore,
  blindCricket,
  blindGolf,
  blindKiller,
  blindShanghai,
  chaseTheDragon
}

// Competitor Types
enum CompetitorType {
  solo,
  team
}

// Dart Segments
class DartSegments {
  static const List<String> standardNumbers = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
    '11', '12', '13', '14', '15', '16', '17', '18', '19', '20'
  ];
  
  static const List<String> multipliers = ['', 'D', 'T'];
  
  static const String singleBull = 'SB';
  static const String doubleBull = 'DB';
  static const String miss = 'MISS';
  
  static final List<String> allSegments = [
    ...standardNumbers,
    ...standardNumbers.map((n) => 'D$n'),
    ...standardNumbers.map((n) => 'T$n'),
    singleBull,
    doubleBull,
    miss
  ];
}

// Event Source Enum
enum EventSource {
  client(0),
  server(1),
  vision(2);
  
  final int value;
  const EventSource(this.value);
  
  static EventSource fromValue(int value) {
    switch (value) {
      case 0: return EventSource.client;
      case 1: return EventSource.server;
      case 2: return EventSource.vision;
      default: throw ArgumentError('Invalid EventSource value: $value');
    }
  }
}

// Database Constants
class DatabaseConstants {
  static const String databaseName = 'darts_app.db';
  static const int databaseVersion = 3;
  
  // Table names
  static const String playersTable = 'players';
  static const String gamesTable = 'games';
  static const String competitorsTable = 'competitors';
  static const String competitorPlayersTable = 'competitor_players';
  static const String dartThrowsTable = 'dart_throws';
  static const String gameEventsTable = 'game_events';
}

// API Constants (for future backend integration)
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = 'v1';
  static const String authEndpoint = '/api/\$apiVersion/auth';
  static const String playersEndpoint = '/api/\$apiVersion/players';
  static const String gamesEndpoint = '/api/\$apiVersion/games';
  static const String statisticsEndpoint = '/api/\$apiVersion/statistics';
  static const String syncEndpoint = '/api/\$apiVersion/sync';
}

// Game Configuration Constants
class GameConfigurationConstants {
  static const List<int> x01StartingScores = [301, 501, 701, 901];
  static const List<String> x01InStrategies = ['straight', 'double', 'master'];
  static const List<String> x01OutStrategies = ['straight', 'double', 'master'];
  
  static const List<String> cricketVariants = ['standard', 'cut-throat', 'no-score'];
  static const List<String> cricketNumbers = ['15', '16', '17', '18', '19', '20', 'bull'];
  
  static const List<String> aroundTheClockDirections = ['ascending', 'descending', 'random'];
  static const List<int> aroundTheClockRequiredHits = [1, 2, 3];
}