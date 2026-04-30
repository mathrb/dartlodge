// Dart Throw Repository Implementation Tests
// Runs the contract tests against the DartThrowRepositoryImpl, using the
// canonical migrations script with PRAGMA foreign_keys = ON so tests match
// production.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/persistence/database_migrations.dart';
import 'package:dart_lodge/features/game/data/repositories/dart_throw_repository_impl.dart';
import 'package:dart_lodge/features/game/data/repositories/game_repository_impl.dart';
import 'package:dart_lodge/features/players/data/repositories/player_repository_impl.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
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
    await db.execute('PRAGMA foreign_keys = ON;');
    await DatabaseMigrations.createSchema(db);
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
