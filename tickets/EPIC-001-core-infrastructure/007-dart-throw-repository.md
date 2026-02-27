# TICKET-007: DartThrow Repository (SQLite + Drift)

**Status:** Done
**Epic:** EPIC-001 — Core Infrastructure

---

## Description

Implement the `DartThrowRepository` interface for both backends. Manages the `dart_throws` table with strict duplicate detection (`DuplicateDartException` on repeated `dart_id`) and throw-level correction support.

---

## Acceptance Criteria

- [x] `DartThrowRepositoryImpl` (sqflite) implements all methods from `docs/REPOSITORY_INTERFACES.md`
- [x] `DartThrowRepositoryDrift` (Drift) implements the same interface with identical behaviour
- [x] `insertDart` throws `DuplicateDartException` on a duplicate `dart_id` (non-idempotent, by design)
- [x] `insertDart` throws `GameAlreadyCompletedException` if the target game is completed
- [x] `getDartsForGame` returns all throws ordered by `(turn_number, dart_number)`
- [x] `getDartsForTurn` returns throws for a specific `(game_id, turn_number)`
- [x] `correctDart` updates `segment` and `score` for an existing throw; throws `DartThrowNotFoundException` if absent
- [x] `correctDart` throws `GameAlreadyCompletedException` if the game is completed
- [x] Both implementations pass the shared contract suite in `test/contracts/dart_throw_repository_contract.dart`

---

## Files

- `lib/features/game/data/repositories/dart_throw_repository_impl.dart` — created
- `lib/core/persistence/drift/repositories/dart_throw_repository_drift.dart` — created

---

## Implementation Notes

- `DuplicateDartException` is asymmetric with `GameEventRepository.appendEvent()` (which is idempotent). This asymmetry is intentional: dart corrections require explicit re-throws via `correctDart`, not silent deduplication.
- Segment format follows the canonical convention from `docs/AGENTS.md`: `'20'`, `'D20'`, `'T20'`, `'SB'`, `'DB'`, `'MISS'`. The repository stores and returns these strings without transformation.
- `correctDart` triggers a full projection replay in the statistics layer — the repository itself does not cascade any updates.
- The sqflite implementation uses `INSERT OR IGNORE` then checks `changes()` to distinguish duplicate vs success without relying on exception message parsing.
- Completed-game check is done with a single `SELECT status FROM games WHERE id = ?` before the insert/update.
