# TICKET-020: CreateGameUseCase Provider & startGame()

**Status:** Todo
**Epic:** EPIC-004 — Game Setup Flow

---

## Description

Wire `CreateGameUseCase` into the Riverpod dependency graph and add the `startGame()` method to `GameSetupNotifier`. This is the only async operation in the setup flow: when the player taps START GAME, the notifier calls the use case and the page navigates to the active board on success.

---

## Acceptance Criteria

- [ ] `createGameUseCaseProvider` added to `lib/core/persistence/database_provider.dart` with `keepAlive: true`
- [ ] `createGameUseCaseProvider` depends on `gameRepositoryProvider`, `gameEventRepositoryProvider`, and `gameEngineFactoryProvider` (all already `keepAlive: true`)
- [ ] `GameSetupNotifier.startGame()` method added to `game_setup_provider.dart`:
  - Returns `Future<String?>` — the new `gameId` on success, `null` on validation failure
  - Calls `CreateGameUseCase.execute(gameConfig, competitors)` with correctly mapped arguments
  - Each selected `Player` in `selectedPlayerIds` becomes a solo `Competitor` with a fresh UUID (via `uuid` package)
  - `Competitor.order` matches position in `selectedPlayerIds` list (0-based)
  - Returns `null` and displays no error if `canStart` is `false` (guard)
  - Surfaces `ValidationException` as a returned `null` (page shows SnackBar)
  - Re-throws all other exceptions (unexpected errors propagate to the error boundary)
- [ ] Player selection page calls `startGame()` and navigates to `/game/active/<type>` only when the returned `gameId` is non-null
- [ ] No `Game` entity stored or returned on the provider — the `gameId` string is sufficient for navigation

---

## Files

- `lib/core/persistence/database_provider.dart` — **to update** (add `createGameUseCaseProvider`)
- `lib/features/game/presentation/providers/game_setup_provider.dart` — **to update** (add `startGame()`)

---

## Implementation Notes

- `createGameUseCaseProvider` is a `Provider<CreateGameUseCase>` (not async) — all its dependencies are already available synchronously from their own providers.
- `startGame()` must read state via `state.maybeMap(selectingPlayers: (s) => s, orElse: () => null)` to extract `selectedPlayerIds` and `config`. Return `null` immediately if not in `selectingPlayers` state.
- Competitor mapping: `Competitor(competitorId: uuid.v4(), gameId: <from result>, playerId: selectedPlayerId, order: index, type: CompetitorType.solo)`. The `gameId` is provided by `CreateGameUseCase` return value.
- `ValidationException` is defined in `lib/core/error/repository_exception.dart`. Catch it specifically; do not catch `RepositoryException` or `Exception`.
- The page is responsible for displaying the SnackBar — `startGame()` must not interact with the UI layer directly.
- Spec references: `docs/REPOSITORY_INTERFACES.md` §"CreateGameUseCase", `docs/DATA.md` §"Competitor entity", `docs/STATE_MANAGEMENT.md` §"Async operations in notifiers".

---

