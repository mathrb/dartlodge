# SCR-003 — Player Selection Page

**Route:** `/game/player-selection`
**File:** `lib/features/game/presentation/pages/player_selection_page.dart`

---

## Design Principles

- **P2 — Primary action reachable from thumb position:** START GAME button anchored at the bottom in the SafeArea, always visible. Destructive actions (deselect) are protected behind a modal.
- **P3 — Selected players always visible:** The selected-player area is a persistent zone above the roster grid; it does not scroll away.
- **P4 — Visual hierarchy:** The screen is divided into three clearly separated zones — config summary, selected-player area, and roster grid — distinguishable without relying on color alone.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "Players"       ←  │  ← no gear icon on this screen
├─────────────────────────────┤
│  ┌──────────────────────────┐│
│  │ 501 · Double Out · 1 Leg ✏││  ← config summary chip (full-width)
│  └──────────────────────────┘│
├── Selected player area ──────┤
│                              │
│   ○ ALICE    ○ BOB           │  ← 40dp circular avatars + name below
│   (drag to reorder)          │
│                              │
│  [placeholder if none]       │  ← faint "Select players below" when empty
│                              │
├── Roster grid ───────────────┤
│  ┌────────────────────────┐  │
│  │ [○A] [○B] [○C] [○D]   │  │  ← 4-column player grid
│  │  A    B    C    D      │  │
│  │ [○E] [○F] [○G] [ + ]  │  │  ← "+" card opens create-player modal
│  │  E    F    G    +      │  │
│  └────────────────────────┘  │
│  (~2.33 rows visible — scroll│
│   affordance intentional)    │
├─────────────────────────────┤
│  [        START GAME      ] │  ← full-width FilledButton, SafeArea bottom
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** Back arrow returns to Variant Selection. No gear icon — the config chip (below) is the sole entry point to game settings on this screen.
- **Config summary chip:** Full-width chip immediately below the AppBar. Horizontal padding `space3` (12dp), vertical padding `space2` (8dp) + `space1` (4dp) = approximately 10dp top and bottom. Shows the current game configuration in compact form. Trailing edit icon (✏) in `colorPrimary`.
- **Selected player area:** Fixed-height zone. Players are shown as 40dp circular avatars with their name below (`textPlayerName`). Players are arranged in a horizontal row with wrapping. A drag handle on each allows reordering the turn order. Tapping a selected player avatar opens a small action modal.
- **Roster grid:** 4-column grid in a card container. Each cell is a player avatar (40dp) with name below. Fixed height showing approximately 2.33 rows — the partial third row is an intentional scroll affordance. The last cell in the roster is always the "+" add-player card.
- **START GAME button:** Full-width, anchored at the bottom inside SafeArea. `space4` (16dp) horizontal padding, `space4` (16dp) bottom padding above safe area inset.

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title "Players" | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| Config summary chip text | `textBodyMedium` (DM Sans Regular 14sp) | `colorOnBackground` |
| Config summary chip edit icon | — | `colorPrimary` |
| Selected player name (below avatar) | `textPlayerName` (DM Sans SemiBold 16sp, ALL CAPS, letter-spacing 1.5) | `colorOnBackground` |
| Roster grid player name (below avatar) | `textLabelSmall` (DM Sans Medium 11sp) | `colorOnBackground` |
| Roster grid player name overflow | single line, ellipsis | — |
| "+" card icon label | — | `colorPrimary` |
| "Select players below" placeholder | `textBodyMedium` | `colorOnSurfaceVariant` at 60% opacity |
| "START GAME" button label | `textLabelLarge` (DM Sans Medium 14sp) | `colorOnPrimary` (enabled) / `colorOnSurface` at 38% (disabled) |
| Player modal title | `textHeadingSmall` (DM Sans SemiBold 16sp) | `colorOnBackground` |
| Create-player modal name field label | `textBodyMedium` | `colorOnSurfaceVariant` |

---

## Colors

