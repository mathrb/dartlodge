# TICKET-074: GameDetailPage + Router Wiring

**Epic:** EPIC-009 Game History
**Depends on:** TICKET-070, TICKET-071, TICKET-072

---

## Goal

Implement the drill-down game detail page and wire both history routes into the app router.

---

## Files to Create

- `lib/features/history/presentation/pages/game_detail_page.dart`

## Files to Update

- `lib/app/app_router.dart` — 2 changes (builder function + route entry)

---

## Acceptance Criteria

### `GameDetailPage` (`ConsumerWidget`)

Constructor: `{required String gameId, super.key}`

Watches `gameDetailProvider(gameId)`. Handles all `AsyncValue` states:
- `loading`: centered `CircularProgressIndicator`
- `error`: centered error text
- `data` with `null`: centered "Game not found"
- `data` with value: `_buildBody`

**`_buildBody` layout** (`SingleChildScrollView` → `Column`):

1. **Match header `Card`:**
   - Game type badge (`primaryContainer` colour) + variant label
   - Date formatted as `"15 Jan 2026, 14:30"` using `_formatDateTime`
   - Competitors list sorted winner-first; winner has `Icons.emoji_events` (amber) + bold name

2. **Per-competitor stats** (when `gameStats != null`):
   - Section heading "Stats"
   - For each `CompetitorStats`: competitor name heading + `Wrap` of `StatsCardWidget`s:
     - "3-Dart Avg" / `threeDartAverage`
     - "Legs Won" / `legsWon`
     - "Total Darts" / `totalDartsThrown`

3. **Leg breakdown section heading** + `LegBreakdownTableWidget(events, darts, competitors)`

**Cross-feature import note:** `game_detail_page.dart` imports `StatsCardWidget` from the
`statistics` feature — acceptable because it is a pure display widget with no domain logic.

---

### Router Changes (`app_router.dart`)

1. Add import for `GameDetailPage`
2. Add builder function: `Widget _gameDetailPage(BuildContext _, GoRouterState s) => GameDetailPage(gameId: s.pathParameters['gameId']!);`
3. Add static helper to `GameRoutes`: `static String gameDetail(String id) => '/game/history/$id';`
4. Add outside-shell route: `GoRoute(path: '/game/history/:gameId', builder: _gameDetailPage)`
