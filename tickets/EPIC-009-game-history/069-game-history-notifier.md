# TICKET-069: GameHistoryNotifier

**Epic:** EPIC-009 Game History
**Depends on:** TICKET-068

---

## Goal

Implement the paginated, filterable game-history Riverpod notifier.

---

## Files to Create

- `lib/features/history/presentation/providers/game_history_provider.dart`

---

## Acceptance Criteria

### `GameHistoryNotifier` (`@riverpod class`) → provider: `gameHistoryProvider`

**Instance filter fields** (survive `ref.invalidateSelf()`):
- `_filterGameType: GameType?`
- `_filterDateFrom: DateTime?`
- `_filterDateTo: DateTime?`
- `_filterPlayerIds: List<String>`

**`build()`:**
1. Reads `gameRepositoryProvider`
2. Calls `getCompletedGames(limit: 20, offset: 0, filterByType: _filterGameType)`
3. Fetches competitors for all games in parallel via `Future.wait`
4. Applies date filter client-side via private `_applyDateFilter`
5. Returns `GameHistoryState` with filter values copied into state

**`loadNextPage()`:**
- Guards: `!hasMore || isLoadingMore` → no-op
- Sets `isLoadingMore: true` on current state
- Fetches next page at `offset: current.games.length`
- Appends to `state.games` and `competitorsByGameId`

**`refresh()`:** `ref.invalidateSelf(); await future`

**Filter methods:** each updates instance field then calls `ref.invalidateSelf()`:
- `setGameTypeFilter(GameType?)`
- `setDateRange(DateTime?, DateTime?)`
- `clearFilters()` — resets all four filter fields
