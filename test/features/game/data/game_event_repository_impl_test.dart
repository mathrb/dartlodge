// Game Event Repository Implementation Tests
// Runs the contract tests against the GameEventRepositoryImpl, using the
// canonical migrations script with PRAGMA foreign_keys = ON so tests match
// production.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/persistence/database_migrations.dart';
import 'package:dart_lodge/features/game/data/repositories/game_event_repository_impl.dart';
import 'package:dart_lodge/features/game/data/repositories/game_repository_impl.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
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
    await db.execute('PRAGMA foreign_keys = ON;');
    await DatabaseMigrations.createSchema(db);
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
