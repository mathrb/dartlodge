# TICKET-068: GameHistoryState + GameDetailState

**Epic:** EPIC-009 Game History
**Depends on:** none

---

## Goal

Define the two `@freezed` state classes for the game-history feature.

---

## Files to Create

- `lib/features/history/presentation/state/game_history_state.dart`
- `lib/features/history/presentation/state/game_detail_state.dart`

---

## Acceptance Criteria

### `GameHistoryState` (`@freezed`)

Fields:
- `games: List<Game>` — accumulated pages, newest-first
- `competitorsByGameId: Map<String, List<Competitor>>` — pre-fetched per page
- `isLoadingMore: bool` (`@Default(false)`) — true during incremental page load only
- `hasMore: bool` (`@Default(true)`) — false when last page returned < 20 results
- `filterGameType: GameType?` — null = all types
- `filterDateFrom: DateTime?`, `filterDateTo: DateTime?` — inclusive bounds
- `filterPlayerIds: List<String>` (`@Default([])`) — empty = no player filter
- `factory GameHistoryState.initial()` — delegates to `const GameHistoryState()`

### `GameDetailState` (`@freezed`)

Fields:
- `game: Game?`
- `competitors: List<Competitor>` (`@Default([])`)
- `events: List<GameEvent>` (`@Default([])`)
- `darts: List<DartThrow>` (`@Default([])`)
- `gameStats: GameStats?`
- `factory GameDetailState.initial()` — delegates to `const GameDetailState()`

---

## Notes

Run `dart run build_runner build --delete-conflicting-outputs` after creation.
