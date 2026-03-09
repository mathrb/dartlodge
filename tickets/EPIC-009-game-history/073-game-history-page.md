# TICKET-073: GameHistoryPage

**Epic:** EPIC-009 Game History
**Depends on:** TICKET-069, TICKET-071

---

## Goal

Replace the stub `HistoryPage` with a paginated, filterable game history list.

---

## Files to Update

- `lib/features/history/presentation/pages/history_page.dart` (replace stub)

---

## Acceptance Criteria

### `HistoryPage` (`ConsumerStatefulWidget`)

Needs a `ScrollController` for pagination. Disposes controller in `dispose()`.

**`_onScroll`:** Triggers `loadNextPage()` when within 200px of `maxScrollExtent`.

**Layout:** `Scaffold` → `asyncState.when(loading/error/data)`.

**Loading state:** centered `CircularProgressIndicator`.

**Error state:** error text + "Retry" `TextButton` calling `ref.invalidate(gameHistoryProvider)`.

**Data state:** `Column` with:
1. `HistoryFilterBarWidget` (reads filter values from state; callbacks to notifier)
2. `Expanded` → `RefreshIndicator` wrapping `ListView.builder`

**Empty state** (within data, `games.isEmpty`): `Icon(Icons.history)` + "No completed games yet".

**Pagination sentinel:** last item in `ListView.builder` is a `CircularProgressIndicator` row
when `state.isLoadingMore == true`.

**Navigation:** `context.push('/game/history/${game.gameId}')` on card tap.
