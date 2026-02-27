# TICKET-011: Fix GameEventRepositoryDrift — Game-Existence Guard + Contract Tests

**Status:** In Progress
**Epic:** EPIC-001 — Core Infrastructure

---

## Description

Two gaps were found during review of TICKET-008 (GameEvent Repository):

1. `GameEventRepositoryDrift.appendEvent` and `appendEvents` do not verify that the target game exists before inserting. The sqflite implementation (`game_event_repository_impl.dart`) performs this check and throws `GameNotFoundException`. The Drift implementation silently succeeds (foreign-key constraints are not enforced in the test environment), making the two implementations behaviourally asymmetric against `docs/REPOSITORY_INTERFACES.md` §4.

2. No Drift-specific contract test file exists for `GameEventRepository`. Every other repository has a hybrid test (`*_drift_contract_test.dart`). Game events is the only missing one.

Additionally, the shared contract suite lacked a test confirming that `GameNotFoundException` is thrown for a non-existent game, meaning neither implementation's coverage was confirmed by the suite.

---

## Acceptance Criteria

- [ ] `GameEventRepositoryDrift.appendEvent` throws `GameNotFoundException` when `gameId` does not exist
- [ ] `GameEventRepositoryDrift.appendEvents` throws `GameNotFoundException` when `gameId` does not exist
- [ ] Shared contract suite includes a test asserting `GameNotFoundException` on `appendEvent` with unknown game
- [ ] `test/contracts/game_event_repository_drift_contract_test.dart` exists and runs both SQLite and Drift engines

---

## Files

- `lib/core/persistence/drift/repositories/game_event_repository_drift.dart` — edited
- `test/contracts/game_event_repository_contract.dart` — edited
- `test/contracts/game_event_repository_drift_contract_test.dart` — created

---

## Implementation Notes

- The game-existence check uses `getSingleOrNull()` on the `games` table — the same pattern used by `GameRepositoryDrift`.
- The check in `appendEvent` must occur **before** the try/catch insert block so the exception is not accidentally swallowed.
- The check in `appendEvents` must occur **after** the empty-guard but **before** the transaction, to avoid entering a transaction for a non-existent game.
- The Drift hybrid contract test follows the identical structure as `dart_throw_repository_drift_contract_test.dart`.
