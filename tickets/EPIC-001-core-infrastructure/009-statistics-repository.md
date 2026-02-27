# TICKET-009: Statistics Repository (SQLite + Drift)

**Status:** Done
**Epic:** EPIC-001 — Core Infrastructure

---

## Description

Implement the `StatisticsRepository` interface for both backends. Statistics are projections — the repository never owns a table; it queries `dart_throws` and `game_events` to compute aggregates on demand.

---

## Acceptance Criteria

- [x] `StatisticsRepositoryImpl` (sqflite) implements all methods from `docs/REPOSITORY_INTERFACES.md`
- [x] `StatisticsRepositoryDrift` (Drift) implements the same interface with identical behaviour
- [x] `getPlayerStats` returns a `PlayerStats` entity computed from raw `dart_throws` and `game_events`
- [x] `getGameStats` returns a `GameStats` entity for a single completed or in-progress game
- [x] `getLeaderboard` returns players ranked by the requested metric, computed live
- [x] No statistics value is stored in any database table — all figures are computed at query time
- [x] Both implementations throw `StatisticsNotFoundException` when queried for a player or game that does not exist
- [x] Both implementations pass the shared contract suite in `test/contracts/statistics_repository_contract.dart`

---

## Files

- `lib/features/statistics/data/repositories/statistics_repository_impl.dart` — created
- `lib/core/persistence/drift/repositories/statistics_repository_drift.dart` — created

---

## Implementation Notes

- `getPlayerStats` joins `dart_throws` and `games` via `competitors` to scope throws to the player's games.
- Averages (three-dart average, checkout %) are computed as `SUM / COUNT` inside SQL for efficiency — they are never materialised in a column.
- `getGameStats` replays `game_events` in `local_sequence` order to reconstruct per-turn and per-leg breakdowns.
- The Drift implementation uses `.map()` on query results to avoid raw SQL where the type-safe API covers the need; falls back to `customSelect` for complex aggregation queries.
- `StatisticsNotFoundException` is thrown (not an empty result) when the player or game row is missing — callers can distinguish "no data yet" (empty stats) from "entity does not exist".
- Ratio fields on `PlayerStats` and `GameStats` are always computed from stored counters, never stored independently — enforcing the statistics-as-projections rule.
