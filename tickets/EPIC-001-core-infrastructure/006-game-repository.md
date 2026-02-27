# TICKET-006: Game Repository (SQLite + Drift)

**Status:** Done
**Epic:** EPIC-001 — Core Infrastructure

---

## Description

Implement the `GameRepository` interface for both backends. Manages the `games` and `competitors` tables, handles game lifecycle transitions (created → active → completed), and enforces the read-only invariant for completed games.

---

## Acceptance Criteria

- [x] `GameRepositoryImpl` (sqflite) implements all methods from `docs/REPOSITORY_INTERFACES.md`
- [x] `GameRepositoryDrift` (Drift) implements the same interface with identical behaviour
- [x] `createGame` inserts a game row and its competitor rows in a single transaction
- [x] `getGame` returns a fully hydrated `Game` entity including `competitors` list; throws `GameNotFoundException` if absent
- [x] `getActiveGames` and `getCompletedGames` filter by `status` column
- [x] `updateGameState` throws `GameAlreadyCompletedException` if the game is already completed before writing
- [x] `completeGame` sets `status = 'completed'` and `completed_at`; throws `GameAlreadyCompletedException` on re-completion
- [x] `getCompetitors` returns all competitors for a game ordered by `position`
- [x] Both implementations pass the shared contract suite via `test/contracts/game_repository_drift_contract_test.dart` (uses `runHybridTests` to run `runGameRepositoryContractTests` against both backends)

---

## Files

- `lib/features/game/data/repositories/game_repository_impl.dart` — created
- `lib/core/persistence/drift/repositories/game_repository_drift.dart` — created

---

## Implementation Notes

- Competitor rows are inserted in the same transaction as the game row to avoid orphaned competitors on partial failure.
- `completeGame` checks `status` before writing — the completed-game invariant is enforced at the application layer, not via a trigger or constraint.
- `getGame` performs two queries (game + competitors) and assembles the entity in Dart. A `JOIN` was avoided to keep mapping simple and consistent between sqflite and Drift.
- `game_state_json` is stored as an opaque string; the repository neither parses nor validates it.
- The `competitors` relationship uses `ON DELETE CASCADE`, so deleting a game (currently unsupported but reserved) would remove its competitors automatically.
- `import 'package:my_darts/core/error/repository_exception.dart' hide DatabaseException;` is required in the sqflite implementation to prevent ambiguity with sqflite's own `DatabaseException`, which is used in the `on DatabaseException catch` clause for unique-constraint and active-game-constraint detection.
