# EPIC-003: X01 Game Engine

## Goal
Provide a pure, fully-tested X01 game logic engine that implements all transition tables from the spec and can be composed with any UI layer.

## Status
[x] Complete

## Scope — In
- `StatelessX01Engine` implementing transition Tables A–L from `docs/games/x01.transitions.md`
- In-strategy enforcement: straight-in, double-in, master-in
- Out-strategy enforcement: straight-out, double-out, master-out
- Bust handling: immediate turn end on bust, score reset to pre-turn value
- Bull segment handling: `'SB'` (25) and `'DB'` (50); `'DB'` counts as a double for in/out validation
- Failed in-dart: dart is consumed (thrown) but does not score — turn continues
- Score floor: dart that would take score below zero is a bust
- Multi-leg games: `legsToWin` config, leg reset on `LegCompleted`, game completion detection
- `CreateGameUseCase` — validates config, writes `GameCreated` + `LegStarted` events
- `ProcessDartUseCase` — validates dart via engine, appends `DartThrown` / `TurnEnded` / `LegCompleted` / `GameCompleted` events
- `UndoLastDartUseCase` — appends `DartCorrected` event, replays to previous state
- Engine unit tests covering:
  - Every row in transition Tables A–L
  - All bust conditions (negative, exact-out-miss, strategy violations)
  - All win conditions (single-leg, multi-leg)
  - All explicitly-resolved ambiguities from the transition doc

## Scope — Out
- Cricket / Around the Clock engines (EPIC-006, EPIC-007)
- UI rendering (EPIC-005)
- Statistics projections (EPIC-008)

## Key User Stories
- As a game engine, I correctly apply every dart throw to the current game state so that scores are always accurate.
- As a game engine, I detect bust conditions immediately and end the turn so that no illegal scores are recorded.
- As a game engine, I enforce the configured in/out strategy so that games follow the agreed rules.
- As a developer, every transition table row has a passing test so that regressions are caught immediately.

## Technical Components
- `lib/features/game/domain/engines/x01_engine.dart` — `StatelessX01Engine`
- `lib/features/game/domain/engines/game_engine.dart` — abstract `GameEngine` interface
- `lib/features/game/domain/usecases/create_game_use_case.dart`
- `lib/features/game/domain/usecases/process_dart_use_case.dart`
- `lib/features/game/domain/usecases/undo_last_dart_use_case.dart`
- `lib/features/game/domain/entities/game.dart` — already exists
- `lib/features/game/domain/entities/game_event.dart` — already exists
- `lib/features/game/domain/entities/dart_throw.dart` — already exists
- `test/features/game/domain/engines/x01_engine_test.dart`
- `test/features/game/domain/usecases/create_game_use_case_test.dart`
- `test/features/game/domain/usecases/process_dart_use_case_test.dart`

## Dependencies
- EPIC-001 (repository interfaces + exception hierarchy)

## Spec References
- `docs/games/x01.transitions.md` — authoritative transition tables A–L + resolved ambiguities
- `docs/GAME-EVENT-SPECIFICATIONS.md` — canonical event types and payloads
- `docs/REPOSITORY_INTERFACES.md` — `GameEventRepository`, `DartThrowRepository`
