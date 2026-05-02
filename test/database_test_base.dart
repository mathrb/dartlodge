// Database Test Base Infrastructure
// Abstract base class for testing both SQLite and Drift implementations

import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import 'package:dart_lodge/features/statistics/domain/repositories/statistics_repository.dart';

abstract class DatabaseTestBase {
  /// Set up the test environment
  Future<void> setUp();

  /// Clean up after tests
  Future<void> tearDown();

  /// Repository factories
  Future<PlayerRepository> createPlayerRepository();
  Future<GameRepository> createGameRepository();
  Future<DartThrowRepository> createDartThrowRepository();
  Future<GameEventRepository> createGameEventRepository();
  Future<StatisticsRepository> createStatisticsRepository();
}