| Element | Token |
|---|---|
| Screen background | `colorBackground` |
| Config summary chip background | `colorSurface` |
| Config summary chip border | 1dp `colorOutline` |
| Config summary chip corner radius | `radiusMedium` (12dp) |
| Selected-player area background | `colorBackground` (no card) |
| Roster grid card background | `colorSurface` |
| Roster grid card border | 1dp `colorOutline` |
| Roster grid card corner radius | `radiusMedium` (12dp) |
| Player avatar background | `colorSecondaryContainer` |
| Player avatar initials | `colorOnSecondaryContainer` |
| "+" card background | `colorSurfaceVariant` |
| "+" card icon | `colorPrimary` |
| START GAME (enabled) | `colorPrimary` filled, `colorOnPrimary` text |
| START GAME (disabled) | `colorSurfaceVariant` background, foreground at 38% opacity |
| Selected player highlight | none — the avatar is visually distinct by being in the selected area |

---

## Interactions

- **Config summary chip:** Full-width tap target, minimum 48dp height. Opens the Game Config Bottom Sheet (SCR-004) as a modal bottom sheet. Dismissing the sheet without tapping "APPLY SETTINGS" discards changes.
- **Roster grid cell (player):** Minimum 48×48dp tap target per cell. Tap toggles the player in/out of the selected-player area. When selected, the player avatar appears in the selected-player zone. Tapping again deselects.
- **Selected player avatar:** Tap opens a small modal with two options:
  - "Handicap settings" (placeholder — navigates nowhere in current scope; shown as disabled with Tooltip "Coming soon")
  - "Deselect" — removes the player from the selected area and returns them to deselected state in the roster grid
- **Drag handle on selected player:** Shows a drag affordance (6-dot grid icon, `colorOnSurfaceVariant`). Dragging reorders the turn-order list. New order is reflected in the order players appear during the game.
- **"+" card:** Minimum 48×48dp. Tap opens a lightweight inline create-player modal (see below).
- **START GAME button:** Minimum 48dp height, full-width. Enabled only when ≥1 player is in the selected area. When disabled, include Tooltip "Select at least one player". Tapping (when enabled) calls the startGame notifier method and navigates to the appropriate game board.

**Create-player inline modal:**
- A bottom sheet or dialog overlaying the current screen.
- Contains: 60dp circular avatar preview (updates as name is typed), name text field (max 24 chars), "CREATE PLAYER" button.
- On success: modal dismisses; new player auto-appears in roster grid; new player is automatically added to the selected-player area.

---

## Edge Cases

- **0 players in roster:** Grid shows only the "+" card in the first cell. No separate empty-state message shown in the grid — the "+" is sufficient affordance.
- **Newly created player:** Appears as the first new cell in the grid and is auto-selected (moved to selected-player area immediately).
- **Selected player area with 0 selected:** Show faint centered placeholder text "Select players below" in `textBodyMedium` at 60% opacity in `colorOnSurfaceVariant`. No icon.
- **Max players (implementation limit):** If the game type has a maximum player count (e.g. X01 max 6), disable additional roster cells from being selected once the limit is reached. Show Tooltip "Maximum N players reached" on disabled cells.

---

## Special Notes

- **Config summary chip format strings:**
  - **X01:** `"{score} · {outStrategy} Out · {legsToWin == 1 ? '1 Leg' : 'Best of N'}"`
    - Example: `"501 · Double Out · 1 Leg"`
  - **Cricket:** `"{variant} · {N} {N == 1 ? 'pt' : 'pts'} to win"`
    - Example: `"Standard · 3 pts to win"`
  - **Practice:** game name only, e.g. `"Around the Clock"`
- The roster grid is fixed in height showing approximately 2.33 rows. The partial third row is intentional to signal scroll capability. Do not make the grid expand dynamically.
- Player avatar diameter: 40dp. Initials rendered in `textLabelMedium` (DM Sans Medium 12sp).
- Page horizontal margin: `space4` (16dp).
- START GAME button: `space4` (16dp) horizontal margin, `space4` (16dp) bottom padding above SafeArea inset, `space16` (64dp) bottom safe area.
- The "drag to reorder" affordance only appears for the selected-player area. The roster grid is not reorderable.
