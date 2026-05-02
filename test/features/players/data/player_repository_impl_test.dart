// Player Repository Implementation Tests
// Runs the contract tests against the PlayerRepositoryImpl, using the canonical
// migrations script with PRAGMA foreign_keys = ON so tests match production.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/persistence/database_migrations.dart';
import 'package:dart_lodge/features/players/data/repositories/player_repository_impl.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
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
    db = await openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON;');
    await DatabaseMigrations.createSchema(db);
    repo = PlayerRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  runPlayerRepositoryContractTests(
    factory,
    insertHistory: (playerId) async {
      // Insert in FK order: games → competitors → competitor_players.
      await db.insert('games', {
        'game_id': 'g1',
        'game_type': 'x01',
        'config_json': '{}',
        'start_time': DateTime.now().toIso8601String(),
        'is_complete': 1,
      });
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
