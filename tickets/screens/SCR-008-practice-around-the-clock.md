# SCR-008 — Practice: Around the Clock

**Route:** `/game/practice/:gameId` (rendered when game type is `aroundTheClock`)
**File:** `lib/features/game/presentation/pages/practice_board_page.dart` (variant rendering within shared chrome)

---

## Design Principles

Inherits all principles from SCR-007 (Practice Board Shared Chrome). This ticket documents only the differences and additions specific to the Around the Clock practice type.

---

## Differences from Shared Chrome (SCR-007)

### AppBar Subtitle

Format: `"Number: {N} / 20"`

Example: `"Number: 7 / 20"`

---

### Target Display

| Element | Content |
|---|---|
| Large label (`textScoreMedium`, 48sp, `colorPrimary`) | Current target number as plain integer string — e.g. "7" |
| Secondary metric line (`textBodyMedium`, `colorOnSurfaceVariant`) | `"Number {N} of 20"` |

---

### Dartboard Highlight

**Standard variant:**
- The entire wedge for the current target number is highlighted in `colorPrimary`.
- "Entire wedge" means all three scoring rings for that number: single ring, double ring, and triple ring.
- All other wedges (all other numbers and the bullseye area) are shown at 35% opacity over `colorOnSurface`.

**Doubles-only variant:**
- Only the **double ring** of the current target number is highlighted in `colorPrimary`.
- The single and triple rings for the current target number are shown at 60% opacity (more visible than other numbers but less than the target double).
- All other wedges are shown at 35% opacity.

---

### Input Bar

A 3-cell contiguous horizontal bar spanning the full screen width, edge-to-edge (no horizontal margin). This bar sits in the `PracticeInputButtonsWidget` zone of the shared chrome.

```
┌──────────────────────────────────┐
│   S-{N}   │   D-{N}   │  T-{N}  │
└──────────────────────────────────┘
```

Where `{N}` is the current target number (e.g. "S-7", "D-7", "T-7").

**Geometry:**
- Parent container: `radiusNone` (flat bar, no rounded corners — visually distinct from the content above)
- 3 equal-width cells, each a tap target
- Minimum cell height: 56dp
- Cells separated by 1dp `colorOutline` vertical hairlines (right border of each cell, except last)
- The bar draws a 1dp `colorOutline` top border to separate it from the dartboard area

**Cell styling:**

| Cell | Background | Text color | Additional |
|---|---|---|---|
| S-{N} (single) | `colorSurface` | `colorOnSurface` | No dot indicators |
| D-{N} (double) | `colorPrimaryContainer` | `colorOnPrimaryContainer` | 2×4dp dot indicators below number in `colorOnPrimaryContainer` |
| T-{N} (triple) | `colorPrimary` | `colorOnPrimary` | 3×4dp dot indicators below number in `colorOnPrimary` |

**Cell label typography:** `textSegmentButton` (DM Sans SemiBold 18sp)

**Doublesonly variant — dimming:**
- In the `doublesOnly` variant, the S-{N} and T-{N} cells have their **foreground** content (text + dots) at 38% opacity. Background color remains at full opacity.
- S-{N} and T-{N} cells remain tappable. The game engine will reject non-double hits as not counting toward target progress, but the dart is still consumed (recorded as thrown). The visual dimming communicates "these won't advance your target" without disabling the input.

---

### Bottom Bar Primary Action

**Label:** "NEXT ROUND"

**Enabled condition:** `dartsThrownInTurn == 3` (all 3 darts have been registered for the current turn)

**When disabled:** Tooltip "Throw all 3 darts first"

Note: MISS button remains in the center position (shared chrome standard layout applies).

---

### Completion Modal

When the target number would advance past 20 (i.e. the player has successfully hit 20), show a completion modal dialog.

**Modal spec:**
- Title: "Drill Complete!" — `textHeadingSmall colorOnBackground`
- Body: "You completed Around the Clock in {T} turns ({D} darts)" — `textBodyMedium colorOnBackground`
  - `{T}` = total turns taken
  - `{D}` = total darts thrown across all turns
- Single action button: "NEW DRILL" (FilledButton, `colorPrimary`)
  - Tapping navigates to Home (`/`)
- Dialog width: `min(screenWidth - 48dp, 320dp)`, `radiusMedium`
- Not dismissible by tapping outside (modal is blocking)

---

## Edge Cases

- **Target display when at 20:** Large label shows "20"; secondary shows "Number 20 of 20". After hitting 20, the completion modal appears immediately.
- **Miss recorded on the current target:** Dart slot consumed; target number does not advance; input bar labels remain the same for remaining darts.
- **All 3 darts missed:** NEXT ROUND becomes enabled; player manually advances with the button.

---

## Special Notes

- The input bar is edge-to-edge (no `space4` horizontal margin). This is intentional to maximize tap area for the 3 cells.
- The `radiusNone` on the input bar container creates a visual break between the rounded content above (dartboard + target display) and the flat input strip.
- Dot indicators are centered below the number text within each cell, aligned horizontally. 4dp diameter circles. `space1` (4dp) gap between number text and dot row.
- The NEXT ROUND button is disabled until all 3 darts are registered. A partial turn cannot be manually advanced — the player must throw (or MISS) all 3 darts before proceeding. This is consistent with how X01 board handles turn advancement.
