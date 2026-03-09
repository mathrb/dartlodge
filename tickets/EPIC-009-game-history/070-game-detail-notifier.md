# TICKET-070: GameDetailNotifier

**Epic:** EPIC-009 Game History
**Depends on:** TICKET-068

---

## Goal

Implement the single-game detail Riverpod notifier (family, keyed by `gameId`).

---

## Files to Create

- `lib/features/history/presentation/providers/game_detail_provider.dart`

---

## Acceptance Criteria

### `GameDetailNotifier` (`@riverpod class`, family) → provider: `gameDetailProvider(gameId)`

**`build(String gameId)`:**

All five sources fetched in parallel via `Future.wait`:
1. `gameRepositoryProvider.getGame(gameId)` → `Game?`
2. `gameRepositoryProvider.getCompetitors(gameId)` → `List<Competitor>`
3. `gameEventRepositoryProvider.getEventsForGame(gameId)` → `List<GameEvent>`
4. `dartThrowRepositoryProvider.getDartsForGame(gameId)` → `List<DartThrow>`
5. `statisticsRepositoryProvider.getGameStats(gameId)` → `GameStats?`

Returns `null` when `game == null`.

Events sorted ascending by `localSequence`.
Darts sorted by `turnNumber`, then `dartNumber`.

Uses `ref.read()` (not `ref.watch()`) for all repos (one-time load).
