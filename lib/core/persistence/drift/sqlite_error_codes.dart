// Cross-platform SQLite constraint detection helpers.
//
// Replaces fragile `e.toString().contains('UNIQUE constraint failed')` matches
// throughout the repository layer. Works the same way on:
//
//   * native (mobile/desktop) — drift over the `sqlite3` Dart package (v3
//     bundles its own native library via build hooks)
//   * web (Chrome/dev) — drift over the wasm build of the same `sqlite3` Dart
//     package
//
// Both backends raise a `SqliteException` from `package:sqlite3/common.dart`
// when SQLite reports a constraint violation. Drift may wrap that in
// `DriftWrappedException` depending on the call site; [extractSqliteException]
// unwraps a single level. If the cause shape ever changes, callers should
// fall through to the catch-all branch (which wraps in `DatabaseException`).
//
// See https://sqlite.org/rescode.html for the extended result code catalogue.

import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart' show SqliteException;

/// SQLite extended result codes used by the repository layer.
const int sqliteConstraintUnique = 2067; // SQLITE_CONSTRAINT_UNIQUE
const int sqliteConstraintPrimaryKey = 1555; // SQLITE_CONSTRAINT_PRIMARYKEY
const int sqliteConstraintForeignKey = 787; // SQLITE_CONSTRAINT_FOREIGNKEY

/// Returns the underlying [SqliteException] if [error] is one, or if it is a
/// [DriftWrappedException] whose `cause` is a [SqliteException]. Otherwise
/// returns `null`.
SqliteException? extractSqliteException(Object error) {
  if (error is SqliteException) return error;
  if (error is DriftWrappedException) {
    final cause = error.cause;
    if (cause is SqliteException) return cause;
  }
  return null;
}

/// True when [error] is a `UNIQUE` or `PRIMARY KEY` constraint violation.
bool isUniqueConstraintViolation(Object error) {
  final sql = extractSqliteException(error);
  if (sql == null) return false;
  return sql.extendedResultCode == sqliteConstraintUnique ||
      sql.extendedResultCode == sqliteConstraintPrimaryKey;
}

/// True when [error] is a `FOREIGN KEY` constraint violation.
bool isForeignKeyConstraintViolation(Object error) {
  final sql = extractSqliteException(error);
  if (sql == null) return false;
  return sql.extendedResultCode == sqliteConstraintForeignKey;
}
