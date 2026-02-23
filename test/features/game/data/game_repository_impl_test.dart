// Game Repository Implementation Tests
// Runs the contract tests against the GameRepositoryImpl

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/game/data/repositories/game_repository_impl.dart';
import 'package:my_darts/features/game/domain/repositories/game_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../contracts/game_repository_contract.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late GameRepository repo;

  Future<GameRepository> factory() async {
    return repo;
  }

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath);
    
    // Create schema v1
    await db.execute('''
      CREATE TABLE players (
        player_id   TEXT    NOT NULL PRIMARY KEY,
        name        TEXT    NOT NULL,
        created_at  TEXT    NOT NULL,
        last_active TEXT    NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE games (
        game_id               TEXT     NOT NULL PRIMARY KEY,
        game_type             TEXT     NOT NULL,
        config_json           TEXT     NOT NULL,
        start_time            TEXT     NOT NULL,
        end_time              TEXT,
        winner_competitor_id  TEXT,
        is_complete           INTEGER  NOT NULL DEFAULT 0,
        game_state_json       TEXT
      );
    ''');

    // Add unique partial index to ensure only one active game
    await db.execute('''
      CREATE UNIQUE INDEX idx_games_single_active
      ON games(is_complete)
      WHERE is_complete = 0;
    ''');

    await db.execute('''
      CREATE TABLE competitors (
        competitor_id  TEXT  NOT NULL PRIMARY KEY,
        game_id        TEXT  NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
        type           TEXT  NOT NULL,
        name           TEXT  NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE competitor_players (
        competitor_id     TEXT     NOT NULL REFERENCES competitors(competitor_id) ON DELETE CASCADE,
        player_id         TEXT     NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
        rotation_position INTEGER  NOT NULL,
        PRIMARY KEY (competitor_id, player_id)
      );
    ''');

    repo = GameRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  runGameRepositoryContractTests(factory);
}
