# SCR-007 — Practice Board Shared Chrome

**Route:** `/game/practice/:gameId`
**File:** `lib/features/game/presentation/pages/practice_board_page.dart`

---

## Design Principles

- **P1 — Current target readable at a glance:** The target label uses the largest available practice type token (`textScoreMedium`) and is always on screen.
- **P2 — MISS and primary action in the thumb zone:** Both are in the bottom bar, in fixed positions, reachable without repositioning hand.
- **P3 — Target and progress always visible:** The target display zone and AppBar subtitle are pinned; they never scroll.
- **P4 — Dartboard widget is the visual centerpiece:** The dartboard fills the available vertical space between the AppBar and the target display zone.

---

## Layout Anatomy

```
┌─────────────────────────────────┐
│ AppBar: "[Game Name]"        ←  │  ← title line 1: game name
│          "[progress subtitle]"  │  ← title line 2: varies per type
│                            [⋮] │  ← overflow menu
├─────────────────────────────────┤
│                                 │
│                                 │
│      DartboardHighlightWidget   │  ← Expanded widget, fills all remaining
│                                 │    vertical space between AppBar and
│      Current target segment     │    target display zone
│      highlighted in colorPrimary│
│                                 │
│                                 │
├─────────────────────────────────┤
│   PracticeTargetDisplayWidget   │
│   [Large target label — 48sp]   │  ← textScoreMedium (Oswald Bold)
│   [Secondary metric line]       │  ← textBodyMedium, colorOnSurfaceVariant
├─────────────────────────────────┤
│   PracticeInputButtonsWidget    │  ← replaced per practice type (SCR-008–012)
├─────────────────────────────────┤
│   BottomBar (SafeArea)          │
│   [↩ Undo]  [  MISS  ]  [ACTION]│  ← left: undo; center: miss; right: action
└─────────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** Back arrow navigates to Home. No confirmation required for abandoning practice. Title line 1: game name (human-readable, not enum key). Title line 2 (subtitle): progress indicator — format varies per practice type (see SCR-008–012). Trailing overflow [⋮]: "Reset Drill" or "End Drill" depending on game type.
- **DartboardHighlightWidget:** Fills all remaining vertical space using an `Expanded` widget. Renders a stylized dartboard image or vector diagram. The current target segment/wedge is highlighted in `colorPrimary`. All other segments at 35% opacity over `colorOnSurface`. The widget takes up as much height as available without scrolling.
- **PracticeTargetDisplayWidget:** Fixed-height zone below the dartboard. Large target label (48sp) and a secondary informational line below it.
- **PracticeInputButtonsWidget:** A swappable zone between the target display and the bottom bar. Its exact contents are defined per practice type in SCR-008–012. This zone may be a 3-cell bar, a full 7-row segment grid, or empty.
- **Bottom bar:** Three elements in a horizontal row inside SafeArea:
  - Left: Undo button (TextButton or icon button)
  - Center: MISS button (OutlinedButton)
  - Right: Primary action button (FilledButton) — label and enabled state vary per type

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title line 1 (game name) | `textHeadingSmall` (DM Sans SemiBold 16sp) | `colorOnBackground` |
| AppBar title line 2 (progress subtitle) | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |
| Target label (large) | `textScoreMedium` (Oswald Bold 48sp) | `colorPrimary` |
| Secondary metric line | `textBodyMedium` (DM Sans Regular 14sp) | `colorOnSurfaceVariant` |
| Bottom bar primary action label | `textLabelLarge` (DM Sans Medium 14sp) | `colorOnPrimary` |
| MISS button label | `textLabelLarge` | `colorOnSurface` |
| Undo button label | `textLabelLarge` | `colorOnSurface`; disabled: 38% opacity |

---

## Colors

| Element | Token |
|---|---|
| Screen background | `colorBackground` |
| DartboardHighlightWidget highlighted segment | `colorPrimary` |
| DartboardHighlightWidget non-highlighted segments | `colorOnSurface` at 35% opacity |
| DartboardHighlightWidget background | `colorBackground` |
| PracticeTargetDisplayWidget background | `colorBackground` (no card) |
| Bottom bar background | `colorSurface` with top 1dp `colorOutline` hairline separator |
| Bottom bar primary action (enabled) | `colorPrimary` filled |
| Bottom bar primary action (disabled) | 38% opacity, `colorSurfaceVariant` |
| MISS button background | `colorSurface` |
| MISS button border | 1dp `colorOutline` |
| Undo (enabled) | `colorOnSurface` |
| Undo (disabled) | 38% opacity |

---

## Interactions

- **Back button:** Navigates to Home. No "Abandon Drill?" confirmation dialog required for practice sessions.
- **Overflow [⋮]:**
  - For most practice types: "Reset Drill" (resets to initial state, no confirmation required) and "End Drill" (ends session and navigates to post-drill summary or Home).
  - "End Drill" may show a summary modal before navigating (see per-type specs).
- **MISS:** Always enabled during active play. Records a missed dart (dart slot consumed, no score, no target progress). Minimum tap target: 48×48dp.
- **Undo:** Removes the last thrown dart of the current turn. Disabled when no darts have been thrown this turn. Tooltip: "No darts to undo". Minimum tap target: 48×48dp.
- **Primary action button (right side):**
  - Label varies per practice type (e.g. "NEXT ROUND", "END DRILL").
  - Enabled condition varies per practice type.
  - See SCR-008–012 for exact label and enabled rule per type.
  - Minimum tap target: 48×48dp.

---

## Edge Cases

**Loading state:**
- Centered `CircularProgressIndicator` in `colorPrimary` while game data loads.
- The full-page loading state covers the DartboardHighlightWidget zone and the target display zone.

**Error state:**
- Centered `error_outline` icon 48dp in `colorOnSurfaceVariant`.
- Below icon: "Failed to load drill." in `textBodyLarge colorOnBackground`.
- Below that: "Retry" TextButton in `colorPrimary`.

---

## Special Notes

- **Nav bar:** Hidden on this screen (full-screen practice mode).
- **PracticeInputButtonsWidget zone:** This is a swappable, per-type component. The shared chrome renders the AppBar, dartboard, target display, and bottom bar. The input buttons zone between target display and bottom bar is provided by the specific practice-type variant. See SCR-008–012 for each variant's implementation.
- **DartboardHighlightWidget:** The specific segments highlighted within the dartboard widget depend on the active practice type and current target. The shared chrome is responsible for passing the current target to the widget; the widget handles the visual rendering. See individual type specs for which segments to highlight.
- **AppBar subtitle format:** The format string for the progress subtitle is defined per practice type. The shared chrome widget receives this as a parameter from the type-specific provider.
- **Bottom bar layout:** Use a `Row` with `MainAxisAlignment.spaceBetween`. All three buttons should have consistent minimum heights (48dp). The center MISS button should be visually centered. If a practice type has no MISS button (e.g. Checkout Practice — SCR-012), the center slot is left empty and the row is effectively left-Undo + right-Action.
- **SafeArea:** The bottom bar is wrapped in SafeArea to avoid overlap with system navigation gestures.
