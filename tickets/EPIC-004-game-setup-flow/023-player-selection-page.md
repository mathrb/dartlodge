# TICKET-023: Player Selection Page + PlayerSelectionListWidget

**Status:** Todo
**Epic:** EPIC-004 — Game Setup Flow

---

## Description

Implement the player selection screen where players are added to the game. The current user is auto-selected and locked. All other registered players appear as a checkbox list. The page also hosts the START GAME button and a quick-link to add a new player.

---

## Acceptance Criteria

- [ ] `lib/features/game/presentation/pages/player_selection_page.dart` created as `ConsumerWidget`
- [ ] `lib/features/game/presentation/widgets/player_selection_list_widget.dart` created as `StatelessWidget`
- [ ] Page guards against invalid state: if `GameSetupNotifier` state is `selectingType`, redirect to `/` via `ref.listen`
- [ ] First row in the list: current user (locked player), rendered with a checked, non-interactive checkbox and a lock icon
- [ ] Remaining rows: all other players from `playerListProvider`, each with a togglable checkbox
  - Checked state driven by `selectedPlayerIds` in notifier state
  - Tapping calls `ref.read(gameSetupProvider.notifier).togglePlayer(playerId)`
- [ ] "＋ Add New Player" row at the bottom of the list: tapping calls `context.push('/players/add')`; on return the list refreshes via `playerListProvider` invalidation
- [ ] START GAME button:
  - Enabled only when `ref.watch(gameSetupProvider.notifier).canStart` is `true`
  - On tap: calls `await ref.read(gameSetupProvider.notifier).startGame()`
  - On non-null result (gameId): calls `context.go('/game/active/<type>/<gameId>')`
  - On null result (validation failure): shows a `SnackBar` with message "Could not start game. Please check your selection."
- [ ] AppBar trailing button: gear icon that opens the Game Config Panel (TICKET-024) via `showModalBottomSheet`
- [ ] `PlayerSelectionListWidget` is a `StatelessWidget` accepting: `List<Player> players`, `String? lockedPlayerId`, `Set<String> selectedIds`, `void Function(String) onToggle`, `VoidCallback onAddNew`

---

## Files

- `lib/features/game/presentation/pages/player_selection_page.dart` — **to create**
- `lib/features/game/presentation/widgets/player_selection_list_widget.dart` — **to create**
- `lib/app/app_router.dart` — **to update** (add player selection route)

---

## Implementation Notes

- Use `ref.listen(gameSetupProvider, (prev, next) { ... })` in `build()` (or in `initState` for `ConsumerStatefulWidget`) to detect `selectingType` state and trigger a redirect. The redirect must use `WidgetsBinding.instance.addPostFrameCallback` or the `redirect` hook in GoRouter to avoid calling `context.go` during build.
- `playerListProvider` is the async provider from EPIC-002. Use `AsyncValue.when` to show a loading spinner, error message, and the player list.
- The `lockedPlayerId` is not directly on `GameSetupState` — read it from `gameSetupProvider.notifier` via a separate getter or from the notifier's private field exposed as a read-only getter. Alternatively, include the locked ID in the `selectingPlayers` state variant as `lockedPlayerId`.
- `startGame()` is async; show a loading indicator on the button while the future is in flight (use a local `_isStarting` bool in a `ConsumerStatefulWidget` if needed).
- `context.go` (not `context.push`) after a successful start — the setup flow should not be in the back stack once the game board is open.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Player Selection Screen", `docs/STATE_MANAGEMENT.md` §"ref.listen usage".

---

