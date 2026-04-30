// Drift Test Implementation
// Test base for web Drift database

import 'package:drift/native.dart';
import 'package:dart_lodge/core/persistence/drift/database.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/player_repository_drift.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/game_repository_drift.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/dart_throw_repository_drift.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/game_event_repository_drift.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/statistics_repository_drift.dart';
import 'database_test_base.dart';

class DriftTestBase implements DatabaseTestBase {
  late AppDatabase db;

  @override
  Future<void> setUp() async {
    // Use in-memory database for tests
    db = AppDatabase(NativeDatabase.memory());
  }

  @override
  Future<void> tearDown() async {
    await db.close();
  }

  @override
  Future<PlayerRepositoryDrift> createPlayerRepository() async {
    return PlayerRepositoryDrift(db);
  }

  @override
  Future<GameRepositoryDrift> createGameRepository() async {
    return GameRepositoryDrift(db);
  }

  @override
  Future<DartThrowRepositoryDrift> createDartThrowRepository() async {
    return DartThrowRepositoryDrift(db);
  }

  @override
  Future<GameEventRepositoryDrift> createGameEventRepository() async {
    return GameEventRepositoryDrift(db);
  }

  @override
  Future<StatisticsRepositoryDrift> createStatisticsRepository() async {
    return StatisticsRepositoryDrift(db);
  }
}