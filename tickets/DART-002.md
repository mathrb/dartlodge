## DART-002 — Engine does not capture `turn_start_score` on `TurnStarted`; bust does not restore score

**Type:** Bug  
**Component:** `lib/features/game/domain/engines/stateless_x01_engine.dart`  
**Spec reference:** `x01_transitions.md — Table A, Table F`

### Description

Table A requires that `turn_start_score = score` be captured when a `TurnStarted` event is applied. Table F requires that on a bust, `score` is restored to `turn_start_score`. Neither behaviour is implemented. As a result, a bust on dart 2 or dart 3 does not roll back the score changes from the earlier darts in the same turn, producing a permanently incorrect score.

### Steps to reproduce

1. Start a 501 double-out game.
2. Player throws T20 (dart 1) → score becomes 441.
3. Player throws T20 (dart 2) → score becomes 381.
4. Player throws T20 (dart 3) → score becomes 321.
5. **Bust:** Player hits D25 (dart 2 of next turn, leaving 1) — score should revert to 381 but does not.

### Root cause

`_applyTurnStarted` does not write `turnStartScore` (field does not exist; see DART-001). `_applyDartThrown` on bust sets `dartsThrownInTurn = 3` but does not restore score:

```dart
// Current — bust handling (incorrect)
if (isBust) {
  return state.copyWith(dartsThrownInTurn: 3); // score NOT restored
}
```

### Required changes

After DART-001 lands:

1. In `_applyTurnStarted`: set `competitor.turnStartScore = competitor.score`.
2. In `_applyDartThrown` bust branch: set `competitor.score = competitor.turnStartScore`.

### Acceptance criteria

- [x] Bust on dart 1 leaves score unchanged ✓
- [x] Bust on dart 2 restores score to value at turn start ✓
- [x] Bust on dart 3 restores score to value at turn start ✓
- [x] Unit tests added for bust-on-dart-2 and bust-on-dart-3 scenarios

### Review (2026-02-21)

The implementation of **DART-002** correctly follows the requirements of Table A and Table F of the X01 specification.

1.  **Turn Start Capture**: `_applyTurnStarted` now correctly captures the competitor's current score into `turnStartScore`.
2.  **Bust Restoration**: In `_applyDartThrown`, the bust logic correctly restores the competitor's score to `turnStartScore` and forces the turn to end (`dartsThrownInTurn: 3`).
3.  **Verification**: 
    -   Verified the logic in `lib/features/game/domain/engines/stateless_x01_engine.dart`.
    -   Ran existing unit tests in `test/features/game/domain/engines/stateless_x01_engine_test.dart`, including specific new tests for bust-on-dart-2 and bust-on-dart-3.
    -   All tests passed successfully (+20 tests).

Status: **PASSED**


