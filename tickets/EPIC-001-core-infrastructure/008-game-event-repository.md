# TICKET-008: GameEvent Repository (SQLite + Drift)

**Status:** Done
**Epic:** EPIC-001 — Core Infrastructure

---

## Description

Implement the `GameEventRepository` interface for both backends. Manages the `game_events` table, which is the append-only event log. Provides idempotent append (silent dedup on `event_id`) and ordered replay queries.

---

## Acceptance Criteria

- [x] `GameEventRepositoryImpl` (sqflite) implements all methods from `docs/REPOSITORY_INTERFACES.md`
- [x] `GameEventRepositoryDrift` (Drift) implements the same interface with identical behaviour
- [x] `appendEvent` silently ignores duplicate `event_id` (idempotent) — no exception, no error state
- [x] `appendEvent` throws `GameAlreadyCompletedException` if the target game is completed
- [x] `getEventsForGame` returns all events ordered by `local_sequence ASC`
- [x] `getEventsAfterSequence` returns events with `local_sequence > afterSequence` for incremental replay
- [x] `getLatestSequence` returns the highest `local_sequence` for a game, or `0` if no events exist
- [x] Both implementations pass the shared contract suite in `test/contracts/game_event_repository_contract.dart`

---

## Files

- `lib/features/game/data/repositories/game_event_repository_impl.dart` — created
- `lib/core/persistence/drift/repositories/game_event_repository_drift.dart` — created

---

## Implementation Notes

- `appendEvent` idempotency is implemented via `INSERT OR IGNORE` (sqflite) and `insertOnConflictUpdate` with no actual update (Drift), keyed on `event_id`.
- `local_sequence` is assigned by the caller (the game engine / use case), not auto-incremented by SQLite, so that sequence values are stable across replay.
- `global_sequence` is nullable — it is assigned by the backend sync layer and is `NULL` for locally-created events that have not been synced.
- `payload_json` is stored as an opaque `TEXT` blob; the repository does not parse or validate the JSON.
- Ordering by `local_sequence` (not `created_at`) is the authoritative event ordering rule per `docs/AGENTS.md`.
- The `game_events` table uses `ON DELETE CASCADE` from `games`, so all events are removed when a game is deleted (reserved operation).
