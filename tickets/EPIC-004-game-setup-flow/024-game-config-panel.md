# TICKET-024: Game Config Panel + ConfigStepperWidget

**Status:** Todo
**Epic:** EPIC-004 — Game Setup Flow

---

## Description

Implement the game configuration bottom sheet and its stepper sub-widget. The panel is opened from the AppBar gear icon on the Player Selection Page and allows the user to adjust in/out strategy, legs, and starting player. Configuration changes are applied to the notifier only when the user confirms.

---

## Acceptance Criteria

- [ ] `lib/features/game/presentation/pages/game_config_page.dart` created — implemented as a `StatefulWidget` (local form state, no Riverpod inside the widget itself)
- [ ] `lib/features/game/presentation/widgets/config_stepper_widget.dart` created as `StatelessWidget`
- [ ] Panel is opened via `showModalBottomSheet(context: context, builder: (_) => GameConfigPanel(initialConfig: config))` from `PlayerSelectionPage`; caller passes the current `GameConfig` from notifier state
- [ ] **Copy-on-open pattern**: `GameConfigPanel.initState()` copies `initialConfig` into local `_draftConfig`; changes update `_draftConfig` only
- [ ] **Apply-on-close**: when the panel is dismissed (back swipe or close button), `Navigator.pop(context, _draftConfig)` returns the draft; the calling page calls `ref.read(gameSetupProvider.notifier).updateConfig(result)` only if `result != null`
- [ ] X01 config fields visible in the panel:
  - Starting Score: read-only `Text` label showing the variant's score (e.g. "501") — not editable here
  - In Strategy: `RadioListTile` group with options Straight, Double, Master
  - Out Strategy: `RadioListTile` group with options Straight, Double, Master
  - Legs to Win: `ConfigStepperWidget` (value: 1–9, default 1)
  - Starting Player: `DropdownButton<String>` listing selected player names; first entry is "Random"
- [ ] Cricket config shows only: Legs to Win stepper, Starting Player dropdown (no in/out strategy)
- [ ] Practice config shows only: Starting Player dropdown (no strategy, no legs)
- [ ] `ConfigStepperWidget` properties: `int value`, `int min`, `int max`, `VoidCallback onDecrement`, `VoidCallback onIncrement`
  - Row layout: decrement `IconButton` / value `Text` / increment `IconButton`
  - Decrement disabled (greyed, non-tappable) when `value == min`; increment disabled when `value == max`
- [ ] Panel has a visible close / "Apply" button in addition to swipe-to-dismiss

---

## Files

- `lib/features/game/presentation/pages/game_config_page.dart` — **to create**
- `lib/features/game/presentation/widgets/config_stepper_widget.dart` — **to create**

---

## Implementation Notes

- `GameConfigPanel` is a `StatefulWidget`, not a `ConsumerWidget`. It receives the initial config as a constructor parameter and returns the modified config via `Navigator.pop`. Keeping Riverpod out of the panel simplifies testing and avoids re-render coupling.
- The "Starting Player" dropdown lists player names from the `selectedPlayerIds` resolved in the calling page — pass them as `List<String> playerNames` to `GameConfigPanel`. The first option is always "Random" (mapped to `startingPlayer: null` in `GameConfig`).
- Fields hidden for non-X01 game types are simply not rendered — no `Visibility` widget with `visible: false`. Use a conditional `if (config.gameType == GameType.x01) ...` in the widget tree.
- `ConfigStepperWidget` uses `IconButton(onPressed: value > min ? onDecrement : null, ...)` for built-in Flutter disabled styling.
- The panel must not call `ref.read(gameSetupProvider.notifier).updateConfig(...)` directly — this would break the copy-on-open pattern by applying partial changes mid-editing. All application happens in the calling page after `showModalBottomSheet` returns.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Game Config Panel", `docs/DATA.md` §"GameConfig fields".

---

