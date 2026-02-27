// SQLite Test Implementation
// Test base for mobile SQLite database

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
    // Initialize FFI for testing environment
    sqfliteFfiInit();
    
    // Use in-memory database for tests
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    
    // Create tables (simplified for testing)
    await _createTestTables();
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

  Future<void> _createTestTables() async {
    // Create players table
    await db.execute('''
      CREATE TABLE players (
        player_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_active TEXT NOT NULL
      )
    ''');

    // Create games table
    await db.execute('''
      CREATE TABLE games (
        game_id TEXT PRIMARY KEY,
        game_type TEXT NOT NULL,
        config_json TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        winner_competitor_id TEXT,
        is_complete INTEGER NOT NULL DEFAULT 0,
        game_state_json TEXT
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_games_single_active
      ON games(is_complete)
      WHERE is_complete = 0
    ''');

    // Create competitors table
    await db.execute('''
      CREATE TABLE competitors (
        competitor_id TEXT NOT NULL PRIMARY KEY,
        game_id       TEXT NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
        type          TEXT NOT NULL,
        name          TEXT NOT NULL
      )
    ''');

    // Create competitor_players table
    await db.execute('''
      CREATE TABLE competitor_players (
        competitor_id     TEXT    NOT NULL REFERENCES competitors(competitor_id) ON DELETE CASCADE,
        player_id         TEXT    NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
        rotation_position INTEGER NOT NULL,
        PRIMARY KEY (competitor_id, player_id)
      )
    ''');

    // Create dart_throws table
    await db.execute('''
      CREATE TABLE dart_throws (
        dart_id TEXT PRIMARY KEY,
        game_id TEXT NOT NULL,
        competitor_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        turn_number INTEGER NOT NULL,
        dart_number INTEGER NOT NULL,
        segment TEXT NOT NULL,
        score INTEGER NOT NULL,
        x REAL,
        y REAL
      )
    ''');

    // Create game_events table
    await db.execute('''
      CREATE TABLE game_events (
        event_id TEXT PRIMARY KEY,
        game_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        local_sequence INTEGER NOT NULL,
        occurred_at TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        actor_id TEXT NOT NULL,
        global_sequence INTEGER,
        source INTEGER NOT NULL DEFAULT 0,
        UNIQUE (game_id, local_sequence)
      )
    ''');
  }
}
