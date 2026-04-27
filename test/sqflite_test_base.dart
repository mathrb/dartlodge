// SQLite Test Implementation
// Test base for mobile SQLite database. Uses the canonical migrations script
// from `lib/core/persistence/database_migrations.dart` and enables
// `PRAGMA foreign_keys = ON` so tests run against the same schema (and same
// FK enforcement) as production.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_darts/core/persistence/database_migrations.dart';
import 'package:my_darts/features/players/data/repositories/player_repository_impl.dart';
import 'package:my_darts/features/game/data/repositories/game_repository_impl.dart';
import 'package:my_darts/features/game/data/repositories/dart_throw_repository_impl.dart';
import 'package:my_darts/features/game/data/repositories/game_event_repository_impl.dart';
import 'package:my_darts/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'database_test_base.dart';

class SqfliteTestBase implements DatabaseTestBase {
  late Database db;

  @override
  Future<void> setUp() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON;');
    await DatabaseMigrations.createSchema(db);
  }

  @override
  Future<void> tearDown() async {
    await db.close();
  }

  @override
  Future<PlayerRepositoryImpl> createPlayerRepository() async {
    return PlayerRepositoryImpl(db);
  }

  @override
  Future<GameRepositoryImpl> createGameRepository() async {
    return GameRepositoryImpl(db);
  }

  @override
  Future<DartThrowRepositoryImpl> createDartThrowRepository() async {
    return DartThrowRepositoryImpl(db);
  }

  @override
  Future<GameEventRepositoryImpl> createGameEventRepository() async {
    return GameEventRepositoryImpl(db);
  }

  @override
  Future<StatisticsRepositoryImpl> createStatisticsRepository() async {
    return StatisticsRepositoryImpl(db);
  }
}
