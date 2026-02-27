# TICKET-007: Edit & Delete Player

**Status:** Done
**Epic:** EPIC-002 — Player Management

---

## Description

Allow a player's name to be edited inline or from the detail screen, and allow soft-deletion when the player has no game history. Hard deletion is blocked at the repository level by `ON DELETE RESTRICT`.

---

## Acceptance Criteria

- [ ] `EditPlayerNotifier` — `@riverpod` notifier exposing `setName()` and `submit(String playerId)`; reuses `PlayerFormState`
- [ ] `submit()` calls `updatePlayerName(playerId, name)` on the repository after the same validation rules as create (non-empty, ≤ 30 chars, unique)
- [ ] On success, pops the edit UI and invalidates `allPlayersProvider` and `playerProvider(playerId)`
- [ ] `deletePlayer(String playerId)` method on a `PlayerActionsNotifier` (or co-located on `EditPlayerNotifier`)
- [ ] `deletePlayer` calls `repository.deletePlayer(playerId)` (soft delete: sets `is_active = 0`)
- [ ] If the player has game history, the repository throws an appropriate `RepositoryException`; the UI shows a snackbar "Cannot delete a player with game history"
- [ ] Delete action requires a confirmation dialog before proceeding
- [ ] On successful delete, navigates back to the player list; list updates automatically

---

## Files

- `lib/features/players/presentation/providers/players_provider.dart` — update (add `EditPlayerNotifier`, `deletePlayer`)
- `lib/features/players/presentation/providers/players_provider.g.dart` — regenerate

---

## Implementation Notes

- The `PlayerRepository` interface does not currently have a `deletePlayer` method — it needs to be added to the interface and implemented in both sqflite and Drift repositories before this ticket can be completed.
- Soft delete sets `is_active = 0`. The Drift `watchAllPlayers()` stream already filters `is_active = true`, so deleted players disappear from the list automatically.
- If a player has any row in the `competitors` table, the soft-delete should still proceed (the competitors record remains for historical data). The hard-delete path (not exposed to the UI) would be blocked by `ON DELETE RESTRICT` at the SQLite level.
- Uniqueness check on edit must exclude the player being edited: `any((p) => p.playerId != playerId && p.name.toLowerCase() == name.toLowerCase())`.
- The confirmation dialog text: "Delete [name]? This cannot be undone." with "Cancel" and "Delete" (destructive style) actions.

---

## Implementation Notes (2026-02-27)

- Hard delete (not soft delete) was used — `DATABASE_DDL.md` has no `is_active` column.
- `deletePlayer` added to `PlayerRepository` interface and both SQLite and Drift implementations.
- History check: `SELECT COUNT(*) FROM competitor_players WHERE player_id = ?` before DELETE.
- `EditPlayerNotifier` added to `players_provider.dart`; generates as `editPlayerProvider`.
- `EditPlayerPage` created at `lib/features/players/presentation/pages/edit_player_page.dart`.
- `PlayerCardWidget` gains optional `onEdit`/`onDelete` callbacks; shows `PopupMenuButton` when provided.
- `PlayerListPage._PlayerList` converted to `ConsumerWidget` to support inline delete from list.
- Route `/players/:playerId/edit` added as sub-route of `:playerId` in `app_router.dart`.
- Contract tests: 3 `deletePlayer` cases added to both `player_repository_contract.dart` (standalone) and `player_repository_drift_contract_test.dart` (hybrid SQLite+Drift). All 22 hybrid tests pass.
