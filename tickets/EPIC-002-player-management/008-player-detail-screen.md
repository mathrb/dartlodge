# TICKET-008: Player Detail Screen

**Status:** Todo
**Epic:** EPIC-002 — Player Management

---

## Description

Implement the player detail screen showing basic profile info and a career statistics preview card. The stats card is a stub that links to EPIC-008; this ticket covers the scaffold, player info section, and the edit/delete entry points.

---

## Acceptance Criteria

- [ ] `PlayerDetailPage` is a `ConsumerWidget` at `lib/features/players/presentation/pages/player_detail_page.dart`
- [ ] Receives `playerId` as a constructor parameter (passed from the router path parameter)
- [ ] Watches `playerProvider(playerId)` and handles all three `AsyncValue` states
- [ ] Profile section shows: `PlayerAvatarWidget`, player name, member since (`createdAt` formatted), last active date
- [ ] Career stats preview card: placeholder/stub section with a "View full stats →" link (no-op or disabled until EPIC-008)
- [ ] AppBar trailing action: edit button (`Icons.edit`) navigates to the inline edit flow
- [ ] AppBar or bottom: delete button with destructive styling; triggers the confirmation dialog from TICKET-007
- [ ] If player is not found (`AsyncValue.error` with `PlayerNotFoundException`), shows an error screen with a back button

---

## Files

- `lib/features/players/presentation/pages/player_detail_page.dart` — to create

---

## Implementation Notes

- `playerProvider(playerId)` is a family provider — pass the exact `playerId` string from the route. The provider returns `AsyncValue<Player?>`; treat `null` as `PlayerNotFoundException` in the UI.
- Date formatting: use `intl` package `DateFormat.yMMMd()` for `createdAt` and `lastActive` display.
- The edit flow can be implemented as: (a) a separate `EditPlayerPage`, or (b) an inline editable `TextField` replacing the name text. Either is acceptable; document the approach chosen.
- Career stats preview card content (values like avg, checkout %) is out of scope for this ticket — render a `Card` with "Stats coming soon" placeholder text and the "View full stats →" link disabled or hidden.
- The page is reached via `/players/:id`; `state.pathParameters['id']` in GoRouter provides the `playerId`.
