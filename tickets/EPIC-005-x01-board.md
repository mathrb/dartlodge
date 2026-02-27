# EPIC-005: X01 Game Board

## Goal
Provide a fully interactive X01 game screen where players input darts, see live scores update, and complete legs and matches — all wired to the X01 engine via Riverpod.

## Status
[ ] Not started — provider scaffold exists

## Scope — In
- **Board layout:**
  - Header: menu icon, game type label, round/leg counter
  - Dart throw indicators (3 slots, filled as darts are thrown this turn)
  - Dark player-score section: active player name (highlighted), remaining score (120pt bold), PPR metric
  - Inactive player row(s): name + remaining score (smaller)
  - Dart input grid (see below)
  - Bottom bar: NEXT ROUND button (disabled until 3 darts thrown or bust), Undo button
- **Dart input grid:**
  - Row 1: MISS | BULL (SB=25, DB=50)
  - Rows 2–21: Singles 20→1
  - Doubles row: D20→D1 with dot indicator
  - Triples row: T20→T1 with dot indicator
- **Turn flow:**
  1. Player taps dart segment → `ProcessDartUseCase` called → score updates
  2. After 3rd dart or bust → NEXT ROUND button activates
  3. NEXT ROUND → `TurnEnded` event appended → next player's turn begins
- **Bust display:** score flashes red, dart indicators clear, "BUST" label shown briefly
- **Undo:** taps Undo → `UndoLastDartUseCase` → board state reverts one dart
- **Leg completion modal:** winner name, leg score (darts used), "Next Leg" button
- **Game completion modal:** overall winner, final score, "New Game" and "View Stats" actions
- **`ActiveGameNotifier`** (`AsyncNotifier`, `keepAlive` while game active):
  - On init: loads game from `getGame(id)` + replays all events via X01 engine to rebuild state
  - On dart: calls `ProcessDartUseCase`, emits updated `ActiveGameState`
  - On undo: calls `UndoLastDartUseCase`
  - Watches `watchEventsForGame(gameId)` stream for real-time updates
- **`ActiveGameState`** (freezed): current scores per competitor, darts thrown this turn, whose turn, leg/match progress, bust flag, completion state

## Scope — Out
- Cricket board (EPIC-006)
- Practice board (EPIC-007)
- Statistics overlay during game (EPIC-008 — wired later as overlay)

## Key User Stories
- As a player, I can tap dart segments to record my throws so that scores update without manual arithmetic.
- As a player, I see a bust notification immediately when my turn busts so that I know to hand over.
- As a player, I can undo my last dart if I entered it incorrectly so that the score stays accurate.
- As a player, I see a completion screen when a leg or the match ends so that the result is celebrated.

## Technical Components
- `lib/features/game/presentation/pages/x01_board_page.dart`
- `lib/features/game/presentation/widgets/dart_input_grid_widget.dart`
- `lib/features/game/presentation/widgets/player_score_section_widget.dart`
- `lib/features/game/presentation/widgets/dart_indicator_widget.dart`
- `lib/features/game/presentation/widgets/bust_overlay_widget.dart`
- `lib/features/game/presentation/widgets/leg_complete_modal_widget.dart`
- `lib/features/game/presentation/widgets/game_complete_modal_widget.dart`
- `lib/features/game/presentation/providers/active_game_provider.dart`
- `lib/features/game/presentation/state/active_game_state.dart`

## Dependencies
- EPIC-001 (persistence)
- EPIC-003 (X01 engine + use cases)
- EPIC-004 (game setup flow creates the game and navigates here)

## Spec References
- `docs/UI_SCREEN_FLOWS_V3_FINAL.md` — X01 Board section: layout, dart grid, player section
- `docs/STATE_MANAGEMENT.md` — `ActiveGameNotifier` pattern, stream watching
- `docs/GAME-EVENT-SPECIFICATIONS.md` — event types for dart input and turn/leg/game lifecycle
