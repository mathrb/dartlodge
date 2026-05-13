// Regression test: PRAGMA foreign_keys = ON in MigrationStrategy.beforeOpen.
//
// SQLite ships with FK enforcement disabled by default. The migration strategy
// re-enables it on every connection open. If that ever regresses, inserts with
// dangling references would silently succeed, corrupting downstream projections
// that assume referential integrity (e.g. `dart_throws.competitor_id` must
// resolve to a real row in `competitors`).
//
// This test inserts a `competitors` row referencing a non-existent game_id and
// asserts that SQLite raises `SQLITE_CONSTRAINT_FOREIGNKEY` (extended code
// 787). Running this against a database without the PRAGMA would silently
// succeed.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart' show SqliteException;

import 'package:dart_lodge/core/persistence/drift/database.dart';
import 'package:dart_lodge/core/persistence/drift/sqlite_error_codes.dart';

void main() {
  group('FK enforcement', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('inserting a competitor with a bogus game_id raises FK violation',
        () async {
      // Sanity check: confirm the PRAGMA is actually on. If this returns 0 the
      // FK assertion below would silently pass on bad data — guard the guard.
      final pragma = await db
          .customSelect('PRAGMA foreign_keys;')
          .getSingle();
      expect(pragma.data['foreign_keys'], 1,
          reason: 'PRAGMA foreign_keys must be ON for the rest of the test '
              'to be meaningful');

      Object? caught;
      try {
        await db.customStatement(
          "INSERT INTO competitors (competitor_id, game_id, type, name) "
          "VALUES ('c-bogus', 'g-does-not-exist', 'solo', 'Bogus');",
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isNotNull,
          reason: 'Expected an FK violation; got a successful insert');

      final sql = extractSqliteException(caught!);
      expect(sql, isA<SqliteException>(),
          reason: 'Expected a SqliteException, got: $caught');
      expect(sql!.extendedResultCode, sqliteConstraintForeignKey,
          reason:
              'Expected SQLITE_CONSTRAINT_FOREIGNKEY (787); got ${sql.extendedResultCode}');
    });
  });
}
