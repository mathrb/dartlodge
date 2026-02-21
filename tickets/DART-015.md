## DART-015 — `GameEventRepositoryImpl.appendEvents` only validates the first event's `gameId`

**Type:** Bug  
**Component:** `lib/features/game/data/repositories/game_event_repository_impl.dart`

### Description

`appendEvents` guards against appending to a non-existent game by checking if the first event's `gameId` exists. If the caller (pathologically) supplies events from multiple different games in a single batch, events for non-existent games skip validation and would either fail on the foreign key constraint (acceptable) or succeed silently (not acceptable).

While the current call sites always pass a homogeneous list, a more defensive implementation would either validate all distinct `gameId` values in the batch or assert that the entire list shares a single `gameId`.

### Required change

```dart
Future<void> appendEvents(List<GameEvent> events) async {
  // Existing code...
  assert(events.map((e) => e.gameId).toSet().length == 1,
      'appendEvents requires all events to belong to the same game');
  // ...
}
```

Or validate all distinct game IDs before inserting.

### Acceptance criteria

- [ ] Passing events from two different games in one call either throws an assertion in debug mode or validates both game IDs
- [ ] Existing tests for `appendEvents` remain green
- [ ] A test is added that covers the multi-game-ID edge case

