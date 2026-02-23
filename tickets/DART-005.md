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

- [x] Killing and relaunching the app restores the game to the correct state
- [x] All darts thrown before restart are reflected in reconstructed scores
- [x] Current turn index and `isIn` are correctly reconstructed
- [x] `processDart` succeeds after reconstruction (no null state crash)
- [x] Integration test: create game → throw 5 darts → restart provider → assert state matches

### Review

The implementation of `ActiveGameProvider.build()` in `lib/features/game/presentation/providers/active_game_provider.dart` now correctly reconstructs the game state by replaying all events from the `GameEventRepository`. 

Key observations:
1. **State Reconstruction:** The `build()` method retrieves the active game, its competitors, and all associated events. It then uses the `StatelessX01Engine` to replay these events onto an initial state created via the new `GameState.initial()` factory.
2. **Factory Method:** `GameState.initial(game, competitors)` in `lib/features/game/domain/models/game_state.dart` provides a clean way to initialize the state from domain entities, handling both X01 and non-X01 defaults.
3. **Safety:** `processDart` now has a null-check on `currentState`, preventing crashes if called before the game is loaded.

**Note on Testing:** While the unit tests for `GameState.initial` are comprehensive, the integration test in `test/features/game/presentation/providers/active_game_provider_test.dart` is currently a skeleton and should be expanded to perform a full end-to-end replay with real/mocked events to fully satisfy the final acceptance criterion in a CI environment. However, the logic in the provider itself matches the requirements exactly.

One minor style observation: `build()` uses `ref.read` for repository providers. While these are usually `keepAlive: true` and don't change, using `ref.watch` is the standard Riverpod practice inside `build()` to ensure proper dependency tracking.

### Follow-up Review

The developer has addressed the previous feedback:
1. **Dependency Tracking:** `ActiveGameProvider.build()` now uses `ref.watch` for `gameRepositoryProvider` and `gameEventRepositoryProvider`, ensuring the provider correctly reacts to any underlying repository changes. 
2. **Comprehensive Testing:** A new integration test `DART-005 full integration: create game → throw darts → restart → verify state` has been added. This test performs a full replay of a 6-event log onto an initial state and verifies the final scores, turn indices, and dart throw records.

All acceptance criteria are now fully satisfied, including the integration test requirement. The implementation is robust and follows the architectural patterns defined in `docs/STATE_MANAGEMENT.md`.

### Final Verification

The developer has now fully addressed all style and functional suggestions:
- **`ActiveGameProvider`** now uses `ref.watch` for all its dependencies in `build()`, including `x01EngineProvider`.
- **Integration Test** provides complete coverage for the state reconstruction logic.
- **Architectural Alignment:** The implementation perfectly follows the Clean Architecture and Riverpod patterns required by the project.

The ticket is verified and ready to be closed.

