# EPIC-009: Game History

## Goal
Players can browse all their completed games, view match summaries, and drill into per-leg performance without leaving the app.

## Status
[ ] Not started

## Scope — In
- **History screen** (bottom nav tab, second position):
  - Paginated list of completed games sorted by date descending (newest first)
  - Game summary card per entry (see below)
  - Pull-to-refresh
  - Empty state when no completed games exist
  - Filter bar: game type chips, date range selector, player filter
- **Game summary card:**
  - Date + time (relative: "2 days ago" for recent, absolute for older)
  - Game type badge (X01/Cricket/Practice) + variant label (e.g., "501 Double Out")
  - Player avatars + names in finishing order
  - Winner highlighted
  - Final score / legs won summary (e.g., "3–1")
- **Game detail screen:**
  - Match-level header: same info as summary card
  - Per-competitor stats panel: 3-dart avg, checkout %, darts per leg (links to EPIC-008 projections)
  - Leg-by-leg breakdown table: leg number, winner, darts thrown, finishing score or "BUST"
  - Tap a leg row → per-leg throw list (each dart with segment + score progression)
- **`GameHistoryNotifier`** (`AsyncNotifier`, auto-dispose):
  - Loads paginated results via `getCompletedGames(cursor, pageSize)`
  - Holds filter state: game type, date range, player IDs
  - Appends next page on scroll-to-end
- **`GameHistoryState`** (freezed): list of game summaries, pagination cursor, filters, loading/error flags
- **`GameDetailNotifier`** (`AsyncNotifier`, auto-dispose): loads single game + all competitors + events for the leg breakdown

## Scope — Out
- Statistics projections (EPIC-008 — game detail screen links to stats but does not compute them independently)
- Deleting game history (not in scope — data is immutable once completed)
- Exporting history (future epic)

## Key User Stories
- As a player, I can see all my past games in a list so that I can review my history.
- As a player, I can filter by game type or date so that I can find a specific session quickly.
- As a player, I can tap a game to see the leg-by-leg breakdown so that I can analyse where I won or lost.
- As a player, I can see my per-game stats alongside the history so that each game result is meaningful.

## Technical Components
- `lib/features/game/presentation/pages/game_history_page.dart`
- `lib/features/game/presentation/pages/game_detail_page.dart`
- `lib/features/game/presentation/widgets/game_summary_card_widget.dart`
- `lib/features/game/presentation/widgets/leg_breakdown_table_widget.dart`
- `lib/features/game/presentation/widgets/history_filter_bar_widget.dart`
- `lib/features/game/presentation/providers/game_history_provider.dart`
- `lib/features/game/presentation/providers/game_detail_provider.dart`
- `lib/features/game/presentation/state/game_history_state.dart`
- `lib/features/game/presentation/state/game_detail_state.dart`

## Dependencies
- EPIC-001 (database, `getCompletedGames`, `watchCompletedGames`)
- EPIC-004 (bottom navigation bar already wired with History tab)
- EPIC-008 (stats shown in game detail come from statistics projections)

## Spec References
- `docs/UI_SCREEN_FLOWS_V3_FINAL.md` — game history screen and game detail layouts
- `docs/REPOSITORY_INTERFACES.md` — `GameRepository.getCompletedGames()`, `watchCompletedGames()`
- `docs/STATE_MANAGEMENT.md` — pagination pattern with `AsyncNotifier`
