# SCR-009 — Practice: Bob's 27

**Route:** `/game/practice/:gameId` (rendered when game type is `bobs27`)
**File:** `lib/features/game/presentation/pages/practice_board_page.dart` (variant rendering within shared chrome)

---

## Design Principles

Inherits all principles from SCR-007 (Practice Board Shared Chrome). This ticket documents only the differences and additions specific to the Bob's 27 practice type.

---

## What is Bob's 27?

Bob's 27 is a doubles-focused practice drill. The player starts with a score of 27 and works through all doubles (D1 → D20) in order — one double per round, 3 darts per round. Hitting the target double adds points to the running total; missing subtracts. Score can go negative, ending the drill early. Completing all 20 rounds finishes the drill.

**Scoring:**
- Hitting the target double D{N}: score += (N × 2) × (number of times hit in the round, max 3)
- Missing the target double in a round: score -= N × 2
  (A single or triple on the target number is a "miss" for scoring purposes)

---

## Differences from Shared Chrome (SCR-007)

### AppBar Subtitle

Format: `"Target: D{N}"`

Example: `"Target: D5"` when on the fifth double.

---

### Target Display

| Element | Content |
|---|---|
| Large label (`textScoreMedium`, 48sp, `colorPrimary`) | Current target double — e.g. "D5" |
| Secondary metric line (`textBodyMedium`, `colorOnSurfaceVariant`) | `"Score: {score}"` — starts at 27, can go negative |

When the score is negative, the secondary metric line text changes to `colorError` to signal danger. The label text remains "Score: {score}" — e.g. "Score: -9".

---

### Dartboard Highlight

- Only the **double ring** of the current target number is highlighted in `colorPrimary`.
- The **single and triple rings** of the current target number are shown at 40% opacity (slightly more visible than other numbers, but clearly not the target).
- All other number wedges and the bullseye area are shown at 35% opacity.

This highlight pattern communicates that only the double counts for scoring progress.

---

### Input Bar

A 3-cell contiguous horizontal bar spanning the full screen width, edge-to-edge (no horizontal margin). Sits in the `PracticeInputButtonsWidget` zone of the shared chrome.

```
┌──────────────────────────────────┐
│   S-{N}   │   D-{N}   │  T-{N}  │
└──────────────────────────────────┘
```

Where `{N}` is the current target number (e.g. "S-5", "D-5", "T-5").

**Geometry:**
- Parent container: `radiusNone` (flat bar, edge-to-edge)
- 3 equal-width cells, each a tap target
- Minimum cell height: 56dp
- Cells separated by 1dp `colorOutline` vertical hairlines

**Cell styling and opacity:**

| Cell | Background | Text color | Foreground opacity | Notes |
|---|---|---|---|---|
| S-{N} (single) | `colorSurface` | `colorOnSurface` | 38% | Non-scoring hit — dims to signal no points awarded |
| D-{N} (double) | `colorPrimaryContainer` | `colorOnPrimaryContainer` | 100% | Primary scoring target — fully visible |
| T-{N} (triple) | `colorPrimary` | `colorOnPrimary` | 38% | Non-scoring hit — dims to signal no points awarded |

- S-{N}: 2×4dp dot indicators at 38% opacity in `colorOnPrimaryContainer` — wait, this cell has `colorSurface` background and no dots (singles don't have dot indicators). **No dot indicators on the S cell.**
- D-{N}: 2×4dp dot indicators below number in `colorOnPrimaryContainer`.
- T-{N}: 3×4dp dot indicators below number in `colorOnPrimary`, at 38% opacity.

Background color on all cells remains at **full opacity** (100%). Only the foreground text and dots are dimmed for S and T cells.

**Cell label typography:** `textSegmentButton` (DM Sans SemiBold 18sp)

**All 3 cells remain tappable.** The game engine applies the scoring consequence:
- D-{N} hit: adds points per the scoring formula above.
- S-{N} or T-{N} hit: treated as a miss for that dart — penalty may apply at round end.

No special visual distinction is needed beyond the opacity dimming — the scoring outcome is reflected in the Score metric in the target display area.

---

### Bottom Bar Primary Action

**Label:** "NEXT ROUND"

**Enabled condition:** `dartsThrownInTurn == 3` (all 3 darts have been registered)

**When disabled:** Tooltip "Throw all 3 darts first"

Note: MISS button remains in the center position (shared chrome standard layout applies).

---

### Early-End Modal (Score Reaches Zero or Below)

When the running score drops to 0 or below after a round penalty is applied, the drill ends immediately. Show a blocking modal dialog:

**Modal spec:**
- Title: "Drill Ended" — `textHeadingSmall colorOnBackground`
- Body: "Your score went to zero. You reached round {N}. Final score: {score}" — `textBodyMedium colorOnBackground`
  - `{N}` = the round number at which the drill ended
  - `{score}` = final score (will be 0 or negative)
- Single action button: "NEW DRILL" (FilledButton, `colorPrimary`)
  - Navigates to Home (`/`)
- Dialog width: `min(screenWidth - 48dp, 320dp)`, `radiusMedium`
- Not dismissible by tapping outside

---

### Completion Modal (After Round 20)

When the player completes all 20 doubles (rounds D1 through D20), show a completion modal:

**Modal spec:**
- Title: "Drill Complete!" — `textHeadingSmall colorOnBackground`
- Body: "Final score: {score}" — `textBodyMedium colorOnBackground`
- Single action button: "NEW DRILL" (FilledButton, `colorPrimary`)
  - Navigates to Home (`/`)
- Dialog width: `min(screenWidth - 48dp, 320dp)`, `radiusMedium`
- Not dismissible by tapping outside

---

## Edge Cases

- **Score going negative:** The secondary metric line color changes to `colorError` when score is negative. No other UI changes.
- **Score at exactly 0:** Drill ends at end of round (after all 3 darts registered and penalty applied). Zero is treated as ≤ 0.
- **Target D20 completion:** If the player passes D20 without the score going to zero or below, show the completion modal.
- **MISS button:** Records a missed dart. The engine determines whether that dart counts as a "miss" for penalty calculation at round end.

---

## Special Notes

- The input bar is edge-to-edge (no `space4` horizontal margin).
- `radiusNone` on the input bar container, same as SCR-008.
- The 38% opacity on S and T cells communicates "these don't score toward your target" without making them unresponsive. The cells must remain tappable and register darts.
- Score can be displayed as a negative number (e.g. "Score: -4"). The secondary metric line must accommodate a leading "−" character without truncation.
- D-{N} dot indicators: 2 dots, each 4dp diameter, centered horizontally below the number, with `space1` (4dp) gap between number text and dots.
- T-{N} dot indicators: 3 dots at 38% opacity matching the foreground dimming.
