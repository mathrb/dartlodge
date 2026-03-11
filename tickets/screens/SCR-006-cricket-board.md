# SCR-006 — Cricket Board Page

**Route:** `/game/cricket/:gameId`
**File:** `lib/features/game/presentation/pages/cricket_board_page.dart`

---

## Design Principles

- **P1 — Mark symbols readable at a glance:** Symbols (─, /, X, ⊗) are large and high-contrast; closed numbers shown in `colorCricketClosed` green.
- **P2 — Input cells in thumb zone, MISS accessible:** The unified table extends to the bottom; action buttons (MISS, UNDO, NEXT PLAYER) sit in a fixed footer row.
- **P3 — Mark state and scores always visible:** The table header row with scores and player names is pinned at the top of the table and never scrolls away.
- **P4 — Unified table aesthetic:** The scoreboard and input grid are a single cohesive table — no separate input area, no separate scoreboard panel.

---

## Layout Anatomy

```
AppBar: "Cricket"  subtitle: "Standard · Leg 1"     [⋮]
[Dart indicator:  T20  |  ○  |  ○ ]
─────────────────────────────────────────────────────
Header row (pinned):
│  64    │  32    │[MISS]│[UNDO]│
│ ALICE  │  BOB   │      │      │   score top, name below
─────────────────────────────────────────────────────
│  ⊗     │   X    │ [20] │ [D20]│ [T20] │  ← 20 row
│  /     │   ⊗    │ [19] │ [D19]│ [T19] │  ← 19 row
│  X     │   X    │ [18] │ [D18]│ [T18] │
│  ─     │   /    │ [17] │ [D17]│ [T17] │
│  ─     │   ─    │ [16] │ [D16]│ [T16] │
│  ─     │   ─    │ [15] │ [D15]│ [T15] │
│  ⊗     │   /    │[Bull]│[DBul]│  ≡   │  ← Bull row: no triple slot
─────────────────────────────────────────────────────
Footer row (pinned):
│                         │ [NEXT PLAYER] │
─────────────────────────────────────────────────────
```

**Zone descriptions:**

