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

- [ ] After a 3-dart turn, `currentTurnIndex` increments
- [ ] After the last competitor's turn, index wraps to 0
- [ ] `turnActive` is set to `false` on TurnEnded
- [ ] Two-player game: players alternate correctly across multiple turns
- [ ] Four-player game: rotation visits all four players in order

