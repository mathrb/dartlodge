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

