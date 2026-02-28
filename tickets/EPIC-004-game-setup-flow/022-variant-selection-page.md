# TICKET-022: Variant Selection Page + VariantPillWidget

**Status:** Todo
**Epic:** EPIC-004 — Game Setup Flow

---

## Description

Implement the variant selection screen that appears after the player selects a game type on the home screen. The screen displays pill-shaped variant buttons appropriate for the chosen `GameType`. Selecting a variant updates `GameSetupNotifier` and navigates to the player selection page.

---

## Acceptance Criteria

- [ ] `lib/features/game/presentation/pages/variant_selection_page.dart` created as `ConsumerWidget`
- [ ] `lib/features/game/presentation/widgets/variant_pill_widget.dart` created as `StatelessWidget`
- [ ] Page is parameterized by `GameType` via GoRouter path parameter (e.g. `/game/variant-selection/:type`) or via `GameSetupNotifier` state — either approach is acceptable as long as routing is consistent with TICKET-025
- [ ] Page title matches the selected game type: "X01", "Cricket", "Practice"
- [ ] Variants rendered per type:
  - X01: 301, 501 (visually emphasized as the recommended option), 701, 901, Custom (disabled, greyed out — not implemented this epic)
  - Cricket: Standard, No Score, Cut Throat, Tactics, Custom (disabled)
  - Practice: Around the Clock, Catch 40, Bob's 27, Shanghai, 170 Checkout
- [ ] `VariantPillWidget` properties: `String label`, `bool isSelected`, `bool isRecommended`, `bool isEnabled`, `VoidCallback? onTap`
  - Height: 72 logical pixels
  - Border radius: 36 logical pixels (fully rounded ends)
  - Full-width (fills horizontal space of parent)
  - Recommended variant renders with a distinct background tint or badge
  - Disabled variants render at reduced opacity (0.5) and ignore taps
- [ ] Tapping an enabled variant:
  1. Calls `ref.read(gameSetupProvider.notifier).selectVariant(config)` with the appropriate `GameConfig`
  2. Calls `context.push('/game/player-selection')`
- [ ] AppBar includes a back button that returns to home without modifying notifier state

---

## Files

- `lib/features/game/presentation/pages/variant_selection_page.dart` — **to create**
- `lib/features/game/presentation/widgets/variant_pill_widget.dart` — **to create**
- `lib/app/app_router.dart` — **to update** (add variant selection route)

---

## Implementation Notes

- `VariantPillWidget` is a `StatelessWidget`. Tap logic is owned by `VariantSelectionPage`, which passes a callback.
- Construct `GameConfig` for each variant inline on the page — do not put config defaults inside the widget.
- X01 `GameConfig` for 501: `{ startingScore: 501, inStrategy: straight, outStrategy: double, legsToWin: 1, startingPlayer: random }`. Same pattern for 301 (startingScore: 301), 701, 901.
- Cricket variant configs follow the `CricketVariant` enum in `docs/DATA.md`. Only `Standard` needs a non-stub `GameConfig` this epic; others can carry a placeholder config provided they navigate correctly.
- Practice variants: each maps to a `PracticeMode` enum value. The `GameConfig` for practice games may be minimal (`{ practiceMode: aroundTheClock, ... }`).
- "Custom" variants are `isEnabled: false` and do not call `selectVariant`.
- The "501" pill should visually stand out — use a border or filled background in the theme's primary color.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Variant Selection", `docs/DATA.md` §"GameConfig fields and valid values".

---

