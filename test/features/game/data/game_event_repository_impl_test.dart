// Game Event Repository Implementation Tests
// Runs the contract tests against the GameEventRepositoryImpl

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/game/data/repositories/game_event_repository_impl.dart';
import 'package:my_darts/features/game/data/repositories/game_repository_impl.dart';
import 'package:my_darts/features/game/domain/repositories/game_event_repository.dart';
import 'package:my_darts/features/game/domain/repositories/game_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../contracts/game_event_repository_contract.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late GameEventRepository repo;
  late GameRepository gameRepo;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath);
    
    // Create schema v1
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

    await db.execute('''
      CREATE TABLE game_events (
        event_id        TEXT     NOT NULL PRIMARY KEY,
        game_id         TEXT     NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
        event_type      TEXT     NOT NULL,
        local_sequence  INTEGER  NOT NULL,
        occurred_at     TEXT     NOT NULL,
        payload_json    TEXT     NOT NULL,
        synced          INTEGER  NOT NULL DEFAULT 0,
        UNIQUE (game_id, local_sequence)
      );
    ''');

    repo = GameEventRepositoryImpl(db);
    gameRepo = GameRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  runGameEventRepositoryContractTests(
    factory: () async => repo,
    gameRepoFactory: () async => gameRepo,
  );
}
