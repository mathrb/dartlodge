# SCR-005 — X01 Board Page

**Route:** `/game/x01/:gameId`
**File:** `lib/features/game/presentation/pages/x01_board_page.dart`

---

## Design Principles

- **P1 — Scores readable at arm's length:** Active player score uses the largest available type token; the scoreboard columns are always visible.
- **P2 — Input grid fills thumb zone:** The segment grid occupies the lower 60% of the screen, within natural thumb reach.
- **P3 — Active player, score, and dart indicators always visible:** The scoreboard and dart-indicator row are pinned above the grid; they never scroll away.
- **P4 — Broadcast scoreboard aesthetic:** Scoreboard column layout mirrors the visual language of professional darts televised scoring.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│ AppBar: "501"               │  ← title: starting score
│          "Leg 1 of 3"       │  ← subtitle: leg progress
│                        [⋮] │  ← trailing overflow menu
├─────────────────────────────┤
│ [60]  [T20]  [ ○ ]  [ ○ ]  │  ← dart indicator row
│  sum   d1     d2     d3     │
├─────────────────────────────┤
│ ┌────────┬────────┬────────┐│
│ │ [60]312│  501   │  441   ││  ← equal-width player columns
│ │ ALICE ▶│  BOB   │  CARL  ││    active marked with ▶ suffix
│ │ PPR54.3│  PPR — │  PPR — ││
│ └────────┴────────┴────────┘│
├─────────────────────────────┤
│ 💡 T20 · T18 · D8           │  ← checkout banner (≤170 only)
├─────────────────────────────┤
│ ┌──────────────────────────┐│
│ │ MISS  │  SB·25  │ DB·50  ││  ← row 0: 3 equal-width cells
│ ├── colorOutlineVariant ────┤│
│ │20│19│18│17│16│15│14│13│12│11│ ← row 1: singles 20→11
│ │10│ 9│ 8│ 7│ 6│ 5│ 4│ 3│ 2│ 1│ ← row 2: singles 10→1
│ ├── colorOutlineVariant ────┤│
│ │20│19│18│17│16│15│14│13│12│11│ ← row 3: doubles 20→11 (colorPrimaryContainer)
│ │10│ 9│ 8│ 7│ 6│ 5│ 4│ 3│ 2│ 1│ ← row 4: doubles 10→1  (colorPrimaryContainer)
│ │  ·· ·· ·· ·· ·· ·· ·· ·· ··│    2 dot indicators per cell
│ ├── colorOutlineVariant ────┤│
│ │20│19│18│17│16│15│14│13│12│11│ ← row 5: triples 20→11 (colorPrimary)
│ │10│ 9│ 8│ 7│ 6│ 5│ 4│ 3│ 2│ 1│ ← row 6: triples 10→1  (colorPrimary)
│ │ ··· ··· ··· ··· ··· ··· ···│    3 dot indicators per cell
│ └──────────────────────────┘│
├─────────────────────────────┤
│ [↩ Undo]        [NEXT ROUND]│  ← bottom action bar
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** No back button (full-screen game mode — `automaticallyImplyLeading: false`). Title line 1: starting score (e.g. "501"). Title line 2 (subtitle): leg indicator (e.g. "Leg 1 of 3"). Trailing overflow menu [⋮]: single option "End Game".
- **Dart indicator row:** Shows sum of current turn's darts on the left, then three dart slots (thrown darts shown as chips; empty slots shown as outline circles). Sits between AppBar and scoreboard.
- **Scoreboard:** N equal-width columns (one per player). Active player column has `colorActivePlayerBg` background and 4dp left border in `colorActivePlayer`. Score displayed prominently; player name below; PPR below name.
- **Checkout banner:** Rendered between scoreboard and segment grid. Visible only when active player score is ≤170. Collapses to zero height (no reserved whitespace) when hidden.
- **Segment grid:** The central input mechanism. 7 rows × 10 columns for singles/doubles/triples, plus a 3-cell row 0. Contained in a `ClipRRect` at `radiusMedium`. Full-width within `space4` (16dp) horizontal margin.
- **Bottom action bar:** `Undo` on the left, `NEXT ROUND` on the right. Wrapped in SafeArea.

---

## Typography

