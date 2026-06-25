# Statistics & projections rules

> Loaded on demand. CLAUDE.md's Rules Index points here before touching stats, projections, or formatters.

### Statistics scope resets
Turn resets on `TurnStarted`, Leg resets on `LegCompleted`, Match resets on `GameCompleted`. No other reset points.

### Computing stats over an event slice
All projection wiring lives in `PlayerStatsAssembler` (`lib/features/statistics/domain/assemblers/`). Use the method that matches the scope: `fromEvents` (career), `gameStatsFromEvents` (per-game), `playerStatsForGameFromEvents` (per-player-per-game), `legCompetitorStatsFromEvents` (per-leg). Repos and use cases load events and delegate. If you need a new projection bundle, add it to the assembler — do not re-wire `ProjectionRunner` directly in repos or use cases. Snapshot keys: `x01_average`, `x01_checkout`, `x01_highest_checkout`, `x01.highScoreBuckets`, `cricket.mpt`, `cricket.markBuckets`, `cricket.firstNineMpr`. First-nine projections (`cricket.firstNineMpr`, X01 first-nine PPR) only count when `TurnStarted` events are present — fixtures emitting just `DartThrown`/`TurnEnded` silently produce null first-nine stats.

### `GameStats.gameType` is load-bearing
The post-game summary branches on `gameStats.gameType == GameType.cricket.name` to choose MPR vs PPR labels and rows. Every return path of `getGameStats` (including the empty-darts early return) must set it, in both repository implementations.

### Statistics loader vs computation
Statistics computation lives in `PlayerStatsAssembler` (shared). The loader queries live in `lib/core/persistence/drift/repositories/statistics_repository_drift.dart` — load events + dart_throws, then delegate to the assembler. When changing how stats are computed, update only the assembler.

### Cricket mark-bucket field overload
`CompetitorStats.{five..nine}MarkTurns` are populated as **exact-N** counts by `getGameStats` and `ComputeLegStatsUseCase` (read from the `*Exact` snapshot keys) but as **≥-N** counts by `getPlayerStats` (read from the `*MarkTurns` keys). Same field, different cohorts by call path.

### Statistics scope is required
`getPlayerStats` and `watchPlayerStats` take `required GameType gameType`. PPR-shaped fields are X01-only and cricket fields are cricket-only — a single call cannot mix types coherently. The player-picker AVG badge consumes `playerStatsProvider`, which passes `GameType.x01`.

### Projection snapshots are two-level
Top level keyed by `engine.descriptor.id` (e.g. `'x01.doubleOut'`), inner map keyed by field name (e.g. `'doubleOutSuccessRate'`). Wiring a new engine into `PlayerStatsAssembler.fromEvents` means reading at both levels — running an engine without reading its snapshot is a silent no-op.

### Number formatting
Use `StatFormatter` (`lib/core/utils/stat_formatter.dart`) for all statistics display — `fmtDouble`, `fmtPct`, `fmtPerLeg`. Never use inline `toStringAsFixed()` in statistics UI. `test.yml`'s "Stats UI formatter gate" greps `lib/features/*/presentation/` for `toStringAsFixed` and fails CI on ANY match (not just stats) — route every number through `StatFormatter` (it wraps `toStringAsFixed` in `core/utils`, outside the gate), even non-stat labels like a `2.5×` zoom readout.

### Widget test finders (stat literals)
`StatFormatter.fmtDouble` strips trailing zeros — e.g. `170.0` → `'170'`, which collides with raw `int` values rendered the same way. Prefer `findsNWidgets(n)` or more specific finders (`find.descendant`) over `findsOneWidget` when stat rows may share literals.
