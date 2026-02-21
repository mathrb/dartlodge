## DART-007 — Multi-leg game support missing (Tables J and K)

**Type:** Feature  
**Component:** `lib/features/game/domain/engines/stateless_x01_engine.dart`  
**Spec reference:** `x01_transitions.md — Tables J, K, L`

### Description

The engine has no concept of legs. When a checkout occurs it marks the game as complete, regardless of how many legs are configured. A best-of-5 game therefore ends on the first leg won.

Tables J and K require:
- `legs_won += 1` for the winning competitor
- If `legs_won < legs_to_win`: reset all scores to `starting_score`, reset all `is_in = false`, reset turn, increment `current_leg_index`
- If `legs_won == legs_to_win`: emit `GameCompleted`

### Required changes

1. Add `_applyLegCompleted(GameState, GameEvent)` handler.
2. Implement reset logic per Table K.
3. Implement game completion check per Table J / Table L.
4. `CreateGameUseCase` must emit a `LegCompleted` event shape; engine must handle it.

### Acceptance criteria

- [ ] Best-of-1 game completes after one checkout (existing behaviour preserved)
- [ ] Best-of-3 game requires 2 legs won before `GameCompleted`
- [ ] After leg reset: all competitors' scores return to `startingScore`
- [ ] After leg reset: all `isIn` values reset to `false`
- [ ] `currentLegIndex` increments after each leg reset
- [ ] `legsWon` is correctly tracked per competitor and visible in state