| Element | Token | Notes |
|---|---|---|
| AppBar title (starting score) | `textHeadingSmall` (DM Sans SemiBold 16sp) | `colorOnBackground` |
| AppBar subtitle (leg indicator) | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |
| Active player score | Scales by N players: N=1→2 use `textScoreActive` (Oswald Bold 80sp); N=3→4 use `textScoreMedium` (48sp); N=5→6 use `textScoreSmall` (36sp) | `colorPrimary` |
| Inactive player score | One scale step smaller than active; use same 4-tier mapping but one tier down | `colorInactiveScore` (#9CA3AF) |
| Round-sum prefix (before score) | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |
| Player name (ALL CAPS) | `textPlayerName` (DM Sans SemiBold 16sp, letter-spacing 1.5) | Active: `colorSecondary`; Inactive: `colorOnSurfaceVariant` |
| PPR value | `textBodySmall` | `colorOnSurfaceVariant`; show "—" until first complete turn |
| Dart indicator chip label (segment text) | `textBodyMedium` (DM Sans Regular 14sp) | `colorOnSurface` |
| Dart indicator round sum | `textHeadingSmall` (DM Sans SemiBold 16sp) | `colorPrimary` |
| Segment button number | `textSegmentButton` (DM Sans SemiBold 18sp) | Varies by row tier (see Colors) |
| Row 0 labels (MISS, SB·25, DB·50) | `textSegmentButton` (DM Sans SemiBold 18sp) | `colorOnSurface` |
| Checkout banner text | `textBodyMedium` (DM Sans Regular 14sp) | `colorOnBackground` |
| Checkout banner 💡 icon | — | `colorPrimary` |
| "NEXT ROUND" button | `textLabelLarge` (DM Sans Medium 14sp) | `colorOnPrimary` |
| "↩ Undo" button | `textLabelLarge` | `colorOnSurface`; disabled: 38% opacity |
| Active player ▶ suffix | `textPlayerName` | `colorSecondary` |

---

## Colors

| Element | Token |
|---|---|
| Full screen background | `colorBackground` |
| Active player scoreboard panel background | `colorActivePlayerBg` (#FFF5F5 light / #2A1515 dark) |
| Active player scoreboard panel left border | 4dp `colorActivePlayer` (= `colorPrimary`) |
| Active player score | `colorPrimary` |
| Inactive player scoreboard panel background | `colorSurface` |
| Inactive player score | `colorInactiveScore` (#9CA3AF) |
| Segment grid outer container | `colorSurface` background; `ClipRRect` at `radiusMedium` |
| Each cell: right border | 1dp `colorOutline` hairline |
| Each cell: bottom border | 1dp `colorOutline` hairline |
| Tier-boundary separator rows (between rows 2→3 and 4→5) | 1dp `colorOutlineVariant` |
| Row 0 + rows 1–2 (singles/MISS/Bull) background | `colorSurface` |
| Row 0 + rows 1–2 text | `colorOnSurface` |
| Rows 3–4 (doubles) background | `colorPrimaryContainer` |
| Rows 3–4 text | `colorOnPrimaryContainer` |
| Rows 3–4 dot indicators (2 dots) | `colorOnPrimaryContainer` |
| Rows 5–6 (triples) background | `colorPrimary` |
| Rows 5–6 text | `colorOnPrimary` |
| Rows 5–6 dot indicators (3 dots) | `colorOnPrimary` |
| Dart indicator chip (thrown) background | `colorSurface` |
| Dart indicator chip (thrown) border | 1dp `colorOutline` |
| Dart indicator empty slot | outline circle `colorOutline` |
| Checkout banner background | `colorSurfaceVariant` |
| Checkout banner left border | 2dp `colorPrimary` |
| "NEXT ROUND" (enabled) | `colorPrimary` filled |
| "NEXT ROUND" (disabled) | 38% opacity foreground, `colorSurfaceVariant` bg |
| Undo (disabled) | 38% opacity |
| Cell ripple | `colorOnSurface` at 12% opacity, clipped to cell |

---

## Interactions

**Segment grid cells:**
- **Row 0 (MISS, SB, DB):** 3 equal-width cells. Minimum height 48dp. Full-width of the grid. Ripple clipped to cell boundary.
- **Rows 1–6 (10-column grid):** Approximately 39dp wide on a 390dp-wide device. This is an accepted exception to the 48dp minimum tap-target guideline; the cells are packed flush and the interaction density is required for the game input. Minimum cell height: 48dp.
- **Cell press:** Ripple `colorOnSurface` at 12% opacity, clipped to the cell boundary. No scale transform.
- **Each cell tap:** Records the dart thrown (segment type + number). Updates the dart indicator row. Updates the active player's remaining score. If the turn ends (3 darts thrown or bust), updates the scoreboard.

**Undo button:**
- Removes the last thrown dart of the current turn.
- Disabled when no darts have been thrown in the current turn. Tooltip: "No darts to undo".
- Does not undo across turns.

**NEXT ROUND button:**
- Enabled only when all 3 darts have been registered for the current turn (`dartsThrownInTurn == 3`).
- When disabled, include Tooltip: "Throw all 3 darts first".
- Tapping advances the turn to the next player.

**Overflow menu [⋮]:**
- Single option: "End Game".
- Tapping shows confirmation dialog:
  - Title: "End Game?"
  - Body: "The current game will be marked as abandoned."
  - Cancel: TextButton `colorOnBackground`
  - Confirm: FilledButton `colorError`
  - Dialog width: `min(screenWidth - 48dp, 320dp)`, corner radius `radiusMedium`.

**Checkout banner:**
- Not tappable — display only.

---

## Edge Cases

**Checkout banner:**
- Visible when active player's remaining score is ≤ 170 and ≥ 2.
- Hidden (collapses to zero height) when score > 170 or score equals 1 (no valid double finish for 1).
- No animation on show/hide — instant collapse.
- Checkout route is a suggestion string only (e.g. "T20 · T18 · D8"). Implementation of checkout route calculation is a separate concern.

**Player count scaling:**
- N=1: single full-width column; score at 80sp.
- N=2: 2 equal columns; score at 80sp each.
- N=3–4: 3–4 equal columns; score at 48sp.
- N=5–6: 5–6 equal columns; score at 36sp.
- Score text must never wrap or truncate. Container width must accommodate "501" at the active score size.

**Bust:**
- Snackbar appears at the bottom of the screen. Background: `colorErrorContainer`. Text: "BUST" in `textHeadingSmall` in `colorOnErrorContainer`. Auto-dismisses after 2 seconds.
- Active player panel border flashes `colorError`: 300ms visible → 500ms normal → 300ms visible. Then returns to normal state.
- Turn advances automatically after bust (no user action needed).

**Win:**
- Full-screen banner slides up from the bottom.
- Winner name: `textDisplayLarge` (32sp DM Sans SemiBold), `colorWin` (#2E7D32).
- Two action buttons: "Post-Game Summary" (FilledButton `colorPrimary`) and "Play Again" (outlined `colorPrimary`).
- Banner background: `colorWinContainer` (#E8F5E9 light / #1B3A1C dark).

**Loading:**
- Centered `CircularProgressIndicator` in `colorPrimary` while game data loads.

**Error:**
- Centered `error_outline` icon 48dp + error message + "Retry" TextButton `colorPrimary`.

---

## Special Notes

**Segment grid construction (contiguous tile spec):**
- The grid's outer container is a `ClipRRect` with `radiusMedium` (12dp). This clips all children.
- Each individual cell has `radiusNone` (0dp) corners — the rounded appearance comes from the outer clip only.
- Each cell draws only its **right** and **bottom** 1dp `colorOutline` hairline border. The leftmost column in each row draws no left border. The top row draws no top border. This creates a seamless grid appearance.
- Tier-boundary separators (the visual gap between rows 2→3 and between rows 4→5) use `colorOutlineVariant` (slightly lighter than `colorOutline`) and are 1dp tall.

**Dot indicators:**
- Double rows (3–4): 2 dots per cell, 4dp diameter each, placed below the number, centered horizontally in the cell.
- Triple rows (5–6): 3 dots per cell, 4dp diameter each, placed below the number.
- No text multiplier labels ("DBL", "TRP") — dots only.

**Semantic accessibility labels (for screen readers):**
- Single segment: "Single [N]" (e.g. "Single 20")
- Double segment: "Double [N]" (e.g. "Double 20")
- Triple segment: "Triple [N]" (e.g. "Triple 20")
- Row 0 MISS: "Miss"
- Row 0 SB: "Single Bull, 25 points"
- Row 0 DB: "Double Bull, 50 points"

**Score animation:**
- Active player score: counter roll-down animation, 250ms linear, on score change.
- Inactive player scores: update instantly (no animation).
- Respect `MediaQuery.disableAnimations` — collapse all transitions to instant when active.

**Nav bar:** Hidden on this screen (full-screen game mode).

**Row 0 labels:** MISS has no point value label. SB shows "SB·25". DB shows "DB·50".
