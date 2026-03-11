# SCR-019 — Game Detail Page

**Route:** `/game/history/:gameId`
**File:** `lib/features/history/presentation/pages/game_detail_page.dart`

---

## Design Principles

- **P1 — Result and key stats scannable:** The result header (winner, darts, date) is immediately visible at the top without scrolling.
- **P4 — Result header prominent:** The header area is distinct from the stat cards below through color and typography scale.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "X01 · 501"     ←  │
├─────────────────────────────┤
│  ┌─────────────────────────┐│
│  │ ALICE won               ││  ← winner name (textHeadingLarge, colorWin)
│  │ 43 darts · Mar 8, 2026  ││  ← metadata (textBodySmall, colorOnSurfaceVariant)
│  └─────────────────────────┘│
├─────────────────────────────┤
│  (Per-player section for ALICE:)
│  ┌──────────┐ ┌──────────┐  │
│  │  72.3    │ │  121     │  │  ← stat cards (equal width, 2-column)
│  │  Avg     │ │ High CO  │  │
│  └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐  │
│  │   2      │ │   43     │  │
│  │  Legs    │ │  Darts   │  │
│  └──────────┘ └──────────┘  │
├─────────────────────────────┤
│  (Per-player section for BOB:)
│  BOB                        │  ← section header for loser
│  ┌──────────┐ ┌──────────┐  │
│  │  54.1    │ │   —      │  │
│  │  Avg     │ │ High CO  │  │
│  └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐  │
│  │   0      │ │   57     │  │
│  │  Legs    │ │  Darts   │  │
│  └──────────┘ └──────────┘  │
├─────────────────────────────┤
│  Leg breakdown table        │
│  ┌──────────────────────────┐│
│  │ Leg  │ Winner  │ Darts   ││  ← table header
│  │─────────────────────────││  ← 1dp colorOutline divider
│  │  1   │ ALICE   │  25    ││
│  │─────────────────────────││
│  │  2   │ BOB     │  31    ││
│  │─────────────────────────││
│  │  …                      ││
│  └──────────────────────────┘│
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** Back arrow returns to History page. Title: game type + key config (e.g. "X01 · 501", "Cricket · Standard"). No overflow menu.
- **Result header card:** Full-width card immediately below AppBar. Shows winner name (prominent), total darts, and date. `colorSurface` background.
- **Per-player stat sections:** One section per player. The winner's section comes first (no separate section header for the winner — the result header above already identifies them). Subsequent players have a player name section header. Each section has a 2×2 grid of stat cards.
- **Leg breakdown table:** Below all player sections. Full-width table showing each leg's winner and dart count.

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title (game type · config) | `textHeadingSmall` (DM Sans SemiBold 16sp) | `colorOnBackground` |
| Result header — winner name line | `textHeadingLarge` (DM Sans SemiBold 24sp) | `colorWin` (#2E7D32) |
| Result header — metadata (darts, date) | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |
| Per-player section header (loser name) | `textHeadingSmall` (DM Sans SemiBold 16sp) | `colorOnBackground` |
| Stat card value | `textScoreSmall` (Oswald Bold 36sp) | `colorOnBackground` |
| Stat card label | `textLabelMedium` (DM Sans Medium 12sp) | `colorOnSurfaceVariant` |
| Leg table header cells | `textLabelMedium` | `colorOnSurfaceVariant` |
| Leg table data rows | `textBodyMedium` (DM Sans Regular 14sp) | `colorOnBackground` |
| Winning leg row winner name | `textBodyMedium` **bold** (DM Sans SemiBold 14sp) | `colorPrimary` |

---

## Colors

| Element | Token |
|---|---|
| Screen background | `colorBackground` |
| Result header card background | `colorSurface` |
| Result header card corner radius | `radiusMedium` (12dp) |
| Result header card elevation | 1 |
| Per-player stat card background | `colorSurface` |
| Per-player stat card corner radius | `radiusMedium` (12dp) |
| Per-player stat card elevation | 1 |
| Leg table container background | `colorSurface` |
| Leg table container corner radius | `radiusMedium` (12dp) |
| Leg table header row background | `colorSurface` |
| Leg table body row divider | 1dp `colorOutline` |
| Winning leg row background | `colorPrimaryContainer` (subtle tint) at ~20% opacity |
| Non-winning leg row (even) | `colorSurface` |
| Non-winning leg row (odd) | `colorBackground` |

---

## Result Header Card

Full-width, `space4` (16dp) horizontal margin, `radiusMedium` corner radius, elevation 1.

Internal layout:
```
┌──────────────────────────────────────┐
│  ALICE won                           │  ← textHeadingLarge colorWin
│  43 darts · Mar 8, 2026             │  ← textBodySmall colorOnSurfaceVariant
└──────────────────────────────────────┘
```

- "ALICE won" — the word "won" is in `textHeadingLarge` but in `colorOnBackground` (not `colorWin`), so the result reads naturally: "[winner name in colorWin] won".
  - Alternatively: winner name + "won" both in `colorWin` — implementation choice, but winner name must be visually dominant.
- Metadata line: "{N} darts · {date}". Date format: "Mar 8, 2026" (include year). Separated by " · " (space + centred dot + space).
- Card internal padding: `space4` (16dp) all sides.

---

## Per-Player Stat Cards

Two equal-width cards per row, 2 rows per player = 4 stat cards per player.

**Card stats:**

| Position | Metric | Notes |
|---|---|---|
| Row 1, Left | Avg | 3-dart average for this game. "—" if <1 turn completed. |
| Row 1, Right | High CO | Highest single-dart checkout (finishing dart). "—" if no legs won. |
| Row 2, Left | Legs | Legs won in this game. |
| Row 2, Right | Darts | Total darts thrown by this player in this game. |

Stat cards are read-only. No tappable state.

**2-column gap:** `space3` (12dp).
**Row gap:** `space3` (12dp).
**Card internal padding:** `space4` (16dp) all sides.

**Stat value format:**
- Avg: one decimal place (e.g. "72.3"). "—" if insufficient data.
- High CO: integer (e.g. "121"). "—" if no legs won.
- Legs: integer (e.g. "2").
- Darts: integer (e.g. "43").

---

## Leg Breakdown Table

Full-width within `space4` (16dp) horizontal margin. `colorSurface` background, `radiusMedium` corner radius.

**Columns:**

| Column | Width | Content |
|---|---|---|
| Leg | ~64dp fixed | Leg number (1, 2, 3, …) |
| Winner | Flexible (fill) | Winning player's name |
| Darts | ~72dp fixed | Dart count for this leg |

**Table header row:**
- Labels: "Leg", "Winner", "Darts"
- `textLabelMedium colorOnSurfaceVariant`
- Background: `colorSurface`
- 1dp `colorOutline` bottom border

**Table body rows:**
- Row height: minimum 48dp.
- Row divider: 1dp `colorOutline` between each row.
- Winning player's leg row: subtle `colorPrimaryContainer` tint (approximately 20% opacity over the base row color). This helps identify which legs the current game's winner took.
- Leg number: centered in column.
- Winner name: left-aligned; `textBodyMedium colorOnBackground`; winner name bold (`textBodyMedium` DM Sans SemiBold weight) in `colorPrimary`.
- Darts count: right-aligned in column.

---

## Interactions

- **Tapping player name in result header:** Navigates to `PlayerDetailPage` for that player (`/players/:playerId`).
- **Tapping player section header (loser name):** Navigates to `PlayerDetailPage` for that player.
- **Player name tap areas:** minimum 48dp height touch target; ripple `colorOnSurface` at 12% opacity.
- **Stat cards:** Not tappable. No interaction.
- **Leg table rows:** Not tappable. No interaction.
- **Back button:** Returns to History page.

---

## Edge Cases

**Solo practice game:**
- Result header: "Drill Complete · {N} darts · {date}". No "won" phrasing. No `colorWin` — use `colorOnBackground`.
- Single player section only.
- Leg table: may show rounds instead of legs (implementation decision based on game type).

**Game with 1 leg:**
- Leg breakdown table shows a single row. Still rendered (not hidden for single-leg games).

**No leg winner (abandoned game):**
- Result header: "Game abandoned · {date}".
- "won" word is replaced with "abandoned".
- Winner name slot shows "—" or is omitted.
- Leg table may show partial legs.

**Loading:**
- Centered `CircularProgressIndicator` in `colorPrimary`.

**Error:**
- Centered `error_outline` icon 48dp.
- "Failed to load game details." `textBodyLarge colorOnBackground`.
- "Retry" TextButton `colorPrimary`.

**Many players (N > 2):**
- Per-player sections stack vertically, scrollable.
- The page is a `SingleChildScrollView` — all content is part of a single scrollable column.

---

## Special Notes

- **Read-only page.** No editing, no delete action, no overflow menu.
- **"High CO"** stands for "Highest Checkout" — the highest finishing score a player achieved in a single checkout dart. For X01, this is the value on the last dart thrown to win a leg.
- **Stat card value uses `textScoreSmall` (Oswald Bold 36sp)** in `colorOnBackground` — note this is NOT `colorPrimary` here (unlike summary cards on other screens). The result header already uses `colorWin` prominently; the stat cards use `colorOnBackground` to avoid color overload.
- Page horizontal margin: `space4` (16dp).
- Vertical spacing between sections: `space6` (24dp) between result header and first player section; `space6` (24dp) between player sections; `space6` (24dp) between last player section and leg breakdown table.
- Bottom safe area: `space16` (64dp).
