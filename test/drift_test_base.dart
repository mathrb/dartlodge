// Test scaffold for repository tests. Spins up an in-memory drift database
// and exposes the five repositories used across contract and integration tests.

import 'package:drift/native.dart';
import 'package:dart_lodge/core/persistence/drift/database.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/player_repository_drift.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/game_repository_drift.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/dart_throw_repository_drift.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/game_event_repository_drift.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/statistics_repository_drift.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/achievement_repository_drift.dart';

class DriftTestBase {
  late AppDatabase db;

  Future<void> setUp() async {
    db = AppDatabase(NativeDatabase.memory());
  }

  Future<void> tearDown() async {
    await db.close();
  }

  Future<PlayerRepositoryDrift> createPlayerRepository() async =>
      PlayerRepositoryDrift(db);

  Future<GameRepositoryDrift> createGameRepository() async =>
      GameRepositoryDrift(db);

  Future<DartThrowRepositoryDrift> createDartThrowRepository() async =>
      DartThrowRepositoryDrift(db);

  Future<GameEventRepositoryDrift> createGameEventRepository() async =>
      GameEventRepositoryDrift(db);

  Future<StatisticsRepositoryDrift> createStatisticsRepository() async =>
      StatisticsRepositoryDrift(db);

  Future<AchievementRepositoryDrift> createAchievementRepository() async =>
      AchievementRepositoryDrift(db);
}

/// Bridges legacy sqflite-style `db.insert(table, {col: value, ...})` calls
/// in tests onto drift's `customStatement`. Used by the practice-stats tests
/// that pre-date the sqflite removal — they seed events with custom payloads
/// where typed `Companion.insert(...)` would be unhelpful boilerplate.
extension TestRawInsert on AppDatabase {
  Future<void> rawInsert(String table, Map<String, dynamic> row) async {
    final cols = row.keys.toList();
    final placeholders = List.filled(cols.length, '?').join(', ');
    await customStatement(
      'INSERT INTO $table (${cols.join(', ')}) VALUES ($placeholders)',
      cols.map((c) => row[c]).toList(),
    );
  }
}

