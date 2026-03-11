# SCR-013 — Player List Page

**Route:** `/players`
**File:** `lib/features/players/presentation/pages/player_list_page.dart`

---

## Design Principles

- **P4 — Clean list, no decoration:** Each player row carries all necessary information (avatar, name, stat subtitle) without decorative elements. Whitespace and typography hierarchy do the organizing work.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "Players"       [+]│  ← [+] icon button (right)
├─────────────────────────────┤
│                             │
│  ┌─────────────────────────┐│
│  │[○] ALICE                ││  ← 40dp circular avatar + name
│  │    3-dart avg 54.3      ││  ← stat subtitle
│  └─────────────────────────┘│
│  ──────────────────────────  │  ← 1dp colorOutline bottom divider
│  ┌─────────────────────────┐│
│  │[○] BOB                  ││
│  │    3-dart avg 41.0      ││
│  └─────────────────────────┘│
│  ──────────────────────────  │
│  ┌─────────────────────────┐│
│  │[○] CAROL                ││
│  │    —                    ││  ← "—" when no games played
│  └─────────────────────────┘│
│  …                          │
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** Back arrow returns to Home. Title "Players" left-aligned. Trailing [+] icon button (minimum 48×48dp tap target) in `colorPrimary`.
- **Player list:** Vertically scrollable list. Each row is full-width. Rows are separated by a 1dp `colorOutline` bottom divider drawn at the bottom of each row (no gap between divider and next row). No card container per row — dividers are the only separators.
- **Avatar:** 40dp diameter circular avatar. Positioned with `space4` (16dp) left margin, centered vertically within the row. Displays player initials (first letter of name, uppercase).
- **Text column:** To the right of the avatar, with `space3` (12dp) left gap. Contains two lines: player name and stat subtitle. Vertically centered within the row.

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title "Players" | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| [+] AppBar icon | — | `colorPrimary` |
| Player name | `textPlayerName` (DM Sans SemiBold 16sp, ALL CAPS, letter-spacing 1.5) | `colorOnBackground` |
| Stat subtitle | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |

---

## Colors

| Element | Token |
|---|---|
| Screen background | `colorBackground` |
| Player row background | `colorSurface` |
| Row bottom divider | 1dp `colorOutline` |
| Avatar background | `colorSecondaryContainer` |
| Avatar initials | `colorOnSecondaryContainer` |
| [+] AppBar icon | `colorPrimary` |

---

## Interactions

- **Player row:** Minimum 64dp height; full-width tap target. Ripple `colorOnSurface` at 12% opacity. Tapping navigates to PlayerDetailPage (`/players/:playerId`).
- **[+] icon button:** Minimum 48×48dp tap target. Tapping navigates to CreatePlayerPage (`/players/add`).
- **Swipe-to-delete:** Not implemented on this screen. Destructive actions (delete player) are handled on the PlayerDetailPage only.
- **Scroll:** Standard vertical scroll. No pagination — all players are loaded at once (the typical app has a small number of players, ≤20).

---

## Edge Cases

**Empty state (no players exist):**
- No player rows are shown.
- Centered in the available space:
  1. Icon: `person` (or `person_outline`) icon, 64dp, `colorOnSurfaceVariant` at 60% opacity.
  2. Primary message: "No players yet." — `textBodyLarge colorOnBackground`.
  3. Secondary message: "Tap + to add your first player." — `textBodyMedium colorOnSurfaceVariant`.
  4. CTA: FilledButton "ADD PLAYER" in `colorPrimary` — navigates to `/players/add`.
- The [+] icon in the AppBar remains visible and functional.

**Loading state:**
- Centered `CircularProgressIndicator` in `colorPrimary`.
- No skeleton list (player list is small and loads quickly).

**Error state:**
- Centered `error_outline` icon 48dp in `colorOnSurfaceVariant`.
- "Failed to load players." in `textBodyLarge colorOnBackground`.
- "Retry" TextButton in `colorPrimary`.

---

## Special Notes

- **Stat subtitle format:**
  - If the player has ≥1 completed game: `"3-dart avg {N}"` — where N is formatted to 1 decimal place (e.g. "54.3").
  - If the player has no completed games: `"—"` (em dash, single character).
- **Avatar initials:** First character of the player's name, uppercased. Font: `textLabelMedium` (DM Sans Medium 12sp) in `colorOnSecondaryContainer`. Avatar is circular (40dp diameter), not square.
- **Name truncation:** Player name max 24 chars (enforced at creation). Single line, no ellipsis needed.
- **Sorting:** Players are listed in creation order (most recently created last), or alphabetically — implementation decision. Document the choice in the provider.
- **Row height:** Minimum 64dp. If the player name + subtitle fit in fewer pixels, the row still maintains 64dp minimum height via `constraints`.
- Page horizontal margin for text: `space4` (16dp). Avatar itself has `space4` left margin from screen edge.
