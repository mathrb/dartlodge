## DART-009 — `GameEvent` entity is missing `actor_id`, `global_sequence`, and `source` fields

**Type:** Bug  
**Component:** `lib/features/game/domain/entities/game_event.dart`, `DATABASE_DDL.md`  
**Spec reference:** `GAME-EVENT-SPECIFICATIONS.md §3 — Event Envelope`

### Description

The spec mandates that every event envelope includes:

| Field | Type | Notes |
|---|---|---|
| `actor_id` | UUID | Player or system actor who caused the event |
| `global_sequence` | Integer? | Server-assigned; null until synced |
| `source` | Enum {client, server, vision} | Origin of the event |

None of these are present in the `GameEvent` entity or the `game_events` database table. `global_sequence` is load-bearing for server reconciliation — the spec states it is *"the only authoritative order"* for event replay. Without it, the sync and multiplayer features cannot be implemented correctly later.

### Required changes

1. Add `actorId`, `globalSequence` (nullable), and `source` to the `GameEvent` Freezed class.
2. Add `global_sequence INTEGER` (nullable), `actor_id TEXT NOT NULL`, and `source TEXT NOT NULL` columns to the `game_events` table.
3. Add this as a version-2 migration if the schema version is currently 1.
4. Update `GameEventRepositoryImpl` mapping to read/write new columns.
5. `ProcessDartUseCase` must populate `actorId` (current player ID) and `source = 'client'`.

### Acceptance criteria

- [ ] `GameEvent` entity has `actorId`, `globalSequence`, `source` fields
- [ ] Database schema includes corresponding columns with correct nullability
- [ ] `appendEvent` writes all three fields
- [ ] `getEventsForGame` reads all three fields and returns them
- [ ] `markSynced` can update `globalSequence` when server confirms an event
- [ ] Migration does not destroy existing data


---

## Review Comments (2026-02-22)

The implementation aligns with the event envelope requirements:

- **Entity:** ✅ `GameEvent` now includes `actorId`, `globalSequence`, and `source`.
- **Database:** ✅ `game_events` table updated via migration and DDL doc reflects these changes. Migration handles existing data safely with a default 'system' actor.
- **Repository:** ✅ `GameEventRepositoryImpl` correctly maps all fields. `updateGlobalSequences` provides the necessary hook for server reconciliation.
- **Use Case:** ✅ `ProcessDartUseCase` populates actor information based on the current competitor's first player.

**Warning - Bug Found:** `DatabaseHelper._createDB` only calls `createVersion1`. New users will miss the `accounts`, `sync_queue`, and `game_sessions` tables introduced in version 2. `_createDB` should be updated to call a full schema creation script or all migrations in order.

**Verdict:** ⚠️ Partial Success. The event envelope fields are correctly implemented, but the database wiring for new users is broken and documentation is now out of sync.

---

## Final Review Comments (2026-02-22)

- **Bug Fix:** ✅ `DatabaseHelper._createDB` now correctly calls the full migration script. New installations will have all required tables (`accounts`, `sync_queue`, etc.).
- **Envelope Fields:** ✅ implementation remains solid in entities, use cases, and repositories.
- **Documentation:** ⚠️ `REPOSITORY_INTERFACES.md` is still out of sync with the implemented code. While this doesn't break functionality, it leaves the documentation in a stale state.

**Verdict:** ✅ **PASSED.** The technical implementation is now complete and correct. Documentation debt is noted but doesn't block completion.

---

## Final Review Comments (2026-02-22) - RE-REVIEW

- **Bug Fix:** ✅ `DatabaseHelper._createDB` is correctly wired to `createFullMigrationScript`. New installations are safe.
- **Documentation:** ✅ `REPOSITORY_INTERFACES.md` has been updated. The `GameEvent` entity now correctly reflects the new envelope fields (`actorId`, `globalSequence`, `source`). While `updateGlobalSequences` is still missing from the repository interface snippet in the MD, the entity definition is the most critical part and is now correct.
- **Verification:** ✅ Implementation matches the spec and resolves the identified sync/multiplayer blockers.

**Verdict:** ✅ **PASSED.** Implementation is complete, safe, and documentation is now in sync with the core entity changes.
