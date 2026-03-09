# TICKET-071: GameSummaryCardWidget + HistoryFilterBarWidget

**Epic:** EPIC-009 Game History
**Depends on:** TICKET-068 (entities)

---

## Goal

Implement the two reusable widgets for the game history list.

---

## Files to Create

- `lib/features/history/presentation/widgets/game_summary_card_widget.dart`
- `lib/features/history/presentation/widgets/history_filter_bar_widget.dart`

---

## Acceptance Criteria

### `GameSummaryCardWidget` (`StatelessWidget`)

Constructor: `{required Game game, required List<Competitor> competitors, required VoidCallback onTap, GameStats? gameStats}`

Layout (tappable `Card`):
- Game type badge (colour container) + variant label + relative/absolute date (right-aligned)
- Player names sorted winner-first (winner in bold + `Icons.emoji_events` amber icon)
- Score line `"N – M"` (legs won) when `gameStats` is non-null

Relative date logic (no external packages):
- Same day → "Today"
- 1 day ago → "Yesterday"
- ≤ 7 days → "N days ago"
- Older → "15 Jan 2026"

`_monthAbbr` is `const List<String>` with 12 abbreviated month names.

---

### `HistoryFilterBarWidget` (`StatelessWidget`)

Constructor: `{required GameType? selectedGameType, required DateTime? selectedDateFrom, required DateTime? selectedDateTo, required ValueChanged<GameType?> onGameTypeChanged, required void Function(DateTime?, DateTime?) onDateRangeChanged, required VoidCallback onClearFilters}`

Layout: horizontally-scrollable `Row`:
- `FilterChip` for "All" (selected when type is null)
- `FilterChip` for "X01"
- `FilterChip` for "Cricket"
- `TextButton.icon` with `Icons.date_range` to pick date range (calls private `_pickDateRange(BuildContext)`)
- Clear `TextButton.icon` visible only when any filter is active

`_pickDateRange` uses `showDateRangePicker` and calls `onDateRangeChanged` with the result.
