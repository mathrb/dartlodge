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
    
    // Create tables manually or via migration helper
    // We'll use a simplified version of createVersion1 for speed
    await db.execute('''
      CREATE TABLE players (
        player_id   TEXT    NOT NULL PRIMARY KEY,
        name        TEXT    NOT NULL,
        created_at  TEXT    NOT NULL,
        last_active TEXT    NOT NULL
      );
    ''');

    repo = PlayerRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  runPlayerRepositoryContractTests(factory);
}
