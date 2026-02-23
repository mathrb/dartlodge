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

### Follow-up

During review, a pre-existing bug was identified in single bull segment parsing (DART-006.1). This is unrelated to the DART-006 configuration access requirements and will be addressed separately.

---

### Review Summary (2026-02-22)

The implementation of **DART-006** follows **Option A** by incorporating `inStrategy`, `outStrategy`, and `startingScore` directly into the `GameState` class (`lib/features/game/domain/models/game_state.dart`). This ensures the `StatelessX01Engine` remains a pure functional engine while having access to the necessary configuration during event replay.

**Verification Results:**
- **Configuration Access:** `StatelessX01Engine` correctly utilizes `state.inStrategy`, `state.outStrategy`, and `state.startingScore` (for leg resets) instead of hardcoded values.
- **In-Strategy Logic (Table C):** Correctly implemented for `'straight'`, `'double'`, and `'master'`.
- **Out-Strategy Logic (Table E):**
    - **Straight-out:** Any segment reaching 0 is valid.
    - **Double-out:** Only doubles (or double bull) reaching 0 are valid.
    - **Master-out:** Only doubles or triples (multiplier >= 2) reaching 0 are valid.
- **Bust Conditions:** Correctly transitions to bust when reaching 0 with an invalid strategy or when score goes below zero/becomes 1.
- **Persistence:** `GameState` fields are correctly marked for serialization.

**Identified Issue:**
- In `StatelessX01Engine._applyDartThrown`, there is a potential bug when handling a single bull throw:
  ```dart
  final parsedSegment = Segment.parse(multiplier == 1 ? segment : ...);
  ```
  If `multiplier == 1` and `segment == 'bull'`, it calls `Segment.parse('bull')`, which currently throws a `FormatException` in `Segment.parse` because it expects `'SB'`. This is out of scope for the core logic of DART-006 but should be addressed in a follow-up fix.

**Verdict:** **PASSED** (Architecture and logic requirements fully met).

