# TICKET-019: GameSetupNotifier

**Status:** Todo
**Epic:** EPIC-004 — Game Setup Flow

---

## Description

Implement `GameSetupNotifier`, a synchronous `Notifier<GameSetupState>` that drives every transition in the game setup wizard. All transitions are in-memory; no I/O occurs until `startGame()` (TICKET-020). Pages observe the notifier via `ref.watch` and `ref.listen` — the notifier never calls navigation directly.

---

## Acceptance Criteria

- [ ] `lib/features/game/presentation/providers/game_setup_provider.dart` exists with `@riverpod` annotation
- [ ] `GameSetupNotifier extends Notifier<GameSetupState>` (sync `Notifier`, not `AsyncNotifier`)
- [ ] `build()` returns `GameSetupState.initial()` (`selectingType()`)
- [ ] Methods implemented:
  - `void selectGameType(GameType type)` — transitions `selectingType` → `configuringGame` with default `GameConfig` for that type
  - `void selectVariant(GameConfig config)` — updates `config` within `configuringGame`; also transitions from `selectingType` when called directly (variant pill tapped before explicit type selection)
  - `void togglePlayer(String playerId)` — adds or removes `playerId` from `selectedPlayerIds` in `selectingPlayers`; no-ops if state is not `selectingPlayers`
  - `void updateConfig(GameConfig config)` — replaces `config` in whichever variant holds it; no-ops if state is `selectingType`
  - `void reset()` — sets state back to `GameSetupState.initial()`
- [ ] `bool get canStart` — returns `true` when state is `selectingPlayers` and `selectedPlayerIds.isNotEmpty`
- [ ] Auto-selects the current user on transition to `selectingPlayers`: fetches `PlayerRepository.listPlayers()`, sorts by `lastActive` descending, locks the first `playerId` so it cannot be toggled off
- [ ] Locked player ID is tracked in private state within the notifier (not on `GameSetupState`)
- [ ] `@riverpod` provider is `autoDispose` (reset wizard state when user leaves the flow)
- [ ] No navigation calls inside the notifier — pages react to state changes via `ref.listen`

---

## Files

- `lib/features/game/presentation/providers/game_setup_provider.dart` — **to create**
- `lib/features/game/presentation/providers/game_setup_provider.g.dart` — generated

---

## Implementation Notes

- `selectVariant` should handle the case where state is still `selectingType` (user deep-linked directly to a variant pill page). Transition directly to `selectingPlayers` with the provided config, skipping `configuringGame`.
- Default `GameConfig` per type: X01 defaults to `{ startingScore: 501, inStrategy: straight, outStrategy: double, legsToWin: 1, startingPlayer: random }`. Cricket and Practice defaults are defined in `docs/DATA.md`.
- The locked `playerId` is stored as `String? _lockedPlayerId` on the notifier class, not on the freezed state, to avoid exposing it to the UI layer.
- `togglePlayer` must never remove `_lockedPlayerId` from `selectedPlayerIds` — silently no-op if called with the locked ID.
- `PlayerRepository` access: use `ref.read(playerRepositoryProvider)` inside `build()` to fetch available players asynchronously; store the resolved `_lockedPlayerId` before returning the initial state. Use a `FutureOr` pattern or call `ref.read` and await in an `_init()` helper called from `build()`.
- Spec references: `docs/STATE_MANAGEMENT.md` §"Notifier Patterns", `docs/DATA.md` §"GameConfig fields", `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Player Selection".

---

