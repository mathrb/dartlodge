// Player Repository Implementation Tests
// Runs the contract tests against the PlayerRepositoryImpl

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/players/data/repositories/player_repository_impl.dart';
import 'package:my_darts/features/players/domain/repositories/player_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../contracts/player_repository_contract.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late PlayerRepository repo;

  Future<PlayerRepository> factory() async {
    return repo;
  }

  setUp(() async {
    // Open an in-memory database for each test
    db = await openDatabase(inMemoryDatabasePath);

    await db.execute('''
      CREATE TABLE players (
        player_id   TEXT    NOT NULL PRIMARY KEY,
        name        TEXT    NOT NULL,
        created_at  TEXT    NOT NULL,
        last_active TEXT    NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE competitors (
        competitor_id TEXT NOT NULL PRIMARY KEY,
        game_id       TEXT NOT NULL,
        type          TEXT NOT NULL,
        name          TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE competitor_players (
        competitor_id     TEXT    NOT NULL,
        player_id         TEXT    NOT NULL,
        rotation_position INTEGER NOT NULL,
        PRIMARY KEY (competitor_id, player_id)
      );
    ''');

    repo = PlayerRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  runPlayerRepositoryContractTests(
    factory,
    insertHistory: (playerId) async {
      await db.insert('competitors', {
        'competitor_id': 'c1',
        'game_id': 'g1',
        'type': 'human',
        'name': 'Alice',
      });
      await db.insert('competitor_players', {
        'competitor_id': 'c1',
        'player_id': playerId,
        'rotation_position': 0,
      });
    },
  );
}
