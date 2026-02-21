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

- [ ] Bust on dart 1 leaves score unchanged ✓
- [ ] Bust on dart 2 restores score to value at turn start ✓
- [ ] Bust on dart 3 restores score to value at turn start ✓
- [ ] Unit tests added for bust-on-dart-2 and bust-on-dart-3 scenarios

