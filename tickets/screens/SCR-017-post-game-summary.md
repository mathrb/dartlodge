# SCR-017 — Post-Game Summary Page

**Route:** `/post-game/:gameId`
**File:** `lib/features/statistics/presentation/pages/post_game_summary_page.dart`

---

## Design Principles

- **P1 — Winner immediately clear:** The winner card is elevated, uses distinct colors, and is the first element below the AppBar. No ambiguity about who won.
- **P4 — Clean result cards, trophy emphasis:** Minimal decoration; the trophy and winner name carry the visual weight.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "Game Summary"     │  ← no back button
├─────────────────────────────┤
│                             │
│  ┌──────────────────────┐   │
│  │ 🏆  ALICE   [WINNER] │   │  ← winner card (colorWinContainer bg)
│  │                      │   │
│  │  Avg: 72.3  Darts:43 │   │  ← stat line
│  └──────────────────────┘   │
│                             │
│  ┌──────────────────────┐   │
│  │  BOB                 │   │  ← loser card
│  │  Avg: 54.1  Darts: — │   │
│  └──────────────────────┘   │
│                             │
│  (additional loser cards    │
│   if N > 2 players)         │
│                             │
├─────────────────────────────┤
│  [  PLAY AGAIN  ] [ DONE ]  │  ← bottom action row, SafeArea
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** No back button (`automaticallyImplyLeading: false`). Title: "Game Summary". No overflow menu.
- **Winner card:** Elevated card with distinctive styling. Full-width within `space4` (16dp) horizontal margin. Contains: trophy icon (🏆 or equivalent vector icon), player name, "WINNER" badge chip, and a stat line. This card has an animated entrance (see Special Notes).
- **Loser cards:** One card per non-winning player. Same horizontal margin. Simpler styling. Ordered by result (e.g. second place first if applicable, otherwise in turn order).
- **Bottom action row:** Two buttons side by side at the bottom, within SafeArea. "PLAY AGAIN" on the left (FilledButton), "DONE" on the right (outlined).

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title "Game Summary" | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| Winner name | `textDisplayLarge` (DM Sans SemiBold 32sp) | `colorWin` (#2E7D32) |
| "WINNER" badge chip text | `textLabelLarge` (DM Sans Medium 14sp) | `colorOnPrimary` |
| Winner stat label (Avg:, Darts:) | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |
| Winner stat value | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| Loser player name | `textHeadingLarge` (DM Sans SemiBold 24sp) | `colorOnBackground` |
| Loser stat label | `textBodySmall` | `colorOnSurfaceVariant` |
| Loser stat value | `textHeadingMedium` | `colorOnBackground` |
| "PLAY AGAIN" button | `textLabelLarge` | `colorOnPrimary` |
| "DONE" button | `textLabelLarge` | `colorPrimary` |

---

## Colors

| Element | Token |
|---|---|
| Screen background | `colorBackground` |
| Winner card background | `colorWinContainer` (#E8F5E9 light / #1B3A1C dark) |
| Winner card border | 2dp `colorWin` (#2E7D32) |
| Winner card corner radius | `radiusXLarge` (24dp) |
| 🏆 trophy icon color | `colorWin` (#2E7D32) |
| "WINNER" badge chip background | `colorWin` (#2E7D32) |
| "WINNER" badge chip text | `colorOnPrimary` |
| "WINNER" badge chip corner radius | `radiusFull` (pill) |
| Loser card background | `colorSurface` |
| Loser card border | none |
| Loser card corner radius | `radiusMedium` (12dp) |
| Loser card elevation | 1 |
| "PLAY AGAIN" background | `colorPrimary` filled |
| "DONE" border | `colorPrimary` |
| "DONE" text | `colorPrimary` |

---

## Interactions

- **AppBar:** No back gesture or back button. This page is an intentional navigation endpoint after a game — the user must explicitly choose "PLAY AGAIN" or "DONE".
- **"PLAY AGAIN":** Navigates to the Variant Selection page (`/game/variant-selection/:gameType`) with the same game type pre-selected, or to Player Selection with the same config pre-loaded. Implementation determines the exact behavior — the goal is to start a new game with minimal taps.
- **"DONE":** Navigates to Home (`/`).
- **Winner card:** Not tappable (display only).
- **Loser cards:** Not tappable (display only).
- **Stat line:** Static data display, no interaction.

---

## Winner Card Animated Entrance

When the page first renders, the winner card (including trophy icon and name) performs an entrance animation:

1. The trophy icon scales from 0 to 1.2 then settles to 1.0 (spring or eased overshoot).
2. The player name fades in and slides up slightly (8dp translate).
3. Duration: 300ms total.
4. Timing: both animations start simultaneously on page mount.

Respect `MediaQuery.disableAnimations`: if reduced motion is active, show winner card immediately at full size without any animation.

---

## Edge Cases

**Draw (no winner):**
- No winner card is shown.
- All player cards use the loser-card styling (colorSurface bg, radiusMedium).
- A centered message "Game Drawn" renders above the player cards in `textHeadingLarge colorOnBackground`.
- No trophy icon, no "WINNER" badge.

**Practice game (drill completion):**
- The "winner card" shows "Drill Complete!" instead of a player name.
- No trophy icon (use a checkmark ✓ icon, or a target/bullseye icon).
- No "WINNER" badge.
- Stat line shows "Darts: {N}" and any relevant drill-specific metric (e.g. "Success rate: 62%").

**Missing stats (Avg is "—"):**
- Avg stat value shows "—" (em dash).
- Darts stat value shows the actual dart count if available, or "—" if not.
- "—" is rendered in `textHeadingMedium` at normal size.

**N > 2 players:**
- Winner card always first.
- Remaining players in additional loser cards, ordered by result (second place first, if applicable), then turn order.
- All loser cards have equal styling.

**Solo game (1 player):**
- No "WINNER" badge (there's no opponent to beat).
- Winner card shows player name and "COMPLETED" text instead of "WINNER".

---

## Special Notes

- `automaticallyImplyLeading: false` on the AppBar — no back button, no back gesture handling.
- The animated entrance is for the winner card only. Loser cards appear instantly.
- Stats shown on the winner card (Avg, Darts):
  - **Avg:** 3-dart average (PPR) for this game only — not career average.
  - **Darts:** Total darts thrown by this player in this game.
- Stats shown on loser cards:
  - Same format: "Avg: {N}" and "Darts: {N}".
  - If the loser did not complete a leg (e.g. game ended during their turn), Darts still shows total darts thrown; Avg may show "—" if insufficient turns for meaningful calculation.
- Page horizontal margin: `space4` (16dp).
- Vertical gap between winner card and loser card(s): `space4` (16dp).
- Vertical gap between loser cards: `space3` (12dp).
- Bottom action row: `space4` (16dp) between the two buttons; full width split evenly (each button 50% minus half-gap).
- Bottom safe area: `space16` (64dp).
