# SCR-018 — History Page

**Route:** `/history`
**File:** `lib/features/history/presentation/pages/history_page.dart`

---

## Design Principles

- **P4 — Clean list, filter bar doesn't clutter:** Filters are compact chips in a single row. The game list dominates the screen. Filters don't obscure content.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "History"       ←  │
├─────────────────────────────┤
│  [All ▾] [Date range ▾] [✕]│  ← filter bar (sticky below AppBar)
├─────────────────────────────┤
│                             │
│  ┌──────────────────────┐   │
│  │ [X01·501]   Mar 8    │   │  ← game type chip + date right-aligned
│  │ ALICE won · 3 legs   │   │  ← winner + result summary
│  │ 43 darts             │   │  ← metadata line
│  └──────────────────────┘   │
│                             │
│  ┌──────────────────────┐   │
│  │ [Cricket] Feb 27     │   │
│  │ BOB won · 1 leg      │   │
│  │ 31 darts             │   │
│  └──────────────────────┘   │
│                             │
│  (repeat, infinite scroll)  │
│                             │
│  [small spinner]            │  ← pagination loading indicator
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** Back arrow returns to Home. Title "History". No overflow menu, no action icons.
- **Filter bar:** A sticky horizontal chip row immediately below the AppBar. Contains up to 3 elements: game-type dropdown chip, date-range dropdown chip, and a clear-filters [✕] icon button. The filter bar does not scroll with the list — it stays pinned below the AppBar.
- **Game card list:** Vertically scrollable, infinite-scroll list. Each card is full-width within `space4` (16dp) horizontal margin, with `space3` (12dp) vertical gap between cards. Cards use `radiusMedium` corner radius and elevation 1.
- **Pagination spinner:** A small `CircularProgressIndicator` (24dp) centered horizontally, appearing below the last card when more items are loading.

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title "History" | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| Filter chip label | `textLabelMedium` (DM Sans Medium 12sp) | active: `colorOnPrimaryContainer`; inactive: `colorOnSurfaceVariant` |
| Game type label chip (inside card) | `textLabelMedium` | `colorOnSecondaryContainer` |
| Date (inside card, right-aligned) | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |
| Winner line | `textBodyLarge` (DM Sans Regular 16sp) | `colorOnBackground` |
| Winner name within winner line | `textBodyLarge` **bold weight** (DM Sans SemiBold 16sp) | `colorOnBackground` |
| Metadata line (darts count) | `textBodySmall` | `colorOnSurfaceVariant` |

---

## Colors

| Element | Token |
|---|---|
| Screen background | `colorBackground` |
| Filter bar background | `colorBackground` (same as screen — no card or shadow) |
| Filter chip (active) background | `colorPrimaryContainer` |
| Filter chip (inactive) background | `colorSurfaceVariant` |
| Filter chip corner radius | `radiusFull` (pill) |
| Clear [✕] icon | `colorOnSurfaceVariant` |
| Game card background | `colorSurface` |
| Game card corner radius | `radiusMedium` (12dp) |
| Game card elevation | 1 |
| Game type label chip background | `colorSecondaryContainer` |
| Game type label chip text | `colorOnSecondaryContainer` |
| Game type label chip corner radius | `radiusXSmall` (4dp) |
| Pagination spinner | `colorPrimary` |

---

## Filter Bar Behavior

**Game type dropdown chip `[All ▾]`:**
- Default label: "All".
- Tap opens a dropdown menu (or bottom sheet) with options: All, X01, Cricket, Practice (and any other implemented game types).
- When a filter is active, the chip label changes to the selected game type (e.g. "X01"), and the chip background changes to `colorPrimaryContainer`.
- Minimum tap target: 48dp height.

**Date range dropdown chip `[Date range ▾]`:**
- Default label: "Date range".
- Tap opens a date range picker (standard date picker widget).
- When a filter is active, the chip label changes to a compact date representation (e.g. "Mar 1–8"), background changes to `colorPrimaryContainer`.
- Minimum tap target: 48dp height.

**Clear [✕] button:**
- Visible only when at least one filter is active.
- Minimum tap target: 48×48dp.
- Tapping clears all active filters and returns the list to unfiltered state.
- When no filters are active: the [✕] button is hidden (not just greyed out — fully absent from the layout).

