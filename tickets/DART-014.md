## DART-014 — `StatisticsRepositoryImpl` throws `UnimplementedError` at runtime with no user-visible error handling

**Type:** Feature / Risk  
**Component:** `lib/features/statistics/data/repositories/statistics_repository_impl.dart`  
**Spec reference:** `statistics_architecture.md`, `x01_projections.md`

### Description

Every method in `StatisticsRepositoryImpl` throws `UnimplementedError`. Any code path that reaches the statistics layer will crash the app with an unhandled exception. The spec defines statistics as projections computed on-demand from `dart_throws` and `game_events`.

This ticket covers two deliverables:
1. Implement the core X01 statistics projections.
2. In the interim (before implementation), replace `UnimplementedError` with a handled empty response so the app does not crash.

### Phase 1 — Safe stub (immediate)

Replace `throw UnimplementedError()` with a returned empty/zero value and a `debugPrint` warning so UI degrades gracefully.

### Phase 2 — Implementation

Implement at minimum:
- `getPlayerStats(playerId)` → 3-dart average, total games, total legs, checkout %
- `getGameStats(gameId)` → per-competitor summary for the game history screen

Per spec: compute by querying `dart_throws` joined to `game_events`; do not store derived stats as facts.

### Acceptance criteria (Phase 1)

- [ ] No `UnimplementedError` is ever thrown to the UI
- [ ] Statistics screens show an empty/placeholder state rather than crashing

### Acceptance criteria (Phase 2)

- [ ] `getPlayerStats` returns correct 3-dart average for a player with known history
- [ ] `getGameStats` returns correct per-competitor scores for a completed game
- [ ] Statistics are recomputed from raw events (not from a stored cache)

