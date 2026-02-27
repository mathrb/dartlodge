# TICKET-006: Create Player Flow

**Status:** Todo
**Epic:** EPIC-002 — Player Management

---

## Description

Implement the create-player screen with name input and client-side + repository-side validation. Reachable from the player list via the add button or FAB, and from `/players/add` via GoRouter.

---

## Acceptance Criteria

- [ ] `CreatePlayerPage` is a `ConsumerStatefulWidget` at `lib/features/players/presentation/pages/create_player_page.dart`
- [ ] Name field: `TextField` with label "Name", autofocus, max length 30 characters enforced via `inputFormatters`
- [ ] Validation — non-empty: shows inline error "Name cannot be empty"
- [ ] Validation — max 30 chars: enforced by `LengthLimitingTextInputFormatter`; counter shown below field
- [ ] Validation — unique name: shows inline error "A player with this name already exists"
- [ ] Submit button reads "Create Player"; disabled while `isSubmitting == true`
- [ ] On success: pops the route; the player list updates automatically via `allPlayersProvider`
- [ ] On `DuplicatePlayerException`: sets `nameError` to the uniqueness message without crashing
- [ ] `CreatePlayerNotifier` is reset via `ref.invalidate(createPlayerNotifierProvider)` when the page is disposed

---

## Files

- `lib/features/players/presentation/pages/create_player_page.dart` — to create

---

## Implementation Notes

- Use `ref.listen(createPlayerNotifierProvider, (prev, next) { ... })` to react to submission completion and call `context.pop()`. Do not navigate inside the notifier.
- Autofocus the `TextField` on first build to reduce taps — the keyboard appears immediately on page push.
- The `TextEditingController` is owned by the page's `State` (not the notifier) and syncs to the notifier via `onChanged: (v) => ref.read(...notifier).setName(v)`.
- Validation order: check empty first, then length (covered by formatter, not needed again), then uniqueness. Uniqueness is only checked on submit (not on every keystroke).
- The `/players/add` GoRouter route maps to this page. The existing stub in the router uses `PlayersScreen(showAddDialog: true)` — replace with `CreatePlayerPage`.