---

## Game Card Layout

```
┌──────────────────────────────────────┐
│ [X01·501]                   Mar 8   │  ← top row: type chip left, date right
│ ALICE won · 3 legs                  │  ← winner line
│ 43 darts                            │  ← metadata
└──────────────────────────────────────┘
```

- **Top row:** Game type label chip on the left; date on the right; both on the same baseline row.
- **Game type label chip:** Compact chip showing game type + key config (e.g. "X01·501", "Cricket", "Practice·ATC"). `colorSecondaryContainer` bg, `colorOnSecondaryContainer` text, `radiusXSmall` corner.
- **Date:** Short format (e.g. "Mar 8", or "Mar 8, 2025" if not current year).
- **Winner line:** "{WINNER NAME} won · {N} {N == 1 ? 'leg' : 'legs'}". Winner name is rendered in bold weight (DM Sans SemiBold 16sp). The rest of the line is regular weight.
  - For a draw: "Game drawn · {N} legs".
  - For a solo/practice game: "Completed · {N} rounds" or equivalent.
- **Metadata line:** "{N} darts". Total darts thrown across the game.
- Card internal padding: `space4` (16dp) on all sides.
- Card minimum height: 88dp (to accommodate 3 text lines at standard line heights).

---

## Infinite Scroll Behavior

- **Load trigger:** `loadNextPage()` fires when the scroll offset reaches within 200dp of the end of the list (not at the very bottom — early trigger to appear seamless).
- **Guard:** Do not fire `loadNextPage()` when already loading or when all pages have been loaded.
- **Pagination spinner:** Centered 24dp `CircularProgressIndicator` in `colorPrimary`, appearing below the last card with `space4` (16dp) top padding.
- **No "end of list" indicator:** When all pages are exhausted, the spinner simply stops appearing. No "You've reached the end" message.

---

## Interactions

- **Game card tap:** Navigates to Game Detail page (`/game/history/:gameId`). Ripple `colorOnSurface` at 12% opacity, clipped to card.
- **Scroll:** Standard vertical scroll. Scroll position is preserved when returning from Game Detail (if supported by the routing stack — implementation best-effort).

---

## Edge Cases

**Empty state (no games at all):**
- Filter bar still shown.
- Centered in available space (below filter bar):
  1. Icon: `history` icon, 64dp, `colorOnSurfaceVariant` at 60% opacity.
  2. Primary: "No completed games yet." — `textBodyLarge colorOnBackground`.
  3. Optional CTA: "Start your first game" FilledButton `colorPrimary` → Home (navigates back to `/`).

**Filter with 0 results:**
- No game cards shown.
- Centered message: "No games match these filters." — `textBodyMedium colorOnSurfaceVariant`.
- [✕] button is visible in filter bar (at least one filter is active).

**Initial loading (first page):**
- 3 shimmer skeleton cards in `colorSurfaceVariant`, `radiusMedium`, same height as a real card.
- Skeleton animation: horizontal shimmer sweep from left to right, `colorSurfaceVariant` base with slightly lighter highlight sweeping across. Duration: 1.2s per cycle, looping.
- No AppBar changes during initial load.

**Pagination loading (subsequent pages):**
- Existing cards remain visible.
- Small `CircularProgressIndicator` (24dp) appears centered below last card.

**Player filter (arrived from PlayerDetailPage "VIEW GAME HISTORY"):**
- If a playerId filter parameter is passed in the navigation arguments, the filter bar pre-populates with a player chip (e.g. "ALICE ×"). The game type filter remains at "All". The list shows only games featuring that player.
- This filter chip is distinct from the game type chip — it may be added as a 4th chip or replace the game type chip depending on implementation.

---

## Special Notes

- The filter bar is **sticky** — it remains fixed directly below the AppBar as the list scrolls underneath.
- Filter bar height: approximately 48dp (single chip row with `space2` (8dp) top and bottom padding).
- Filter bar horizontal padding: `space4` (16dp).
- Gap between filter chips: `space2` (8dp).
- Page horizontal margin for cards: `space4` (16dp).
- Vertical gap between cards: `space3` (12dp).
- Cards are sorted by game completion date, most recent first.
