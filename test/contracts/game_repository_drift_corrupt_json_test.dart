// Drift-specific regression tests for #194: a corrupted `config_json`
// column must surface as `DatabaseException` rather than raw
// `FormatException` / `TypeError`. Bypasses the public `createGame` API
// (which would validate) by inserting directly via drift's
// `customStatement` to force the row-to-entity mapping to encounter
// malformed input.

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/error/repository_exception.dart';

import '../drift_test_base.dart';

void main() {
  group('game_repository_drift — corrupt JSON column handling (#194)', () {
    final base = DriftTestBase();

    setUp(() async {
      await base.setUp();
    });

    tearDown(() async {
      await base.tearDown();
    });

    Future<void> insertMalformedGame({
      required String gameId,
      required String configJson,
    }) async {
      await base.db.rawInsert('games', {
        'game_id': gameId,
        'game_type': 'x01',
        'config_json': configJson,
        'start_time': '2026-05-15T00:00:00.000',
        'is_complete': 0,
      });
    }

    test('getGame throws DatabaseException on malformed config_json', () async {
      await insertMalformedGame(
        gameId: 'bad-1',
        configJson: '{not valid json',
      );

      final repo = await base.createGameRepository();
      await expectLater(
        () => repo.getGame('bad-1'),
        throwsA(isA<DatabaseException>().having(
          (e) => e.message,
          'message',
          contains('bad-1'),
        )),
      );
    });

    test('getGame throws DatabaseException on schema-drifted config_json',
        () async {
      // Valid JSON but doesn't match GameConfig's freezed shape: missing
      // `runtimeType` discriminator and required fields.
      await insertMalformedGame(
        gameId: 'bad-2',
        configJson: '{"unknown_field": 42}',
      );

      final repo = await base.createGameRepository();
      await expectLater(
        () => repo.getGame('bad-2'),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('getActiveGame throws DatabaseException on malformed config_json',
        () async {
      await insertMalformedGame(
        gameId: 'bad-active',
        configJson: '{still bad',
      );

      final repo = await base.createGameRepository();
      await expectLater(
        () => repo.getActiveGame(),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('getCompletedGames throws DatabaseException on malformed config_json',
        () async {
      await insertMalformedGame(
        gameId: 'bad-completed',
        configJson: 'not json at all',
      );
      // Mark complete so the row is included in getCompletedGames.
      await base.db.customStatement(
        "UPDATE games SET is_complete = 1, end_time = ? WHERE game_id = ?",
        ['2026-05-15T01:00:00.000', 'bad-completed'],
      );

      final repo = await base.createGameRepository();
      await expectLater(
        () => repo.getCompletedGames(),
        throwsA(isA<DatabaseException>()),
      );
    });

  });
}
