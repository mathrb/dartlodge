# TICKET-001: Repository Exception Hierarchy

**Status:** Done
**Epic:** EPIC-001 — Core Infrastructure

---

## Description

Define the sealed exception class hierarchy that all repository implementations must use. Every error thrown from a repository is a subtype of `RepositoryException`, giving callers a single catch clause and exhaustive pattern matching.

---

## Acceptance Criteria

- [x] `RepositoryException` is a sealed class in `lib/core/error/`
- [x] All subtypes extend `RepositoryException`
- [x] `PlayerNotFoundException`, `GameNotFoundException`, `DartNotFoundException`, `EventNotFoundException` cover missing-record cases
- [x] `DuplicatePlayerException`, `DuplicateGameException`, `DuplicateDartException` cover uniqueness violations
- [x] `SequenceConflictException` covers sequence number collisions in the event log (distinct from event-ID deduplication, which is handled silently)
- [x] `GameAlreadyCompleteException` enforces the read-only invariant for finished games
- [x] `PlayerHasGameHistoryException` blocks hard-delete when a player has game history
- [x] `MultipleActiveGamesException`, `ActiveGameAlreadyExistsException` guard the single-active-game invariant
- [x] `InvalidCompetitorException` covers malformed competitor data on game creation
- [x] `StatisticsException` covers general statistics query errors
- [x] `StatisticsNotFoundException` distinguishes "entity not found" from other statistics errors; carries `entityId`
- [x] `DatabaseException` wraps unexpected low-level errors from sqflite/Drift; carries optional `cause` (`Object?`) for logging
- [x] `InvalidGameStateException` covers engine-level state violations; accepts a free-text `reason`
- [x] No repository implementation throws raw `Exception` or `Error`

---

## Files

- `lib/core/error/repository_exception.dart` — created

---

## Implementation Notes

- Sealed class enables exhaustive `switch` expressions in callers without a catch-all.
- `SequenceConflictException` is **not** a rename of `DuplicateGameEventException`. Because `appendEvent()` silently ignores duplicate `event_id` values (idempotent), a "duplicate event" exception would never be thrown. `SequenceConflictException` captures a distinct failure mode: two events claiming the same `local_sequence` number within a game, which is a logic error not covered by idempotent deduplication.
- `GameAlreadyCompleteException` (note: "Complete" not "Completed") is checked by the repository before any write; it is not a database-level constraint.
- `DuplicateDartException` is intentionally asymmetric with `GameEventRepository.appendEvent()`, which silently ignores duplicate `event_id` values (idempotent append). See `docs/REPOSITORY_INTERFACES.md` for the rationale.
- `DatabaseException` carries an optional `cause` field (`Object?`) for logging the original sqflite/Drift error without coupling callers to those packages.
- `InvalidGameStateException` takes a free-text `reason` — it is used by the game engine layer (EPIC-003) to signal precondition failures before persistence is attempted.
- `StatisticsNotFoundException` carries `entityId` (player UUID or game UUID) so callers can include it in user-facing messages without string parsing.
