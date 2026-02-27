# TICKET-002: SQLite Schema & Database Helper

**Status:** Done
**Epic:** EPIC-001 — Core Infrastructure

---

## Description

Bootstrap the SQLite database for mobile targets using `sqflite` and `path_provider`. Includes complete schema creation in version 1 (all tables including backend sync capabilities) and the mandatory `PRAGMA foreign_keys = ON` configuration.

---

## Acceptance Criteria

- [x] `DatabaseHelper` is a singleton that opens the database exactly once per app lifetime
- [x] `PRAGMA foreign_keys = ON` is executed in `onOpen`
- [x] Schema v1 creates all tables from `docs/DATABASE_DDL.md`: `players`, `games`, `competitors`, `competitor_players`, `dart_throws`, `game_events`, `accounts`, `sync_queue`, `game_sessions`
- [x] All UUID columns are `TEXT`, all timestamps are `TEXT` (ISO 8601), all booleans are `INTEGER`
- [x] `ON DELETE CASCADE` is set on `competitors`, `competitor_players`, `dart_throws`, `game_events`
- [x] `ON DELETE RESTRICT` on `competitor_players.player_id` and `dart_throws.player_id` protects historical data
- [x] `ON DELETE SET NULL` on `players.account_id` allows account unlinking without losing the player record
- [x] `accounts` is created before `players` in `onCreate` (players FK depends on it)
- [x] `players` includes `account_id` and `avatar_url` columns from the initial schema — no `ALTER TABLE` needed
- [x] `DatabaseMigrations` class isolates all schema SQL from the helper
- [x] No `onUpgrade` handler — single version schema requires no incremental migrations

---

## Files

- `lib/core/persistence/database_helper.dart` — created
- `lib/core/persistence/database_migrations.dart` — created

---

## Implementation Notes

- `DatabaseHelper.instance` is a static singleton using a `_database` null-check (`if (_database != null) return _database!`), not a `Completer`. Subsequent calls return the cached `Database` immediately.
- `PRAGMA foreign_keys = ON` is in `onOpen`, not `onCreate`, because `onOpen` runs on every connection open (including future upgrades).
- `DatabaseMigrations.createSchema()` creates all 9 tables and their indexes in a single `onCreate` call. `accounts` is created first because `players.account_id` references it.
- `json` columns (`config_json`, `game_state_json`, `payload_json`) have no `DEFAULT` — they are `TEXT` with nullable semantics where appropriate (`game_state_json` is `TEXT` nullable; others are `TEXT NOT NULL`). The app owns parsing.
- Index strategy: composite `(game_id, local_sequence)` on `game_events` for ordered replay; `(game_id, turn_number, dart_number)` on `dart_throws` for turn reconstruction.
