# TICKET-002: PlayerRepository Interface

**Status:** Done
**Epic:** EPIC-002 — Player Management

---

## Description

Define the `PlayerRepository` abstract interface in the domain layer. Establishes the method contract that both sqflite and Drift implementations must satisfy, and exposes the reactive `watchAllPlayers()` stream needed by the provider layer.

---

## Acceptance Criteria

- [x] `PlayerRepository` is an `abstract interface class` in `lib/features/players/domain/repositories/`
- [x] `getAllPlayers()` — returns all active players ordered by `lastActive DESC`
- [x] `getPlayer(String playerId)` — returns `Player?`, null if not found
- [x] `createPlayer(Player player)` — inserts; throws `DuplicatePlayerException` on duplicate `playerId`
- [x] `updatePlayerName(String playerId, String name)` — updates name and `lastActive`; throws `PlayerNotFoundException` if absent
- [x] `touchPlayer(String playerId)` — updates `lastActive` to now; throws `PlayerNotFoundException` if absent
- [x] `watchAllPlayers()` — returns `Stream<List<Player>>` that emits on every change to the players table
- [x] No imports of Flutter, sqflite, or Drift — pure Dart domain file

---

## Files

- `lib/features/players/domain/repositories/player_repository.dart` — created

---

## Implementation Notes

- `getPlayer` returns `Player?` (nullable) rather than throwing `PlayerNotFoundException` — callers decide how to handle missing players. This differs from game/event repositories where missing data is always exceptional.
- `watchAllPlayers()` is the reactive entry point for `allPlayersProvider`. The sqflite implementation uses `Stream.fromFuture` (polling workaround); the Drift implementation uses Drift's built-in `watch()` which reacts to row changes automatically.
- `touchPlayer` is called by the game engine layer whenever a player completes a game, keeping `lastActive` accurate without requiring the UI to manage it.
- Concrete implementations for both backends are documented in EPIC-001 ticket 005.
