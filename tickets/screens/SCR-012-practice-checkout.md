# SCR-012 — Practice: Checkout Practice

**Route:** `/game/practice/:gameId` (rendered when game type is `checkoutPractice`)
**File:** `lib/features/game/presentation/pages/practice_board_page.dart` (variant rendering within shared chrome)

---

## Design Principles

Inherits all principles from SCR-007 (Practice Board Shared Chrome). This ticket documents only the differences and additions specific to the Checkout Practice type.

---

## What is Checkout Practice?

Checkout Practice presents the player with a specific finish value (e.g. 170). The player has 3 darts to attempt the checkout route. The player enters each dart using the full segment grid. A suggested checkout route is displayed (e.g. T20 · T20 · DB for 170). The player may or may not follow the suggestion. If darts land in the correct sequence for any valid checkout route, the attempt is counted as a success. After 3 darts, the drill automatically advances to the next checkout value. The player explicitly ends the drill by tapping "END DRILL".

---

## Differences from Shared Chrome (SCR-007)

### AppBar Subtitle

Format: `"{successes}/{attempts} checkouts"`

Example: `"3/7 checkouts"`

Updates after each completed 3-dart attempt.

---

### Target Display

| Element | Content |
|---|---|
| Large label (`textScoreMedium`, 48sp, `colorPrimary`) | Current checkout finish value — e.g. "170" |
| Secondary metric line | Route progress display — shows suggested checkout route with dart slots filled in as darts land |

**Route progress display spec:**

The secondary metric zone shows the suggested checkout route with a slot for each dart (up to 3):

Before any dart in the attempt:
```
○  ·  ○  ·  ○
```

After first dart lands (e.g. T20):
```
T20  ·  ○  ·  ○
```

After second dart (e.g. T20):
```
T20  ·  T20  ·  ○
```

After third dart (e.g. DB):
```
T20  ·  T20  ·  DB
```

**Color coding per slot:**
- Unfilled slot `○`: `colorOutline`
- Correct hit (dart followed the suggested route): `colorPrimary`
- Wrong hit (dart deviated from the suggested route): `colorError`

Typography for each filled slot: `textBodyMedium` (DM Sans Regular 14sp) in the relevant color.
Typography for separators `·`: `textBodyMedium`, `colorOnSurfaceVariant`.
Typography for unfilled `○`: `textBodyMedium`, `colorOutline`.

---

### Dartboard Highlight

No segment is pre-highlighted. The full dartboard renders at normal opacity — the player decides their own route.

The `DartboardHighlightWidget` renders with all segments at full opacity.

---

### Input Grid

The full 7-row segment grid — identical to X01 Board (SCR-005). Refer to SCR-005 for the complete contiguous tile spec.

```
┌─────────────────────────────────────┐
│   MISS   │   SB·25   │   DB·50      │  ← row 0: 3 equal cells
├─────────────────────────────────────┤
│ 20│19│18│17│16│15│14│13│12│11       │  ← row 1: singles 20→11
│ 10│ 9│ 8│ 7│ 6│ 5│ 4│ 3│ 2│ 1      │  ← row 2: singles 10→1
├─────────────────────────────────────┤  ← tier separator (colorOutlineVariant)
│ 20│19│18│17│16│15│14│13│12│11  ··   │  ← row 3: doubles (colorPrimaryContainer + ·· dots)
│ 10│ 9│ 8│ 7│ 6│ 5│ 4│ 3│ 2│ 1  ··  │  ← row 4: doubles (colorPrimaryContainer + ·· dots)
├─────────────────────────────────────┤  ← tier separator (colorOutlineVariant)
│ 20│19│18│17│16│15│14│13│12│11  ···  │  ← row 5: triples (colorPrimary + ··· dots)
│ 10│ 9│ 8│ 7│ 6│ 5│ 4│ 3│ 2│ 1  ··· │  ← row 6: triples (colorPrimary + ··· dots)
└─────────────────────────────────────┘
```

All geometry, colors, hairlines, dots, and semantic labels identical to SCR-005. MISS is accessible via Row 0 of this grid — not through the bottom bar.

