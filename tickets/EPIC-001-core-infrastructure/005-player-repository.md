# TICKET-005: Player Repository (SQLite + Drift)

**Status:** Done
**Epic:** EPIC-001 — Core Infrastructure

---

## Description

Implement the `PlayerRepository` interface for both database backends. Covers the full method set defined in the interface: list, lookup, create, name update, last-active touch, and reactive stream. Player deletion is not part of this interface; `ON DELETE RESTRICT` on `competitor_players` and `dart_throws` prevents hard-deletes at the database level anyway.

---

## Acceptance Criteria

- [x] `PlayerRepositoryImpl` (sqflite) implements all methods from the `PlayerRepository` interface
- [x] `PlayerRepositoryDrift` (Drift) implements the same interface with identical behaviour
- [x] `createPlayer(Player player)` inserts a fully-constructed `Player`; UUID and timestamps are provided by the caller (use case layer), not generated inside the repository
- [x] `getPlayer` returns `Player?` — null when the row does not exist (not an exception, per the interface contract)
- [x] `getAllPlayers` returns all players ordered by `last_active DESC`; no `is_active` filter (there is no `is_active` column in the schema)
- [x] `updatePlayerName` updates `name` and `last_active`; throws `PlayerNotFoundException` if zero rows affected
- [x] `touchPlayer` updates `last_active` to now; throws `PlayerNotFoundException` if zero rows affected
- [x] `watchAllPlayers` returns a `Stream<List<Player>>` (sqflite: `Stream.fromFuture`; Drift: native `watch()`)
- [x] Both implementations pass the shared contract suite in `test/contracts/player_repository_contract.dart`

---

## Files

- `lib/features/players/data/repositories/player_repository_impl.dart` — created
- `lib/core/persistence/drift/repositories/player_repository_drift.dart` — created

---

## Implementation Notes

- There is no `deletePlayer` method on the interface and no `is_active` column in the schema. Hard-deletes are blocked at the database level: `competitor_players.player_id` and `dart_throws.player_id` both use `ON DELETE RESTRICT` referencing `players`. If soft-delete is needed, it belongs in a future ticket that adds `deletePlayer` to the interface and an `is_active` column to the schema.
- UUID, `created_at`, and `last_active` are set by the caller before passing the `Player` entity to `createPlayer`. The repository persists exactly what it receives. UUID generation (`Uuid().v4()`) lives in the use case or notifier layer.
- `last_active` (not `updated_at` — there is no such column) is updated by `updatePlayerName` and `touchPlayer` via the Dart layer, consistent with the no-trigger rule.
- `import 'package:my_darts/core/error/repository_exception.dart' hide DatabaseException;` is required in the sqflite implementation to prevent ambiguity with sqflite's own `DatabaseException`, which is used in the `on DatabaseException catch` clause for unique-constraint detection.
