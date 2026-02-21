## DART-003 — In-strategy (Table C) is entirely absent from the engine

**Type:** Bug  
**Component:** `lib/features/game/domain/engines/stateless_x01_engine.dart`  
**Spec reference:** `x01_transitions.md — Table C`

### Description

The engine applies scoring to every dart regardless of whether the competitor has been "let in" by their in-strategy. A double-in or master-in game is therefore identical to a straight-in game — the engine will score any dart from the first throw.

Table C must gate scoring behind an `is_in` check and conditionally satisfy the in-strategy based on the dart's multiplier.

### Required changes

In `_applyDartThrown`, before scoring logic:

```dart
if (!competitor.isIn) {
  // Dart counts as thrown regardless (Note 1 in spec)
  newState = incrementDartCount(newState);

  final satisfied = switch (config.inStrategy) {
    InStrategy.straightIn => true,
    InStrategy.doubleIn   => dart.multiplier == 2 || dart.isDoubleBull,
    InStrategy.masterIn   => dart.multiplier == 2 || dart.multiplier == 3 || dart.isDoubleBull,
  };

  if (!satisfied) {
    // No score change, no bust — just dart count
    return checkTurnEnd(newState);
  }

  newState = newState.withCompetitor(competitor.copyWith(isIn: true));
  // Fall through to scoring
}
```

Note: the engine needs access to `inStrategy` from game config — this also requires DART-006 to be resolved.

### Acceptance criteria

- [ ] Straight-in: any first dart starts scoring
- [ ] Double-in: single/triple on first dart → no score, dart counted, turn continues
- [ ] Double-in: double/bull on first dart → `isIn = true`, score applied
- [ ] Master-in: single on first dart → no score, turn continues
- [ ] Master-in: double or triple → `isIn = true`, score applied
- [ ] Failed in-strategy dart does NOT end the turn (spec Note 1)
- [ ] Unit tests cover all six in-strategy × hit-type combinations

