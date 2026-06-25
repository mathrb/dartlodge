# Game engine rules (events, rounds, payloads, RNG)

> Loaded on demand. CLAUDE.md's Rules Index points here before touching game events, rounds, dart payloads, RNG, or game lifecycle.

### GameConfig dispatch
Use `maybeMap` (not `maybeWhen`) — callbacks receive typed subclass instances: `config.maybeMap(x01: (c) => c.startingScore, orElse: () => '')`. Requires explicit `import 'game_config.dart'`; not available via transitive import.

### DartThrown payload keys
`competitor_id`, `player_id`, `segment`, `multiplier`, `score`, `input_method`, plus optional `x`/`y` (see `buildDartThrownEvent` in `lib/features/game/domain/usecases/game_use_case_helpers.dart`). `x`/`y` are the auto-scorer's normalised canonical impact position (#571, canonical scoring frame: origin = centre, radius 1.0 at the double ring, **5/20 calibration wire at top** so segment 20's centre is ~9° clockwise of vertical; the heatmap widget rotates only the *display* via `kHeatmapDisplayRotation` to show a standard "20 at top" board, #697 — stored values stay in the wire-at-top frame) — **omitted when null** (manual entry, noise, pre-#571 events) so old events parse unchanged. The same values are written to `dart_throws.x`/`.y`. The use cases read them off the `DartThrow` they already receive (the notifier sets them); a correction/undo deletes the dart and re-entry is manual → position stays null by design. No `turn_number`, no `dart_number` — reconstruct turn grouping via `TurnStarted`/`TurnEnded` event boundaries if needed.

### `local_sequence` is per-game, not global
Every new game restarts `local_sequence` at 1, so multiple games' events share the same sequence range. Any query that loads events across multiple games MUST sort by `(game_id, local_sequence)` — sorting by `local_sequence` alone interleaves games and corrupts projection state across game boundaries. `ProjectionRunner.run()` enforces this internally; SQL queries feeding it should match.

### RNG in use cases
Event-emitting use cases that need randomness (e.g. `CreateGameUseCase`, `ProcessCricketDartUseCase` for `CrazyTargetsRolled`) accept an optional `math.Random?` constructor parameter that defaults to `math.Random()` in production. Tests inject a seeded `math.Random(seed)` for determinism. RNG runs **once at emission**, the value lands in the event payload, and `engine.apply()` is pure — replay never re-rolls.

### Round semantics
A "round" is one full rotation where ALL competitors throw. `totalRounds` is the correct field name. Do not use `maxRounds` or count per-competitor turns or individual dart throws as rounds.

### Per-leg round cap
X01 and Cricket enforce a round cap per leg (see `GameConfigurationConstants` and engine logic). When the cap is hit with no winner, the leg is decided by current standing — do not extend rounds silently. Both engines and any UI showing round progress must respect this.

### `DartCorrected` payload key is `original_event_id`
A string referencing the corrected `DartThrown.eventId`. Any replay-aware code path (`UndoLastDartUseCase`, `PlayerStatsAssembler.fromEvents`) must collect these and skip the originals.

### `endGame()` / `endDrill()` write `is_complete=true` to the DB but do NOT mutate `state.value.gameState.isComplete`
The post-game-navigation listener (`practice_board_page` / `x01_board_page` etc.) watches that flag and would otherwise route every menu-driven exit through post-game instead of home. When you need an authoritative "is this game complete?" signal outside the active-game provider (e.g. from the router's `onExit`), read it from `GameRepository.getGame(id)`, not the notifier state. See `app_router.dart`'s `_gameIsComplete` helper for the pattern.