---

### Bottom Bar Layout (Differs from Shared Chrome)

This practice type has a **non-standard bottom bar**:

- **No MISS button in the center** — MISS is entered via Row 0 of the input grid.
- **Left:** Undo button (same as shared chrome — removes last thrown dart, disabled when none)
- **Center:** Empty (no element)
- **Right:** "END DRILL" (FilledButton, `colorPrimary`) — see below

```
[↩ Undo]            [END DRILL]
```

---

### Bottom Bar Primary Action

**Label:** "END DRILL"

**Enabled condition:** Always enabled once the drill has started (≥1 attempt completed). Before any attempt is completed, disabled with Tooltip "Complete at least one attempt first".

Note: There is no NEXT ROUND button for this type — turns advance automatically after 3 darts.

---

### Auto-Advance After 3 Darts

Unlike other practice types, Checkout Practice does **not** use a NEXT ROUND button. The turn (3-dart attempt) advances automatically after the 3rd dart is registered:

1. Third dart is recorded.
2. Route progress display shows all 3 slots filled.
3. Success or failure is determined.
4. AppBar subtitle updates (successes/attempts counts).
5. After a short delay (500ms — enough to let the player see the result), the large label animates to the next checkout value, route progress resets to "○ · ○ · ○", and the next attempt begins.
6. Respect `MediaQuery.disableAnimations`: if reduced motion active, skip the delay; advance immediately.

---

### Wrong Dart Behavior

When a dart lands on a segment that deviates from the suggested checkout route:

1. The dart slot in the route progress display fills with the segment label in `colorError`.
2. The `routeProgress` resets to 0 internally — the attempt is now counted as a failed attempt.
3. Remaining darts of the current turn are still entered normally — the player throws them out (no way to succeed with remaining darts, but they must be recorded).
4. The wrong-dart cells in the input grid do **not** show a special error tint or visual state — the route progress display in the target area is the sole feedback mechanism.

---

### Completion Modal

When the player taps "END DRILL":

**Modal spec:**
- Title: "Drill Complete!" — `textHeadingSmall colorOnBackground`
- Body: — `textBodyMedium colorOnBackground`
  ```
  Attempts: {N}
  Successes: {N}
  Success rate: {N}%
  ```
- Single action button: "NEW DRILL" (FilledButton, `colorPrimary`)
  - Navigates to Home (`/`)
- Dialog width: `min(screenWidth - 48dp, 320dp)`, `radiusMedium`
- Not dismissible by tapping outside

---

## Edge Cases

- **Checkout value has a 2-dart route (e.g. 40 → D20):** Route progress displays only 2 filled slots + 1 empty or a MISS placeholder. Implementation handles route-length variability.
- **Player completes checkout early (e.g. hits 2-dart route for a 2-dart finish):** Attempt is marked as success; auto-advance triggers after the 2nd dart (not waiting for 3rd). Remaining dart slot never fills.
- **0 attempts completed:** "END DRILL" is disabled with Tooltip. Player cannot end the drill before completing at least one 3-dart attempt.
- **AppBar subtitle on first attempt (0/0):** Show "0/0 checkouts" or "—" before first attempt completes. Implementation decision.

---

## Special Notes

- MISS is Row 0 of the grid. The bottom bar has no MISS button. This is the primary behavioral divergence from all other practice types. Make this unambiguous in the bottom bar by leaving the center slot empty (not even a placeholder label).
- The auto-advance delay (500ms) exists solely to give the player visual confirmation of their attempt result. It is not a loading delay.
- The Undo button can undo within the current 3-dart attempt only. It cannot undo across completed attempts.
- Route suggestions are displayed but not enforced in a blocking way — the player can attempt any route they choose. The suggestion is informational. Success is determined by whether the player's actual darts represent any valid checkout route for the target value (not necessarily the suggested one).
- Page horizontal margin for the grid: `space4` (16dp) on both sides.
- Grid spec is fully identical to SCR-005. Reuse the same widget.
