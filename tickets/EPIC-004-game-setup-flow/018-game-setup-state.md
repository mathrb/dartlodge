# TICKET-018: GameSetupState Freezed Union

**Status:** Todo
**Epic:** EPIC-004 — Game Setup Flow

---

## Description

Define the `GameSetupState` freezed union that drives the multi-step game setup wizard. The state discriminates on the current wizard step via variant constructors rather than a step enum, making exhaustive handling compile-safe. This is the foundational state type; all other EPIC-004 tickets depend on it.

---

## Acceptance Criteria

- [ ] `lib/features/game/presentation/state/game_setup_state.dart` exists and is `@freezed`
- [ ] Five variant constructors:
  - `selectingType()` — initial state; no game type chosen yet
  - `configuringGame({ required GameType gameType, required GameConfig config })` — variant chosen, config form open
  - `selectingPlayers({ required GameType gameType, required GameConfig config, required List<String> selectedPlayerIds })` — player list step
  - `formingTeams({ required GameType gameType, required GameConfig config, required List<String> selectedPlayerIds })` — team assignment step (UI not built this epic; variant included to avoid future breaking change)
  - `ready({ required GameType gameType, required GameConfig config, required List<String> selectedPlayerIds })` — all steps satisfied; notifier may call `CreateGameUseCase`
- [ ] `factory GameSetupState.initial()` returns `GameSetupState.selectingType()`
- [ ] No imports of `package:flutter`, `package:sqflite`, `package:drift`, or `package:dio` — pure Dart domain/presentation only
- [ ] Code generation (`build_runner`) produces `.freezed.dart` without errors
- [ ] `GameConfig` is imported from `lib/features/game/domain/entities/` (not redefined here)
- [ ] `GameType` is imported from `lib/features/game/domain/entities/`

---

## Files

- `lib/features/game/presentation/state/game_setup_state.dart` — **to create**
- `lib/features/game/presentation/state/game_setup_state.freezed.dart` — generated

---

## Implementation Notes

- Use `@freezed` with `implements` pattern — do not use `@unfreezed`.
- Each variant is a separate `factory` constructor. The consuming widget or notifier uses `.map` / `.when` / `.maybeWhen` to exhaustively handle steps.
- No `validationErrors` map on the state — validation lives in the notifier's `canStart` getter and surfaces as a SnackBar on the player selection page.
- No `isLoading` flag — the async transition that actually starts the game belongs in `ActiveGameNotifier` (EPIC-005). `GameSetupNotifier` is synchronous.
- `formingTeams` is intentionally included even though no UI drives it in this epic. Removing a freezed variant later requires regeneration and is a breaking change across all exhaustive `.map` call sites.
- `selectedPlayerIds` is `List<String>` (UUIDs), not `List<Player>` — the notifier resolves full entities when needed.
- Spec references: `docs/STATE_MANAGEMENT.md` §"State Classes", `docs/DATA.md` §"GameConfig fields".

---

