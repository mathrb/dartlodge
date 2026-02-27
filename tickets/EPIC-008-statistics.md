# EPIC-008: Statistics & Projections

## Goal
Deliver a full statistics system — event-replay projection engine, all X01 projections, and a statistics dashboard — so players can track their performance over time.

## Status
[~] In progress — repository aggregations done; projection engine and dashboard UI not started

## Scope — In

### Projection Engine
- `ProjectionEngine` abstract interface with lifecycle: `init()`, `apply(event)`, `reset(scope)`, `snapshot()`
- `ProjectionDescriptor` model: game types supported, events consumed, projection scope
- Scope hierarchy: Dart → Turn → Leg → Match → Career
- Scope reset triggers (canonical events only):
  - Turn scope resets on `TurnStarted`
  - Leg scope resets on `LegCompleted`
  - Match scope resets on `GameCompleted`
- Full replay from correction point on `DartCorrected` — no delta patching
- `ProjectionRunner`: orchestrates multiple `ProjectionEngine` instances against an event stream

### X01 Projections (from `docs/statistics/x01.projections.md`)
- **3-dart average:** total score / (total darts / 3); scopes: turn, match, career
- **Bust rate:** bust_turns / total_turns × 100
- **Checkout percentage:** successful checkouts / checkout attempts × 100 (attempt = score ≤ 170 on turn start, out-strategy applicable)
- **Highest checkout:** max single-turn score resulting in a win
- **Highest turn score:** max score from a single turn (3 darts)
- **Darts per leg:** total darts thrown / legs won
- **Legs won / legs played**
- **First-dart in success rate:** successful double-in (or master-in) attempts / total in-attempts
- **Double-out success rate:** doubles hit on match dart / doubles attempted on match dart
- **Win rate:** games won / games played

### Statistics Repository Wiring
- `StatisticsRepository` existing aggregation methods remain; projection engine adds event-replay layer
- `getPlayerStats(playerId, {gameType?, dateRange?})` — returns `PlayerStats` with all projection values
- `watchPlayerStats(playerId)` — stream that re-emits on new events for that player

### Statistics Dashboard UI
- **Career stats screen per player:**
  - Summary cards: 3-dart avg, checkout %, win rate, darts per leg, legs played
  - Trend sparklines (last 10 sessions)
  - Best game / best checkout highlights
- **Post-game summary screen:** shown after game completion modal; per-competitor stats for that session
- **Per-game stats overlay:** optional slide-up panel during active game showing running avg, checkout %
- **Leaderboard screen:**
  - Ranked by 3-dart average (default), switchable to checkout % or win rate
  - Minimum games filter (default: 5 games)
  - Filter by game type
- **Filter controls:** game type pill selector, date range picker

### Riverpod Providers
- `playerStatsProvider(playerId, {gameType?})` — `StreamProvider` emitting `PlayerStats`
- `liveGameStatsProvider(gameId)` — `StreamProvider` for in-game overlay
- `leaderboardProvider({metric, minGames, gameType?})` — `AsyncNotifierProvider`

### Tests
- All projections pass test categories A–H from `docs/statistics/projection-test-matrix.md`
- X01 projections additionally pass GS1–GS3 from the same matrix
- `DartCorrected` replay produces identical results to a fresh projection run

## Scope — Out
- Cricket statistics projections (can be added as an extension ticket under this epic)
- Practice mode statistics beyond basic hit rate (can be added later)
- Backend statistics sync (EPIC-010)

## Key User Stories
- As a player, I can see my 3-dart average over my career so that I can track my improvement.
- As a player, I can see my checkout percentage so that I know how reliable I am on double-out.
- As a player, I can see a leaderboard so that I can compare myself to others playing on this device.
- As a player, I see my session stats after each game so that I can reflect on my performance.
- As a developer, statistics are never stored as pre-calculated values so that they are always accurate even after a `DartCorrected` event.

## Technical Components
- `lib/features/statistics/domain/engines/projection_engine.dart` — abstract interface
- `lib/features/statistics/domain/engines/projection_runner.dart`
- `lib/features/statistics/domain/engines/x01/x01_average_projection.dart`
- `lib/features/statistics/domain/engines/x01/x01_bust_rate_projection.dart`
- `lib/features/statistics/domain/engines/x01/x01_checkout_projection.dart`
- `lib/features/statistics/domain/engines/x01/` — one file per projection
- `lib/features/statistics/domain/entities/player_stats.dart` — already exists
- `lib/features/statistics/domain/entities/game_stats.dart` — already exists
- `lib/features/statistics/domain/repositories/statistics_repository.dart` — already exists
- `lib/features/statistics/data/repositories/` — implementations already exist; extend for projection engine
- `lib/features/statistics/presentation/pages/career_stats_page.dart`
- `lib/features/statistics/presentation/pages/post_game_summary_page.dart`
- `lib/features/statistics/presentation/pages/leaderboard_page.dart`
- `lib/features/statistics/presentation/widgets/stats_card_widget.dart`
- `lib/features/statistics/presentation/widgets/stats_overlay_widget.dart`
- `lib/features/statistics/presentation/widgets/leaderboard_row_widget.dart`
- `lib/features/statistics/presentation/providers/statistics_provider.dart`
- `test/features/statistics/domain/engines/projection_runner_test.dart`
- `test/features/statistics/domain/engines/x01/` — one test file per projection

## Dependencies
- EPIC-001 (event log, dart_throws table)
- EPIC-003 (X01 engine produces the events that statistics consume)
- EPIC-005 (post-game summary screen triggered from game completion)

## Spec References
- `docs/statistics/statistics.architecture.md` — projection engine design, scope model
- `docs/statistics/x01.projections.md` — all X01 projection definitions and formulas
- `docs/statistics/projection-test-matrix.md` — test categories A–H, GS1–GS3
- `docs/REPOSITORY_INTERFACES.md` — `StatisticsRepository` method signatures
