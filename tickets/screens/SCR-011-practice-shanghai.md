# SCR-011 — Practice: Shanghai

**Route:** `/game/practice/:gameId` (rendered when game type is `shanghai`)
**File:** `lib/features/game/presentation/pages/practice_board_page.dart` (variant rendering within shared chrome)

---

## Design Principles

Inherits all principles from SCR-007 (Practice Board Shared Chrome). This ticket documents only the differences and additions specific to the Shanghai practice type.

---

## What is Shanghai?

Shanghai is a round-based scoring drill. There are a fixed number of rounds (default 7, corresponding to numbers 1–7). In each round, the player has 3 darts to hit the current round number in any combination (single, double, triple). Score accumulates across rounds. A "Shanghai" bonus occurs when the player hits single, double, and triple of the current number all within the same round (in any order). The drill runs for all configured rounds and then ends.

---

## Differences from Shared Chrome (SCR-007)

### AppBar Subtitle

Format: `"Round {N} / {total}"`

Default total: 7

Example: `"Round 3 / 7"`

---

### Target Display

| Element | Content |
|---|---|
| Large label (`textScoreMedium`, 48sp, `colorPrimary`) | Current round number as plain integer — e.g. "3" |
| Secondary metric line (`textBodyMedium`, `colorOnSurfaceVariant`) | `"Score: {score} | Round {N}/{total}"` |

`{score}` is the cumulative score across all completed rounds plus the current round's in-progress score.

---

### Dartboard Highlight

The entire wedge for the current round number is highlighted in `colorPrimary`.

"Entire wedge" means all three scoring rings for that number: single ring, double ring, and triple ring.

All other wedges (all other numbers and the bullseye area) are shown at 35% opacity over `colorOnSurface`.

This is the same behavior as the standard Around the Clock variant (SCR-008).

---

### Input Bar

A 3-cell contiguous horizontal bar spanning the full screen width, edge-to-edge (no horizontal margin). Sits in the `PracticeInputButtonsWidget` zone of the shared chrome.

```
┌──────────────────────────────────┐
│   S-{N}   │   D-{N}   │  T-{N}  │
└──────────────────────────────────┘
```

Where `{N}` is the current round number (e.g. "S-3", "D-3", "T-3").

**Geometry:**
- Parent container: `radiusNone` (flat bar, edge-to-edge)
- 3 equal-width cells, each a tap target
- Minimum cell height: 56dp
- Cells separated by 1dp `colorOutline` vertical hairlines

**Cell styling:**

| Cell | Background | Text color | Additional |
|---|---|---|---|
| S-{N} (single) | `colorSurface` | `colorOnSurface` | No dot indicators |
| D-{N} (double) | `colorPrimaryContainer` | `colorOnPrimaryContainer` | 2×4dp dot indicators below number |
| T-{N} (triple) | `colorPrimary` | `colorOnPrimary` | 3×4dp dot indicators below number |

All 3 cells are fully active at 100% opacity. No dimming applied — all three hit types contribute to score in Shanghai.

**Cell label typography:** `textSegmentButton` (DM Sans SemiBold 18sp)

**Dot indicators:** Same spec as other practice types:
- D-{N}: 2 dots, 4dp diameter, `colorOnPrimaryContainer`, centered below number with `space1` gap
- T-{N}: 3 dots, 4dp diameter, `colorOnPrimary`, centered below number with `space1` gap

---

### Shanghai Bonus Banner

When the player hits S-{N}, D-{N}, and T-{N} all within the same turn (any order), a "SHANGHAI!" celebratory banner is shown.

**Banner behavior:**
- Appears in the zone between the target display and the input bar (temporarily overlaying or pushing the input bar down).
- Animation:
  1. Scale-in: 300ms (scale from 0.5 to 1.0, eased)
  2. Visible: hold for 1 second
  3. Fade-out: 300ms
- After the fade-out, the banner collapses and the input bar returns to normal position.
- Respect `MediaQuery.disableAnimations`: if reduced motion is active, skip all animation steps; show banner for 1 second then hide immediately.

**Banner visual spec:**
- Text: "SHANGHAI!" — `textDisplayLarge` (DM Sans SemiBold 32sp), `colorPrimary`
- Background: `colorPrimaryContainer`, `radiusLarge` (16dp), horizontal padding `space6` (24dp), vertical padding `space3` (12dp)
- Centered horizontally within the screen

**When to detect Shanghai:**
- After each dart is recorded, check if the current turn now contains all three of: a single hit on the current number, a double hit on the current number, and a triple hit on the current number.
- Shanghai detection is independent of the order darts were thrown.
- MISS darts do not affect Shanghai detection (only actual segment hits count).

---

### Bottom Bar Primary Action

**Label:** "NEXT ROUND"

**Enabled condition:** `dartsThrownInTurn == 3` (all 3 darts have been registered)

**When disabled:** Tooltip "Throw all 3 darts first"

Note: MISS button remains in the center position (shared chrome standard layout applies).

---

### Completion Modal

After all rounds are completed (NEXT ROUND tapped after the final round), show a summary modal:

**Modal spec:**
- Title: "Drill Complete!" — `textHeadingSmall colorOnBackground`
- Body (multiline): — `textBodyMedium colorOnBackground`
  ```
  Total score: {score}
  Shanghai bonuses: {shanghaiCount}
  ```
  If `shanghaiCount > 0`, add: "🎯 Nice shooting!"
- Single action button: "NEW DRILL" (FilledButton, `colorPrimary`)
  - Navigates to Home (`/`)
- Dialog width: `min(screenWidth - 48dp, 320dp)`, `radiusMedium`
- Not dismissible by tapping outside

---

## Edge Cases

- **Shanghai on the 3rd dart:** The banner appears immediately after the 3rd dart is recorded. NEXT ROUND becomes enabled while the banner animates. Player can tap NEXT ROUND after banner completes (or can tap it during the banner animation if impatient — NEXT ROUND tap should be responsive regardless of banner state).
- **MISS recorded during a Shanghai-possible round:** The MISS consumes a dart slot but does not prevent Shanghai if the remaining 2 or 1 dart slots still contain S, D, and T. However, with a MISS consuming a slot, it becomes mathematically impossible to achieve Shanghai in that round (only 2 remaining dart slots cannot cover 3 different types). The banner simply won't appear.
- **Last round:** After tapping NEXT ROUND on the final round, the completion modal appears immediately.
- **Score display:** Score is cumulative. The secondary metric updates after each dart (showing live running total).

---

## Special Notes

- The input bar is edge-to-edge (no `space4` horizontal margin).
- `radiusNone` on the input bar container.
- The NEXT ROUND button prevents premature turn advancement — the player must register all 3 darts before moving on. This ensures the Shanghai detection window is complete.
- Only the current round's target number is in the input bar. The cells update when NEXT ROUND is tapped to reflect the new target number.
- Score formula: Single = N × 1, Double = N × 2, Triple = N × 3, where N is the round number. MISS = 0. Non-target segments register 0 score (the input bar only shows the current target — non-target hits are entered via MISS).
