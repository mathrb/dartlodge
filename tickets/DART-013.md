## DART-013 — `GameRepositoryImpl.getActiveGame` silently returns the first of potentially many active games

**Type:** Bug  
**Component:** `lib/features/game/data/repositories/game_repository_impl.dart`

### Description

The query `WHERE is_complete = 0 LIMIT 1` silently ignores the case where multiple incomplete games exist in the database. The database schema has no unique constraint preventing this. If a game is created but `completeGame` is never called (e.g., due to a crash), a ghost game accumulates and the wrong game may be returned as "active".

### Required changes

1. Add a database-level partial unique index or check: at most one row may have `is_complete = 0`.
2. If enforcing at the DB level is not feasible, add an assertion in `getActiveGame` that logs a warning (or throws) when more than one incomplete game is found.

```sql
-- Option A: unique partial index (SQLite 3.8+)
CREATE UNIQUE INDEX IF NOT EXISTS idx_games_single_active
ON games (is_complete) WHERE is_complete = 0;
```

### Acceptance criteria

- [ ] Creating a second game while one is already active is rejected at the DB level or caught and surfaced clearly
- [ ] `getActiveGame` does not silently return a stale ghost game
- [ ] Migration or schema note documents the constraint

