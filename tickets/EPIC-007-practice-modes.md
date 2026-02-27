# EPIC-007: Practice Modes

## Goal
Provide five practice game types with their own pure engines and a shared board layout that helps players drill specific skills.

## Status
[ ] Not started

## Scope — In

### Engines

**Around the Clock**
- Sequential targets: 1 → 2 → … → 20 → Bull
- Advance target when hit; miss = no advance
- Optional variant: must hit double to advance (double mode)
- Optional variant: triple counts as advancing two numbers
- Win condition: all 20 numbers + Bull hit in order
- Spec: `docs/games/around-the-clock.md`

**Catch 40**
- Each round has a target total (10, 15, 20, 25, … per round spec)
- Player accumulates score; rounds where total ≥ target add that round's target to total score
- Miss or sub-target round: nothing added
- Win: fixed number of rounds completed

**Bob's 27**
- Start with 27 points
- Each round target = current round number doubled (round 1 = D1, round 2 = D2, … round 20 = D20)
- Hit the required double: add (round × 2) × number_hit to score
- Miss all darts on required double: deduct (round × 2) from score
- End when all 20 rounds complete or score drops to 0 or below

**Shanghai**
- Each round has a number (1–7 in standard variant)
- Score points only on the round's target number (single = 1×, double = 2×, triple = 3×)
- Special: hitting single, double, AND triple of the round number in one turn = "Shanghai" = instant win
- Win: highest score after all rounds, or Shanghai

**170 Checkout Practice**
- Presents random / cycling checkouts from the standard 170-checkout table
- Player attempts the checkout in 2–3 darts
- Tracks: attempts, successes, checkout percentage per finish
- No win/lose — drill ends when player exits

### Shared Practice Board UI
- **Layout:**
  - Header: mode name, progress indicator (e.g., "Number: 7 / 20")
  - Large target display: current target number or double/triple (e.g., "D7")
  - Hit rate % or running score beneath target
  - Visual dartboard highlight: the current target segment glows
  - 3 input buttons: `S-{n}` / `D-{n}` / `T-{n}` (labels update per target)
  - MISS button
  - NEXT ROUND button (if turn is complete)
  - Undo last dart
- **Per-mode customisation:** score/progress display adapts (Around the Clock shows number reached, Bob's 27 shows current points, etc.)
- **`ActivePracticeNotifier`** (`AsyncNotifier`): generic over practice state; delegates to the appropriate engine

### `ProcessPracticeDartUseCase`
- Dispatches to correct engine based on game type in config
- Appends `DartThrown` events same as competitive modes

## Scope — Out
- Competitive X01 and Cricket boards (EPIC-005, EPIC-006)
- Statistics projections for practice modes (EPIC-008 extension)
- Multiplayer practice (all practice modes are single-player)

## Key User Stories
- As a player, I can practise Around the Clock to improve consistency across all numbers.
- As a player, I can practise Bob's 27 to improve my double-hitting under pressure.
- As a player, I can practise Shanghai to drill scoring on a single target number.
- As a player, the board always shows me the current target clearly so I know what to aim for.

## Technical Components
- `lib/features/game/domain/engines/around_the_clock_engine.dart`
- `lib/features/game/domain/engines/catch_40_engine.dart`
- `lib/features/game/domain/engines/bobs_27_engine.dart`
- `lib/features/game/domain/engines/shanghai_engine.dart`
- `lib/features/game/domain/engines/checkout_practice_engine.dart`
- `lib/features/game/domain/usecases/process_practice_dart_use_case.dart`
- `lib/features/game/presentation/pages/practice_board_page.dart`
- `lib/features/game/presentation/widgets/practice_target_display_widget.dart`
- `lib/features/game/presentation/widgets/practice_input_buttons_widget.dart`
- `lib/features/game/presentation/widgets/dartboard_highlight_widget.dart`
- `lib/features/game/presentation/providers/active_practice_provider.dart`
- `lib/features/game/presentation/state/active_practice_state.dart`
- `test/features/game/domain/engines/around_the_clock_engine_test.dart`
- `test/features/game/domain/engines/bobs_27_engine_test.dart`
- `test/features/game/domain/engines/shanghai_engine_test.dart`

## Dependencies
- EPIC-001 (persistence)
- EPIC-003 (engine interface pattern, event infrastructure)
- EPIC-004 (game setup flow routes to practice board)

## Spec References
- `docs/games/around-the-clock.md` — state transition tables for Around the Clock
- `docs/UI_SCREEN_FLOWS_V3_FINAL.md` — Around the Clock / practice board section
- `darts-game/` — plain-English rules for all practice variants
- `docs/GAME-EVENT-SPECIFICATIONS.md` — event types
