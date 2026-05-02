// Hybrid Test Runner
// Runs the same tests against both SQLite and Drift engines

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import 'package:dart_lodge/features/statistics/domain/repositories/statistics_repository.dart';
import 'database_test_base.dart';
import 'sqflite_test_base.dart';
import 'drift_test_base.dart';

export 'database_test_base.dart';
export 'sqflite_test_base.dart';
export 'drift_test_base.dart';

/// Run the same tests against both database engines
/// This function creates separate test suites for each engine
void runHybridTests(String testGroupName, Function(DatabaseTestBase) testFunction) {
  // Test with SQLite engine
  group('$testGroupName (SQLite)', () {
    final sqliteBase = SqfliteTestBase();
    
    setUp(() async {
      await sqliteBase.setUp();
    });
    
    tearDown(() async {
      await sqliteBase.tearDown();
    });
    
    testFunction(sqliteBase);
  });

  // Test with Drift engine
  group('$testGroupName (Drift)', () {
    final driftBase = DriftTestBase();
    
    setUp(() async {
      await driftBase.setUp();
    });
    
    tearDown(() async {
      await driftBase.tearDown();
    });
    
    testFunction(driftBase);
  });
}

/// Run tests for Drift engine separately
void runDriftTests(String testGroupName, Function(DatabaseTestBase) testFunction) {
  group('$testGroupName (Drift)', () {
    final driftBase = DriftTestBase();
    
    setUp(() async {
      await driftBase.setUp();
    });
    
    tearDown(() async {
      await driftBase.tearDown();
    });
    
    testFunction(driftBase);
  });
}

/// Helper to run contract tests against both engines
void runContractTests(
  String contractName, 
  Function({ 
    required Future<PlayerRepository> Function() playerRepoFactory,
    required Future<GameRepository> Function() gameRepoFactory,
    required Future<DartThrowRepository> Function() dartThrowRepoFactory,
    required Future<GameEventRepository> Function() gameEventRepoFactory,
    required Future<StatisticsRepository> Function() statisticsRepoFactory,
  }) contractTest 
) {
  runHybridTests(contractName, (base) {
    // The contract test function should create its own test cases
    // We just need to call it with the appropriate factories
    contractTest(
      playerRepoFactory: () => base.createPlayerRepository(),
      gameRepoFactory: () => base.createGameRepository(),
      dartThrowRepoFactory: () => base.createDartThrowRepository(),
      gameEventRepoFactory: () => base.createGameEventRepository(),
      statisticsRepoFactory: () => base.createStatisticsRepository(),
    );
  });
}