// Dart Throw Repository Implementation Tests
// Runs the contract tests against the DartThrowRepositoryImpl

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/game/data/repositories/dart_throw_repository_impl.dart';
import 'package:my_darts/features/game/data/repositories/game_repository_impl.dart';
import 'package:my_darts/features/players/data/repositories/player_repository_impl.dart';
import 'package:my_darts/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:my_darts/features/game/domain/repositories/game_repository.dart';
import 'package:my_darts/features/players/domain/repositories/player_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../contracts/dart_throw_repository_contract.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DartThrowRepository repo;
  late GameRepository gameRepo;
  late PlayerRepository playerRepo;

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

    await db.execute('''
      CREATE TABLE dart_throws (
        dart_id        TEXT     NOT NULL PRIMARY KEY,
        game_id        TEXT     NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
        competitor_id  TEXT     NOT NULL REFERENCES competitors(competitor_id) ON DELETE CASCADE,
        player_id      TEXT     NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
        turn_number    INTEGER  NOT NULL,
        dart_number    INTEGER  NOT NULL,
        segment        TEXT     NOT NULL,
        score          INTEGER  NOT NULL,
        x              REAL,
        y              REAL
      );
    ''');

    repo = DartThrowRepositoryImpl(db);
    gameRepo = GameRepositoryImpl(db);
    playerRepo = PlayerRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  runDartThrowRepositoryContractTests(
    factory: () async => repo,
    gameRepoFactory: () async => gameRepo,
    playerRepoFactory: () async => playerRepo,
  );
}
