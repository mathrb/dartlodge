# TICKET-005: Player List Screen

**Status:** Done
**Epic:** EPIC-002 — Player Management

---

## Description

Replace the current stub `PlayersScreen` with a fully functional player list screen. Shows all active players sorted by last-active date, handles empty state, and provides navigation to create and detail screens.

---

## Acceptance Criteria

- [ ] `PlayerListPage` is a `ConsumerWidget` at `lib/features/players/presentation/pages/player_list_page.dart`
- [ ] Watches `allPlayersProvider` and renders all three `AsyncValue` states: loading skeleton, error with retry, data
- [ ] Empty state: prompt text + prominent "Add your first player" button (no list shown)
- [ ] Non-empty state: scrollable list of `PlayerCardWidget` items, sorted by `lastActive DESC` (order comes from repository)
- [ ] AppBar title "Players", trailing `IconButton(Icons.add)` navigates to `/players/add`
- [ ] Tapping a `PlayerCardWidget` navigates to `/players/:id`
- [ ] `FAB` with `Icons.add` — same action as the AppBar add button
- [ ] The old `PlayersScreen` stub is replaced or re-wired to `PlayerListPage`

---

## Files

- `lib/features/players/presentation/pages/player_list_page.dart` — to create
- `lib/features/players/presentation/screens/players_screen.dart` — to update (replace stub body)

---

## Implementation Notes

- Use `ref.watch(allPlayersProvider)` with `.when(data:, loading:, error:)` — never `.value!`.
- Loading state: a `ListView` of shimmer/skeleton `PlayerCardWidget` placeholders (3–5 items) is preferred over a `CircularProgressIndicator` to avoid layout shift on load.
- Error state: show the error message and an "Retry" button that calls `ref.invalidate(allPlayersProvider)`.
- The list item tap passes `player.playerId` to the router as a path parameter: `context.push('/players/${player.playerId}')`.
- Page file is `player_list_page.dart`; the existing `players_screen.dart` can be updated to delegate to it (or replaced outright, updating the router import accordingly).

---

## Implementation

- Created `lib/features/players/presentation/widgets/player_card_widget.dart` — pure `StatelessWidget` with `CircleAvatar`, name, last-active label, and chevron.
- Created `lib/features/players/presentation/pages/player_list_page.dart` — `ConsumerWidget` with `allPlayersProvider.when(data/loading/error)`, `_EmptyState`, `_PlayerList`, `_SkeletonList`, and `_ErrorState` sub-widgets.
- Updated `lib/features/players/presentation/screens/players_screen.dart` — now delegates to `PlayerListPage`.
- Updated `lib/app/app_router.dart` — added `/players/:playerId` stub detail route.
