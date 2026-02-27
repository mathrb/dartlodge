# TICKET-010: Router Integration

**Status:** Todo
**Epic:** EPIC-002 — Player Management

---

## Description

Update `app_router.dart` to wire all player screens into the GoRouter tree with correct path parameters, replace the stub routes, and ensure deep-link navigation works across all player flows.

---

## Acceptance Criteria

- [ ] `/players` route renders `PlayerListPage` (replaces `PlayersScreen` stub)
- [ ] `/players/add` route renders `CreatePlayerPage` (replaces `PlayersScreen(showAddDialog: true)` stub)
- [ ] `/players/:id` route renders `PlayerDetailPage(playerId: state.pathParameters['id']!)`
- [ ] `/players/:id/edit` route renders the edit player UI (either `EditPlayerPage` or inline via `PlayerDetailPage` — must match TICKET-007 decision)
- [ ] All routes are nested under `/players` as sub-routes in GoRouter
- [ ] No route passes `BuildContext` to a notifier — navigation is triggered by the page reacting to provider state changes

---

## Files

- `lib/app/app_router.dart` — to update

---

## Implementation Notes

- Current router has `/players` and `/players/add` both pointing to `PlayersScreen` variants. Replace both builders.
- `/players/:id` must be a child route of `/players` in GoRouter's `routes` list to inherit the shell (if any) and allow back-navigation to the list.
- `state.pathParameters['id']` is non-null by definition when the route matches — use `!` safely here since GoRouter only matches if the segment is present.
- If `EditPlayerPage` is a separate screen (rather than inline edit on `PlayerDetailPage`), add `/players/:id/edit` as a child of `/players/:id`.
- The router should remain a plain `Provider` (not `@riverpod` generated) since it is app-scoped and does not depend on async data.
- Do not add redirect logic for auth guards in this ticket — that belongs to EPIC-010.
