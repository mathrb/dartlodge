# SCR-010 — Practice: Catch-40

**Route:** `/game/practice/:gameId` (rendered when game type is `catch40`)
**File:** `lib/features/game/presentation/pages/practice_board_page.dart` (variant rendering within shared chrome)

---

## Design Principles

Inherits all principles from SCR-007 (Practice Board Shared Chrome). This ticket documents only the differences and additions specific to the Catch-40 practice type.

---

## What is Catch-40?

Catch-40 is a score-per-round drill. The player has 3 darts per round. The goal is to score 40 or more points in each round. No specific segment is targeted — any valid segment contributes to the round score. The drill runs for a fixed number of rounds (default 8). Each round is either "passed" (≥40 pts) or "failed" (<40 pts). The full 7-row segment grid is used for input.

---

## Differences from Shared Chrome (SCR-007)

### AppBar Subtitle

Format: `"Round {N} / {total}"`

Default total: 8

Example: `"Round 3 / 8"`

---

### Target Display

| Element | Content |
|---|---|
| Large label (`textScoreMedium`, 48sp, `colorPrimary`) | Static text "≥40 pts" — this is the per-round goal |
| Secondary metric line (`textBodyMedium`, `colorOnSurfaceVariant`) | `"Round {N}/{total} · scored: {roundScore}"` |

The `roundScore` in the secondary metric updates with each dart thrown in the current round, showing the running total of the current turn.

When `roundScore >= 40`, the secondary metric text changes to `colorPrimary` (success signal) while the round is still in progress (darts remain). This communicates "you've already passed this round".

When `roundScore < 40` after all 3 darts: text remains `colorOnSurfaceVariant` (neutral — will be evaluated at round end).

---

### Dartboard Highlight

No segment is highlighted. The entire dartboard is shown at normal (100%) opacity with no specific segment emphasized.

The `DartboardHighlightWidget` renders with all segments at full opacity, functioning as a visual reference only.

---

### Input Grid

The full 7-row segment grid is used — identical to the X01 Board (SCR-005). This replaces the 3-cell bar used by Around the Clock and Bob's 27.

```
┌─────────────────────────────────────┐
│   MISS   │   SB·25   │   DB·50      │  ← row 0: 3 equal cells
├─────────────────────────────────────┤
│ 20│19│18│17│16│15│14│13│12│11       │  ← row 1: singles 20→11
│ 10│ 9│ 8│ 7│ 6│ 5│ 4│ 3│ 2│ 1      │  ← row 2: singles 10→1
├─────────────────────────────────────┤  ← tier separator (colorOutlineVariant)
│ 20│19│18│17│16│15│14│13│12│11  ··   │  ← row 3: doubles (colorPrimaryContainer)
│ 10│ 9│ 8│ 7│ 6│ 5│ 4│ 3│ 2│ 1  ··  │  ← row 4: doubles (colorPrimaryContainer)
├─────────────────────────────────────┤  ← tier separator (colorOutlineVariant)
│ 20│19│18│17│16│15│14│13│12│11  ···  │  ← row 5: triples (colorPrimary)
│ 10│ 9│ 8│ 7│ 6│ 5│ 4│ 3│ 2│ 1  ··· │  ← row 6: triples (colorPrimary)
└─────────────────────────────────────┘
```

**All geometry, colors, hairlines, dots, and semantic labels are identical to SCR-005 (X01 Board).** Refer to SCR-005 for the full contiguous tile spec:
- Outer container: `ClipRRect` at `radiusMedium`, full-width within `space4` (16dp) horizontal margin
- Cells: `radiusNone`; right and bottom 1dp `colorOutline` hairline only
- Tier-boundary separators: 1dp `colorOutlineVariant`
- Row 0: `colorSurface` bg; rows 1–2: `colorSurface`; rows 3–4: `colorPrimaryContainer` + 2-dot indicators; rows 5–6: `colorPrimary` + 3-dot indicators
- Cell minimum height: 48dp; 10-column rows approximately 39dp wide (accepted exception)
- Semantic labels: "Single {N}", "Double {N}", "Triple {N}", "Miss", "Single Bull", "Double Bull"
- Cell ripple: `colorOnSurface` at 12% opacity, clipped to cell

---

### Bottom Bar Primary Action

**Label:** "NEXT ROUND"

**Enabled condition:** `dartsThrownInTurn == 3` (all 3 darts have been registered)

**When disabled:** Tooltip "Throw all 3 darts first"

Note: MISS button remains in the center position (shared chrome standard layout applies). The MISS button records a missed dart with 0 score for that dart.

---

### Completion Modal

After all rounds are completed (last round's NEXT ROUND is tapped), show a summary modal:

**Modal spec:**
- Title: "Drill Complete!" — `textHeadingSmall colorOnBackground`
- Body (multiline): — `textBodyMedium colorOnBackground`
  ```
  Rounds attempted: {total}
  Rounds passed (≥40): {passed}
  Total score across all rounds: {totalScore}
  ```
- Single action button: "NEW DRILL" (FilledButton, `colorPrimary`)
  - Navigates to Home (`/`)
- Dialog width: `min(screenWidth - 48dp, 320dp)`, `radiusMedium`
- Not dismissible by tapping outside

---

## Edge Cases

- **Round score exactly 40:** Counts as "passed". Secondary metric changes to `colorPrimary` after 3rd dart lands at exactly 40.
- **Round score = 0 (all MISS):** Round counted as "failed" (0 < 40). No special visual treatment beyond the standard secondary metric display.
- **First round:** AppBar subtitle shows "Round 1 / 8"; secondary metric shows "Round 1/8 · scored: 0" before any dart.
- **Last round completion:** When NEXT ROUND is tapped after round `{total}`, the completion modal appears immediately.

---

## Special Notes

- The input grid in this context is identical to X01's grid. The implementation should reuse the same grid widget — do not create a separate implementation.
- The dartboard widget still renders behind/above the grid (in the `DartboardHighlightWidget` zone) but without any segment highlighted. It serves as a visual backdrop and reference.
- `roundScore` in the secondary metric resets to 0 at the start of each new round (when NEXT ROUND is tapped).
- No "passed/failed" visual feedback is shown mid-grid or on cells — only the secondary metric color change communicates success within a round.
- After tapping NEXT ROUND, the secondary metric resets immediately before the next round starts.
- Page horizontal margin for the grid: `space4` (16dp) on both sides.
