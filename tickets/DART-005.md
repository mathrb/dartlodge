## DART-005 — `ActiveGameProvider.build()` always returns `null`; game state is never reconstructed from events

**Type:** Bug  
**Component:** `lib/features/game/presentation/providers/active_game_provider.dart`  
**Spec reference:** `GAME-EVENT-SPECIFICATIONS.md §8 — Replay & Recovery Rules`

### Description

`ActiveGameProvider.build()` correctly detects that an active game exists, then unconditionally returns `null`. Game state is never reconstructed from the event log. This means:

- The app cannot resume a game after restart.
- `processDart` always fails because `currentState == null`.
- The game is functionally broken end-to-end.

```dart
@override
Future<GameState?> build() async {
  final activeGame = await gameRepository.getActiveGame();
  if (activeGame == null) return null;

  // TODO: reconstruct GameState from events
  return null; // ← always null
}
```

The spec is explicit: *"State reconstruction is done by replaying all events"* (§8).

### Required implementation

```dart
@override
Future<GameState?> build() async {
  final game = await ref.read(gameRepositoryProvider).getActiveGame();
  if (game == null) return null;

  final events = await ref.read(gameEventRepositoryProvider)
      .getEventsForGame(game.gameId);

  if (events.isEmpty) return null;

  final engine = ref.read(x01EngineProvider);
  var state = GameState.initial(game);

  for (final event in events) {
    state = engine.apply(state, event);
  }

  return state;
}
```

### Acceptance criteria

- [ ] Killing and relaunching the app restores the game to the correct state
- [ ] All darts thrown before restart are reflected in reconstructed scores
- [ ] Current turn index and `isIn` are correctly reconstructed
- [ ] `processDart` succeeds after reconstruction (no null state crash)
- [ ] Integration test: create game → throw 5 darts → restart provider → assert state matches

