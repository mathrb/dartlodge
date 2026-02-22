## DART-006 — Engine has no access to game config (`inStrategy`, `outStrategy`); out strategy is hardcoded

**Type:** Bug  
**Component:** `lib/features/game/domain/engines/stateless_x01_engine.dart`  
**Spec reference:** `x01_transitions.md — Tables C, E`

### Description

The engine signature is `apply(GameState state, GameEvent event)`. `GameState` contains no reference to game configuration. The engine currently hardcodes double-out via a comment:

```dart
// TODO: Check out strategy from config
// For now, assume double out if not specified
if (multiplier != 2 && parsedSegment is! DoubleBullSegment) {
  isBust = true;
}
```

Without access to `inStrategy` and `outStrategy`, the engine cannot correctly implement Tables C and E for any game with non-default rules.

### Options

**Option A (recommended):** Include a `GameConfig` object inside `GameState` so the engine always has it available.

```dart
@freezed
abstract class GameState with _$GameState {
  const factory GameState({
    // ...
    required X01GameConfig config, // carries inStrategy, outStrategy, startingScore
  }) = _GameState;
}
```

**Option B:** Add a `config` parameter to the engine method: `apply(GameState, GameEvent, GameConfig)`. This keeps state and config separated but requires callers to always supply config.

### Acceptance criteria

- [x] Engine can read `inStrategy` and `outStrategy` without hardcoding
- [x] Straight-out game: any segment reaching 0 completes the leg
- [x] Double-out game: only a double (or double bull) reaching 0 completes the leg
- [x] Master-out game: double or triple reaching 0 completes the leg
- [x] Config is serialised/deserialised correctly as part of GameState JSON

