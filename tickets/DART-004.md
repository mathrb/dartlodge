## DART-004 — Engine does not advance the active player after `TurnEnded` (Table I)

**Type:** Bug  
**Component:** `lib/features/game/domain/engines/stateless_x01_engine.dart`  
**Spec reference:** `x01_transitions.md — Table I`

### Description

`_applyTurnEnded` resets `dartsThrownInTurn` to 0 but never advances `currentTurnIndex` to the next competitor. This means every turn is assigned to the same competitor for the entire game — no player rotation occurs.

### Current state

```dart
GameState _applyTurnEnded(GameState state, GameEvent event) {
  return state.copyWith(dartsThrownInTurn: 0); // currentTurnIndex unchanged
}
```

### Required change

```dart
GameState _applyTurnEnded(GameState state, GameEvent event) {
  final nextIndex = (state.currentTurnIndex + 1) % state.competitors.length;
  return state.copyWith(
    dartsThrownInTurn: 0,
    turnActive: false,           // Table I
    currentTurnIndex: nextIndex, // Table I — Advance current_player
  );
}
```

### Acceptance criteria

- [x] After a 3-dart turn, `currentTurnIndex` increments
- [x] After the last competitor's turn, index wraps to 0
- [x] `turnActive` is set to `false` on TurnEnded
- [x] Two-player game: players alternate correctly across multiple turns
- [x] Four-player game: rotation visits all four players in order

### Review

The fix for `DART-004` has been implemented in `lib/features/game/domain/engines/stateless_x01_engine.dart`. The `_applyTurnEnded` method now correctly calculates the next player index using modulo operator, resets the dart count, and deactivates the turn.

Unit tests in `test/features/game/domain/engines/stateless_x01_engine_test.dart` specifically verify these requirements:
- `DART-004 should advance currentTurnIndex to next player on TurnEnded`
- `DART-004 should wrap currentTurnIndex to 0 after last player`
- `DART-004 two-player game should alternate players correctly`
- `DART-004 four-player game should rotate through all players`

All tests passed successfully.

