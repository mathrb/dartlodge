# EPIC-006: Cricket Game

## Goal
Support full Cricket game play across all four variants (Standard, No Score, Cut Throat, Tactics) with a dedicated game board UI.

## Status
[ ] Not started

## Scope — In

### Engine
- `StatelessCricketEngine` implementing transition tables from `docs/games/cricket.transitions.md`
- Target numbers: 15, 16, 17, 18, 19, 20, Bull
- Mark tracking: 1 mark (single), 2 marks (double), 3 marks (triple) to close a number
- Inner bull (`'DB'`, 50): counts as 2 marks. Outer bull (`'SB'`, 25): counts as 1 mark
- Scoring value for Bull overflow: 25 per mark regardless of inner/outer
- Numbers 1–14 and non-bull 21–24: counted as thrown, no game effect (ignored, not rejected)
- Surplus marks (score ≥ 3 on a number the player has closed):
  - Standard: score face value against opponents who have not yet closed that number
  - No Score: no surplus scoring — closing only
  - Cut Throat: surplus scores added to opponents who have NOT yet closed the number
  - Tactics: same as Standard but only pre-selected numbers are in play
- Win condition:
  - Standard / No Score / Tactics: all numbers closed AND highest score
  - Cut Throat: all numbers closed AND lowest score
- `ProcessCricketDartUseCase` — validates + appends events, delegates state changes to engine
- Engine unit tests:
  - All transition table rows for all four variants
  - Inner bull / outer bull mark counting
  - Surplus scoring for each variant
  - Win conditions for each variant
  - Edge cases: closing multiple numbers in one triple, all numbers closed but not winning score

### Board UI
- **Layout** (same header pattern as X01):
  - Header: menu icon, "Cricket" label, round counter
  - Dark split section: player name + score (MPR) left, MISS button + Undo right
  - Cricket grid (see below)
  - Bottom bar: NEXT ROUND button
- **Cricket grid:**
  - 3 columns (S / D / T) × 7 rows (20, 19, 18, 17, 16, 15, BULL)
  - Each cell tappable — registers that multiplier for that number
  - Mark indicators: `/` (1 mark), `X` (2 marks), circled `X` (closed / 3 marks)
  - Closed number row: greyed out for the closing player, highlighted if opponents still open
- **Score sidebar:** per-player running score (surplus points)
- **MPR metric:** marks per round, shown under player name
- **Cut Throat visual:** scores shown as "points against" with lowest highlighted

## Scope — Out
- X01 board (EPIC-005)
- Practice modes (EPIC-007)
- Statistics projections for Cricket (deferred to EPIC-008 extension)

## Key User Stories
- As a player, I can play Standard Cricket and score surplus points when my opponents haven't closed a number.
- As a player, I can play Cut Throat Cricket where hitting open numbers hurts my opponents.
- As a player, I see mark indicators on each number so I know what's closed and what's open.
- As a developer, the Cricket engine passes all transition table tests so that rule variants are correct.

## Technical Components
- `lib/features/game/domain/engines/cricket_engine.dart` — `StatelessCricketEngine`
- `lib/features/game/domain/usecases/process_cricket_dart_use_case.dart`
- `lib/features/game/presentation/pages/cricket_board_page.dart`
- `lib/features/game/presentation/widgets/cricket_grid_widget.dart`
- `lib/features/game/presentation/widgets/cricket_mark_indicator_widget.dart`
- `lib/features/game/presentation/widgets/cricket_score_sidebar_widget.dart`
- `lib/features/game/presentation/providers/active_cricket_game_provider.dart`
- `lib/features/game/presentation/state/active_cricket_game_state.dart`
- `test/features/game/domain/engines/cricket_engine_test.dart`

## Dependencies
- EPIC-001 (persistence)
- EPIC-003 (engine interface pattern, `CreateGameUseCase`)
- EPIC-004 (game setup flow, variant selection wires to Cricket board)

## Spec References
- `docs/games/cricket.transitions.md` — authoritative transition tables for all variants
- `docs/UI_SCREEN_FLOWS_V3_FINAL.md` — Cricket Board section
- `docs/GAME-EVENT-SPECIFICATIONS.md` — event types applicable to Cricket