- **AppBar:** No back button (full-screen game mode — `automaticallyImplyLeading: false`). Title: "Cricket". Subtitle: variant name + leg indicator (e.g. "Standard · Leg 1"). Trailing overflow [⋮]: single option "End Game".
- **Dart indicator row:** Between AppBar and table. Shows up to 3 thrown darts as chips; empty slots as outline circles ○. No round sum label (Cricket doesn't aggregate a turn score the same way X01 does).
- **Header row (pinned):** One mark-state column per player, plus MISS and UNDO buttons on the right. Score at top of each player column; name below. The header is always visible.
- **Number rows:** 7 rows — one per cricket number (20, 19, 18, 17, 16, 15, Bull). Each row has: mark-state columns (one per player), then input cells (Single, Double, Triple).
- **Bull row exception:** No Triple cell for Bull. The Triple cell position is replaced by a blank disabled slot labeled "≡" (visual indicator that triple is not applicable).
- **Footer row (pinned):** NEXT PLAYER button on the right, spanning the input columns. Always visible.

---

## Mark Symbol Reference

| Marks held | Symbol | Color |
|---|---|---|
| 0 | ─ | `colorOnSurfaceVariant` |
| 1 | / | `colorOnBackground` |
| 2 | X | `colorOnBackground` (rendered bold/heavier) |
| 3 or more | ⊗ (circled X) | `colorCricketClosed` (#4CAF50) |

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title "Cricket" | `textHeadingSmall` (DM Sans SemiBold 16sp) | `colorOnBackground` |
| AppBar subtitle (variant · leg) | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |
| Dart indicator chip label (segment) | `textBodyMedium` (DM Sans Regular 14sp) | `colorOnSurface` |
| Player score in header | `textScoreSmall` (Oswald Bold 36sp) | `colorPrimary` |
| Player name in header (ALL CAPS) | `textLabelSmall` (DM Sans Medium 11sp) | `colorOnBackground` |
| Target label in number column (20, 19, … Bull) | `textSegmentButton` (DM Sans SemiBold 18sp) | `colorOnSurface` |
| Mark symbols (─, /, X, ⊗) | `textHeadingMedium` (DM Sans SemiBold 20sp) | see Mark Symbol Reference |
| Input button number (20, D20, T20) | `textSegmentButton` (DM Sans SemiBold 18sp) | varies by tier |
| "NEXT PLAYER" button | `textLabelLarge` (DM Sans Medium 14sp) | `colorOnPrimary` |
| "MISS" button | `textLabelLarge` | `colorOnSurface` |
| "UNDO" button | `textLabelLarge` | `colorOnSurface`; disabled: 38% opacity |
| Bull triple slot "≡" label | `textLabelSmall` | `colorOnSurfaceVariant` |

---

## Colors

| Element | Token |
|---|---|
| Full screen background | `colorBackground` |
| Table container | `colorSurface` |
| Cell dividers (right and bottom of each cell) | 1dp `colorOutline` hairline |
| Single input cell background | `colorSurface` |
| Single input cell text | `colorOnSurface` |
| Double input cell background | `colorPrimaryContainer` |
| Double input cell text | `colorOnPrimaryContainer` |
| Double input cell dot indicators (2 dots) | `colorOnPrimaryContainer` |
| Triple input cell background | `colorPrimary` |
| Triple input cell text | `colorOnPrimary` |
| Triple input cell dot indicators (3 dots) | `colorOnPrimary` |
| Bull triple slot (disabled) background | `colorSurfaceVariant` |
| Bull triple slot label | `colorOnSurfaceVariant` |
| Closed row (all players ≥3 marks): entire row | 38% opacity; `colorSurfaceVariant` tint over the row |
| Closed row input buttons | disabled (no tap); cursor `not-allowed` |
| Active player column header background | subtle `colorPrimary` at 10% opacity, or 4dp left border `colorPrimary` |
| Active player score | `colorPrimary` |
| Inactive player score | `colorInactiveScore` (#9CA3AF) |
| MISS button background | `colorSurface` |
| MISS button border | 1dp `colorOutline` |
| UNDO (enabled) | `colorOnSurface` |
| UNDO (disabled) | 38% opacity |
| NEXT PLAYER (enabled) | `colorPrimary` filled |
| NEXT PLAYER (disabled) | 38% opacity, `colorSurfaceVariant` |
| Dart indicator chip (thrown) | `colorSurface` bg, 1dp `colorOutline` border |
| Dart indicator empty slot | outline circle `colorOutline` |

---

## Interactions

**Input cells:**
- Minimum height: 56dp (the 3-cell bar per row — Single, Double, Triple — must collectively be at least 56dp tall; each individual cell height ≥ 56dp).
- Minimum width: approximately 48dp per cell.
- Ripple: `colorOnSurface` at 12% opacity, clipped to cell.
- Tap records a dart hit on that number at the tapped multiplier.

**MISS:**
- Always enabled during active play.
- Records a missed dart (no segment hit, but dart count increments).
- Minimum tap target: 48×48dp.

**UNDO:**
- Removes the last thrown dart of the current turn.
- Disabled when no darts thrown this turn. Tooltip: "No darts to undo".
- Minimum tap target: 48×48dp.

**NEXT PLAYER:**
- If `dartsThrownInTurn == 3`: immediately advances to next player.
- If `dartsThrownInTurn < 3`: shows confirmation dialog:
  - Title: "Advance turn?"
  - Body: "You've only thrown {N} dart(s). Advance anyway?"
  - Cancel: TextButton `colorOnBackground`
  - Confirm: FilledButton `colorPrimary`
  - Dialog width: `min(screenWidth - 48dp, 320dp)`, `radiusMedium`.

**Closed row:**
- Input cells have no `onTap` handler. Pointer shows `SystemMouseCursors.forbidden`.
- Include Tooltip on each disabled cell: "Number already closed".
- Mark-state cells still display symbols (⊗ for all players).

**Overflow [⋮]:**
- "End Game" → confirmation dialog (same pattern as X01).

**Bull row Triple slot:**
- No tap handler. No ripple. Displays "≡" label.
- Background `colorSurfaceVariant`.

---

## Edge Cases

**1-player game (solo/practice mode):**
- Single marks column, no score column (no opponent to display).
- NEXT PLAYER advances to next number target conceptually.

**Cut-throat variant:**
- Score goes up (surplus marks add points against opponents).
- Player score in header reflects their received penalty points.
- Winner is the player with the lowest score when all numbers are closed (or the last remaining player).
- Score column still shows each player's score in `textScoreSmall colorPrimary`.
- Label below score may change to reflect that lower is better: implementation decision.

**Win condition:**
- All numbers closed AND:
  - Standard: active player has the highest cumulative score (or tied for highest with the first-closer winning on tiebreak).
  - Cut-throat: player with the lowest score when all numbers are closed.
- Win banner: slides up from the bottom. Winner name in `textDisplayLarge colorWin`. Actions: "Post-Game Summary" and "Play Again".

**Loading:**
- Centered `CircularProgressIndicator` in `colorPrimary`.

**Error:**
- Centered `error_outline` 48dp + message + "Retry" TextButton `colorPrimary`.

---

## Special Notes

- **Nav bar:** Hidden on this screen (full-screen game mode).
- **FAB:** A floating action button (📊 icon) in the bottom-right corner of the screen opens the stats overlay. This preserves the existing stats overlay behavior. The FAB must not overlap the footer row buttons. Size: 56×56dp. Background: `colorSecondaryContainer`. Icon: `colorOnSecondaryContainer`.
- **Dart indicator row:** Sits between the AppBar and the table header. It is not part of the scrollable table.
- **Semantic accessibility labels:**
  - Single 20: "Single 20"
  - Double 20: "Double 20"
  - Triple 20: "Triple 20"
  - Single Bull: "Single Bull"
  - Double Bull: "Double Bull"
  - Disabled Bull Triple: "Triple Bull — not applicable in Cricket"
- **Active player indication:** The active player's column header uses a subtle background tint (`colorPrimary` at ~10% opacity) or a 4dp left border in `colorPrimary`. This must be clearly legible without color alone — the score and name are the primary identifiers.
- **Column layout:** Mark-state columns (one per player) appear to the left of the number/target label. Input cells (Single, Double, Triple) appear to the right. The number label column is centered between the two groups.
  - Layout per row: [PlayerA marks] [PlayerB marks] ... [Number label] [Single] [Double] [Triple]
  - Alternatively: [Number label] [PlayerA marks] [PlayerB marks] ... [Single] [Double] [Triple]
  - Implementation selects whichever layout is more readable; the spec above shows marks left, inputs right.
