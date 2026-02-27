# EPIC-004: Game Setup Flow

## Goal
Players can navigate from app open to first dart thrown in 3 taps via a consistent home → variant → players → config → start flow.

## Status
[ ] Not started — basic router scaffold exists

## Scope — In
- **Home screen:**
  - 2×2 grid of primary game cards: X01 (red), Cricket (teal), Practice (orange), Stats (purple)
  - Full-width feature/promo cards below the grid
  - Bottom navigation bar: Home, History, Stats, Settings tabs
- **Variant selection screen:** pill-shaped variant buttons per game type
  - X01: 301, 501, 701, 1001
  - Cricket: Standard, No Score, Cut Throat, Tactics
  - Practice: Around the Clock, Catch 40, Bob's 27, Shanghai, 170 Checkout
- **Player selection screen:**
  - Auto-selects the current user (last active player)
  - Checkbox list of all other players
  - Minimum 1 player; maximum configurable per game type
  - Quick-add new player inline (navigates to create player flow from EPIC-002)
- **Game configuration panel:**
  - Starting score (X01 only, locked to variant)
  - In-strategy selector: Straight / Double / Master
  - Out-strategy selector: Straight / Double / Master
  - Legs to win: 1–9 stepper
  - Starting player: random or manual pick
- **`app_router.dart`:** full GoRouter wiring for all screens in this epic and a clear named-route contract for EPIC-005/006/007 boards
- **`GameSetupNotifier`** (`AsyncNotifier`, auto-dispose): drives the multi-step config wizard
- **`GameSetupState`** (freezed): variant, selectedPlayerIds, config fields, step indicator, validation errors

## Scope — Out
- Active game boards (EPIC-005 X01, EPIC-006 Cricket, EPIC-007 Practice)
- Statistics dashboard (EPIC-008)
- Game history (EPIC-009)
- Settings screen beyond server URL placeholder

## Key User Stories
- As a player, I can open the app and see my game options immediately so that I waste no time getting to a game.
- As a player, I can pick a game variant and configure rules before the game starts so that everyone agrees on the format.
- As a player, I can select who is playing from a list so that the right players are tracked in this game.
- As a player, I can start a game in 3 taps (home → variant → start) with sensible defaults so that casual play is frictionless.

## Technical Components
- `lib/app/app_router.dart` — full GoRouter configuration
- `lib/features/game/presentation/pages/home_page.dart`
- `lib/features/game/presentation/pages/variant_selection_page.dart`
- `lib/features/game/presentation/pages/player_selection_page.dart`
- `lib/features/game/presentation/pages/game_config_page.dart`
- `lib/features/game/presentation/widgets/game_card_widget.dart`
- `lib/features/game/presentation/widgets/variant_pill_widget.dart`
- `lib/features/game/presentation/widgets/player_selection_list_widget.dart`
- `lib/features/game/presentation/widgets/config_stepper_widget.dart`
- `lib/features/game/presentation/providers/game_setup_provider.dart`
- `lib/features/game/presentation/state/game_setup_state.dart`

## Dependencies
- EPIC-001 (database + DI)
- EPIC-002 (player list available to select from)
- EPIC-003 (X01 engine, for `CreateGameUseCase`)

## Spec References
- `docs/UI_SCREEN_FLOWS_V3_FINAL.md` — home screen layout, variant selection, player selection, config panel
- `docs/STATE_MANAGEMENT.md` — `GameSetupNotifier` pattern, multi-step wizard state
- `docs/DATA.md` — game config fields and types
