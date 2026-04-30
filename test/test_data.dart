// Test Data Utilities
// Provides test data generators and cleanup methods

import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';

class TestData {
  /// Player Test Data
  static Player createTestPlayer({String id = 'test-player-1'}) {
    return Player(
      playerId: id,
      name: 'Test Player',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
  }

  static List<Player> createMultiplePlayers(int count) {
    return List.generate(count, (index) => createTestPlayer(id: 'test-player-$index'));
  }

  /// Game Test Data
  static Game createTestGame({
    String id = 'test-game-1',
    GameType type = GameType.x01,
    bool completed = false
  }) {
    return Game(
      gameId: id,
      gameType: type,
      config: GameConfig.x01(
        startingScore: 501,
        inStrategy: 'double',
        outStrategy: 'double',
      ),
      startTime: DateTime.now(),
      endTime: completed ? DateTime.now() : null,
      winnerCompetitorId: completed ? 'competitor-1' : null,
      isComplete: completed,
    );
  }

  /// Dart Throw Test Data
  static DartThrow createTestDartThrow({
    String id = 'test-dart-1',
    String gameId = 'test-game-1',
    String playerId = 'test-player-1'
  }) {
    return DartThrow(
      dartId: id,
      gameId: gameId,
      competitorId: 'competitor-1',
      playerId: playerId,
      turnNumber: 1,
      dartNumber: 1,
      segment: 'T20',
      score: 60,
      x: 0.5,
      y: 0.5,
    );
  }

  static List<DartThrow> createMultipleDarts({
    String gameId = 'test-game-1',
    String playerId = 'test-player-1',
    int count = 3
  }) {
    return List.generate(count, (index) => createTestDartThrow(
      id: 'test-dart-$index',
      gameId: gameId,
      playerId: playerId
    ));
  }

  /// Game Event Test Data
  static GameEvent createTestGameEvent({
    String id = 'test-event-1',
    String gameId = 'test-game-1',
    int sequence = 1
  }) {
    return GameEvent(
      eventId: id,
      gameId: gameId,
      eventType: 'game_started',
      localSequence: sequence,
      occurredAt: DateTime.now(),
      payload: {'playerId': 'test-player-1'},
      synced: false,
      actorId: 'test-player-1',
      globalSequence: null,
      source: EventSource.client,
    );
  }

  /// Cleanup Methods
  static Future<void> cleanupPlayers(PlayerRepository repo) async {
    // Implementation would depend on engine capabilities
    // For testing, we can clear the in-memory database between tests
  }

  static Future<void> cleanupGames(GameRepository repo) async {
    // Implementation would depend on engine capabilities
  }

  /// Game Types for Testing
  static List<String> get testGameTypes => [
    'x01', 'cricket', 'aroundTheClock', 'killer'
  ];

  /// Common Test Constants
  static const String testPlayerId = 'test-player-1';
  static const String testGameId = 'test-game-1';
  static const String testDartId = 'test-dart-1';
  static const String testEventId = 'test-event-1';
}