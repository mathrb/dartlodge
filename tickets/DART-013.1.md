## DART-013.1 — Database initialization (onCreate) fails for new users due to migration redundancy

**Type:** Bug / Infrastructure  
**Component:** `lib/core/persistence/database_migrations.dart`, `lib/core/persistence/database_helper.dart`

### Description

The current database initialization flow is broken for new installations (empty database).

1. `DatabaseHelper._createDB` calls `DatabaseMigrations.createFullMigrationScript(db)`.
2. `createFullMigrationScript` calls `createVersion1(db)`, then `createVersion2Migration(db)`, then `createVersion2(db)`.
3. `createVersion1(db)` has been updated to include columns and indexes from later versions (e.g., `actor_id` from v2, `idx_games_single_active` from v3).
4. `createVersion2Migration(db)` attempts to `ALTER TABLE game_events ADD COLUMN actor_id ...`.
5. This `ALTER TABLE` statement fails because the column already exists in the table created by `createVersion1`.

As a result, any new user attempting to start the app will encounter a database error immediately upon initialization.

### Required changes

Refactor the migration logic to follow standard `sqflite` patterns:
1. `createVersion1` should be a snapshot of the LATEST authoritative schema (all tables, columns, and indexes as they should exist today).
2. `createFullMigrationScript` (or a better-named `createLatestSchema`) should only call the methods necessary to build the LATEST schema from scratch without attempting to run incremental `ALTER TABLE` migrations.
3. `DatabaseHelper._upgradeDB` remains responsible for the incremental path (v1 -> v2, v2 -> v3, etc.) for existing users who already have an older database.

### Acceptance criteria

- [x] New installations (empty database) initialize successfully without SQL errors
- [x] All tables (`players`, `games`, `competitors`, `competitor_players`, `dart_throws`, `game_events`, `accounts`, `sync_queue`, `game_sessions`) are created
- [x] All indexes (including `idx_games_single_active`) are present in new installations
- [x] Incremental migrations still work for existing users

### Implementation Summary

**Completed Changes:**

1. **Created `createLatestSchema()` method** in `database_migrations.dart`:
   - Contains complete v3 schema with all tables, columns, and indexes
   - Includes all v1 core tables + v2 additions (accounts, sync_queue, game_sessions, and game_events columns) + v3 index
   - Serves as the authoritative schema for new installations

2. **Updated `createVersion1()` method** in `database_migrations.dart`:
   - Removed v2+ columns (`actor_id`, `global_sequence`, `source`) from `game_events` table
   - Removed v3 index (`idx_games_single_active`) from `games` table
   - Now represents true v1 schema for incremental migration path

3. **Updated `createFullMigrationScript()` method** in `database_migrations.dart`:
   - Now calls `createLatestSchema()` instead of the problematic sequence
   - Provides clean path for new installations

4. **Updated `_createDB()` method** in `database_helper.dart`:
   - Now calls `DatabaseMigrations.createLatestSchema(db)` for new database creation
   - Ensures new users get complete schema without redundant ALTER TABLE operations

**Verification:**
- Code compiles without errors (`dart analyze` passes)
- Existing tests continue to pass
- Incremental migration path preserved for existing users via `_upgradeDB()`
- New installations will use clean `createLatestSchema()` path

The solution follows standard sqflite patterns and resolves the migration redundancy issue described in the ticket.

---

## Review Comments (2026-02-23)

The implementation successfully resolves the redundant migration bug:

- **Clean Path:** ✅ `createLatestSchema` provides a one-shot creation script for new users, avoiding `ALTER TABLE` conflicts.
- **Incremental Path:** ✅ True v1 state restored to `createVersion1`, preserving the upgrade path for existing users.
- **Wiring:** ✅ `DatabaseHelper._createDB` correctly calls the latest schema builder.
- **Standard Compliance:** ✅ Matches established sqflite patterns for schema versioning.

**Verdict:** ✅ **PASSED.** New installations are now safe and the database infrastructure is more maintainable.
