# Screen Design Specifications — my-darts

**Theme:** Kinetic Precision
**Last updated:** 2026-03-22
**Status:** Specification (pre-implementation)

Read `DESIGN_SYSTEM.md` first — all token names referenced here are defined there.

---

## Navigation Structure

The app uses a **hub-and-spoke** pattern. The Home page is the single navigation hub; every other screen is a spoke.

- All destinations are reachable directly from the Home page via tappable cards or icons.
- Every sub-screen has only a back button in the AppBar — no persistent navigation chrome exists anywhere.
- There is no persistent bottom navigation bar and no hamburger menu anywhere in the app.
- Settings is accessed via a gear icon (⚙) in the Home AppBar only — it is not a card.
- Game boards (X01, Cricket, Practice) are full-screen with no AppBar navigation chrome.
- Sub-screen state does not need to be preserved between visits — reload-on-entry is acceptable.
- No `StatefulShellRoute` / persistent navigation stack is needed.

The four Home page entry points are:
1. **History card** — full-width nav card below the game list → `HistoryPage`
2. **Local Players card** — full-width nav card below History → `PlayerListPage`
3. **Statistics list item** — game list row in the "PLAY" section → `CareerStatsPage`
4. **Settings ⚙** — gear icon in the Home AppBar → `SettingsPage`

---

## 1. Home Page (`/`)

**File:** `lib/features/game/presentation/pages/home_page.dart`

### Layout Anatomy

```
┌─────────────────────────────┐
│  Darts                   ⚙ │  ← gear → Settings
├─────────────────────────────┤
│  PLAY                       │  ← section label
│  |▌ X01               →    │  ← left accent bar, primary
│  |▌ Cricket           →    │  ← primary
│  |▌ Practice          →    │  ← primary
│  |▌ Statistics        →    │  ← primary
├─────────────────────────────┤
│  [History              →]   │  ← full-width nav card
│  [Local Players        →]   │  ← full-width nav card
├─────────────────────────────┤
│  (Coming soon, desaturated) │
│   [Game Lobby]              │
│   [VS Friends]              │
└─────────────────────────────┘
```

### Typography
- AppBar title: `textHeadingMedium`, `onSurface`
- Game list item label: `textBodyLarge`, `onSurface`
- Game list item subtitle: `textBodySmall`, `onSurfaceVariant`
- "PLAY" section label: `textLabelSmall`, `onSurfaceVariant`, uppercase
- History / Local Players nav card label: `textBodyLarge`, `onSurface`

### Color Usage
- All game list cards: `surfaceContainerLow` background, `radiusNone`
- X01 left accent bar: `primary` (4dp)
- Cricket left accent bar: `primary` (4dp)
- Practice left accent bar: `primary` (4dp)
- Statistics left accent bar: `primary` (4dp)
- Chevron per card: `primary`
- History / Local Players nav cards: `surfaceContainerLow` background
- Coming-soon cards: `surfaceContainerHighest` background, `onSurfaceVariant` text, `opacity: 0.6`

### Special Notes
- The gear icon (⚙) in the AppBar navigates to Settings. Settings is not a card.
- The game list is a single-column vertical stack of full-width cards with `radiusNone` corners and `64dp` minimum height.
- Each card has a 4dp left accent bar using the color tokens above; label is left-aligned; trailing chevron matches accent color.
- Optionally a subtitle line (`textBodySmall`, `onSurfaceVariant`) can be shown — reserved for future use.
- History and Local Players are full-width cards placed below the game list. They use a trailing chevron icon to reinforce navigation affordance.
- Coming-soon cards are visually de-emphasised (lower opacity) and have a "Coming Soon" label in `textLabelMedium`. They receive no `onTap` handler and show `cursor: not-allowed` semantics. Coming-soon cards are: Game Lobby and VS Friends.

---

## 2. Variant Selection Page (`/game/variant-selection/:gameType`)

**File:** `lib/features/game/presentation/pages/variant_selection_page.dart`

### Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "[Game Type]"      │
├─────────────────────────────┤
│  Scrollable list of         │
│  variant option cards       │
│   [501 — Double Out]        │
│   [301 — Double Out]        │
│   [Standard Cricket]        │
│   …                         │
└─────────────────────────────┘
```

### Typography
- AppBar title: `textHeadingMedium`
- Variant name: `textBodyLarge`, `onSurface`
- Variant subtitle: `textBodyMedium`, `onSurfaceVariant` (adapts to `onPrimaryFixed` / `onPrimaryFixed` on filled/selected pills)
- Hint line: `textBodySmall`, `onSurfaceVariant`, left-aligned

### Color Usage
- Selected variant card: `primaryContainer` background, `onPrimaryFixed` text, left border 3dp `primary`
- Unselected card: `surfaceContainerLow`

### Special Notes
- Variants are tappable list tiles, minimum 64dp height.
- A single tap navigates directly to player selection with the variant pre-selected — no confirm button needed.
- Each variant card displays a **subtitle** (`textBodyMedium`, `onSurfaceVariant`) summarising its default rules:
  - X01 presets: `"Double Out · 1 Leg"` (substituting the actual leg count for multi-leg presets)
  - Cricket presets: describe the variant rule and scoring threshold, e.g. `"Close 15–20 & Bull · 3 pts to win"` for Standard Cricket
  - Practice variants: **Shanghai** shows the round count (e.g., `"7 Rounds"`); others have **no subtitle** as they are self-describing.
  - Disabled Custom entry: **no subtitle**
- A **hint line** is rendered below the pill list in all categories:
  `"Select a preset — you can adjust the settings on the next screen"`
  Styled `textBodySmall`, `onSurfaceVariant`, left-aligned, with `space4` (16 dp) top padding.

---

## 3. Player Selection Page (`/game/player-selection`)

**File:** `lib/features/game/presentation/pages/player_selection_page.dart`

### Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "Players"          │
├─────────────────────────────┤
│  [501 · Double Out · Best of 3  ✏]  │  ← config summary chip, full-width
├─────────────────────────────┤
│                             │
│  Selected players           │
│  (drag to reorder)          │
│  [Avatar]  [Avatar]  …      │
│   NAME      NAME            │
│                             │
├─────────────────────────────┤
│  ┌─────────────────────┐    │
│  │ [Av] [Av] [Av] [Av] │    │  ← 4-column roster grid
│  │ NAME NAME NAME NAME │    │    fixed height, ~2.33 rows visible
│  │ [Av] [Av] [Av] [+]  │    │    vertically scrollable, peek cue
│  │ NAME NAME NAME  +   │    │
│  └─────────────────────┘    │
├─────────────────────────────┤
│  [START GAME]               │  ← full-width, SafeArea
└─────────────────────────────┘
```

### Typography
- AppBar title: `textHeadingMedium`
- Config summary chip text: `textBodyMedium`, `onSurface`
- Config summary chip edit icon: `primary`, 16 dp
- Selected player name: `textPlayerName` (ALL CAPS)
- Roster grid name: `textLabelSmall`, `onSurface`, max 1 line, ellipsis overflow
- "START GAME" button: `textLabelLarge`, `onPrimaryFixed`
- Modal title: `textHeadingSmall`

### Color Usage
- Config summary chip: `surfaceContainerLow` background, `radiusNone`; `primary` trailing edit icon
- Selected player area: `surface`
- Roster grid container: `surfaceContainerLow` background, `radiusNone`
- Roster grid avatar (real player): `surfaceContainerHighest` background,
  `onSurface` initials
- Roster grid "+" card: `surfaceContainerHighest` background, `primary` "+" icon
- "START GAME" button disabled: 38% opacity when no players selected

### Special Notes
- **Config summary chip** sits immediately below the AppBar as a full-width tappable row:

  ```
  ┌──────────────────────────────────────────┐
  │  501 · Double Out · 1 Leg             ✏  │
  └──────────────────────────────────────────┘
  ```

  - Background `surfaceContainerLow`; `radiusNone`; padding 12 dp horizontal, 10 dp vertical.
  - Left text: config summary string (`textBodyMedium`, `onSurface`).
  - Right icon: `edit_outlined` in `primary`, 16 dp.
  - Tapping anywhere on the chip opens the Game Config bottom sheet (Section 4).
  - The chip re-renders immediately after settings are applied — it always reflects the current live config.
  - The AppBar on this page carries **no ⚙ settings icon** — the chip is the sole entry point to game config. The ⚙ icon is used exclusively on the Home page (→ Settings).

  **Config summary string format:**

  | Game type | Format |
  |---|---|
  | X01 | `"{score} · {outStrategy} Out · {legsToWin == 1 ? '1 Leg' : 'Best of N'}"` |
  | Cricket | `"{variant} · {N} {N == 1 ? 'pt' : 'pts'} to win"` |
  | Practice | Shanghai: `"{gameName} · {totalRounds} Rounds"`; others: game name only |

  Out strategy labels: Straight, Double, Master.
  Cricket variant labels: Standard, No Score, Cut Throat, Tactics.
- **Selected players area** (center): displays chosen players as avatars with name below.
  Players can be dragged to reorder — turn order is significant in darts.
  Tapping a selected player opens a modal with two options:
  - Handicap settings (starting score offset for this player)
  - Deselect (removes player from selection)
- **Roster grid** (bottom ~20–25% of screen): fixed-height bordered container.
  4 columns, vertically scrollable. Height is set to show approximately 2.33 rows —
  the partial third row is an intentional scroll affordance indicating more players below.
  Each cell shows a circular avatar (40dp) with the player's name truncated below.
  The last cell is always a "+" card; tapping it opens a lightweight inline modal
  (avatar preview + name field + CREATE PLAYER confirm button). The newly created player
  appears immediately in the roster grid and is auto-selected into the center area.
- **"START GAME" button** is anchored at the very bottom, wrapped in `SafeArea` to
  respect home indicator insets. Sufficient padding separates it from the roster grid
  to prevent mis-taps.
- Player avatar: circular, 40dp diameter, initials in `textLabelMedium` on
  `surfaceContainerHighest`.
- Minimum tap target for each roster grid cell: 48×48dp.
- If the roster has 0 real players, the grid shows only the "+" card (no separate empty
  state message needed).

---

## 4. Game Config Page (Bottom Sheet) (`/game/config`)

**File:** `lib/features/game/presentation/pages/game_config_page.dart`

### Layout Anatomy

Rendered as a modal bottom sheet, not a full page.

```
┌─────────────────────────────┐
│  ──── drag handle           │
│  "Game Settings"            │
│                             │
│  Starting Score: [501▾]     │
│  In Strategy:   [Any ▾]     │
│  Out Strategy:  [Double▾]   │
│  Legs to Win:   [− 3 +]     │
│  Rounds:        [7 ▾]       │  ← visible for Shanghai
│                             │
│  [APPLY SETTINGS]           │
└─────────────────────────────┘
```

### Typography
- Sheet title: `textHeadingMedium`
- Field labels: `textBodyMedium`, `onSurfaceVariant`
- Dropdown values: `textBodyLarge`, `onSurface`
- Apply button: `textLabelLarge`, `onPrimaryFixed` on `primaryContainer`

### Color Usage
- Sheet background: `surfaceContainerLow`
- Drag handle: `outlineVariant`
- Stepper (−/+) buttons: outlined style, `primary` border + text
- Count value between steppers: `textHeadingMedium`, `onSurface`

### Special Notes
- Opened via the config summary chip on the Player Selection page (Section 3).
- Sheet height: `isScrollControlled: true` with `maxChildSize: 0.75`.
- Stepper buttons minimum 48×48dp touch target.
- "Rounds" is a dropdown (7, 10, 15, 20) visible only for game types that support it (e.g., Shanghai).
- All changes are held in local state until "APPLY SETTINGS" is tapped — tapping the drag-handle drag area dismisses without saving.

---

### Game Board Layout Constraint (applies to all board screens: X01, Cricket, Practice)

All game board screens must fit entirely within the device viewport with no scrolling required. The bottom action bar (NEXT ROUND / NEXT PLAYER / advance button) must always be visible without user scrolling.

Implementation rule: The page body must use a `Column` with `Expanded` children to distribute vertical space. **Never use `SingleChildScrollView` as the body wrapper for a game board.** Flex-based layout guarantees the board adapts to any screen height; minimum cell heights (48dp for X01, 36–56dp for Cricket) prevent content from becoming unusably small.

---

## 5. X01 Board Page (`/game/x01/:gameId`)

**File:** `lib/features/game/presentation/pages/x01_board_page.dart`

This is the highest-frequency interaction surface. Legibility and tap ergonomics take absolute priority.

### Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "501"              │
│           "Leg 1 of 3"      │
│                        [⋮] │
├─────────────────────────────┤
│  [60]  [T20]  [○]  [○]     │  ← dart indicator row
│  sum    dart1  dart2 dart3  │
├─────────────────────────────┤
│ ┌────────┬────────┬────────┐│
│ │[60]312 │  501   │  …     ││  ← [round sum] remaining score
│ │ ALICE▶ │  BOB   │        ││  ← name (active player marked ▶)
│ │PPR 54.3│ PPR —  │        ││  ← PPR
│ └────────┴────────┴────────┘│
│   (1–6 equal-width columns)  │
├─────────────────────────────┤
│  💡 T20 · T18 · D8          │  ← checkout banner (≤170 only)
├─────────────────────────────┤
│  ┌────────────────────────┐  │
│  │  MISS  │  SB·25│ DB·50 │  │  ← row 0: 3 equal cells (surfaceContainerLow)
│  │                        │  │  ← tier boundary: tonal shift (no hairline)
│  │20│19│18│17│16│15│14│13│12│11│  ← row 1 singles (surfaceContainerLow)
│  │10│ 9│ 8│ 7│ 6│ 5│ 4│ 3│ 2│ 1│  ← row 2 singles
│  │                        │  │  ← tier boundary: tonal shift (no hairline)
│  │20│19│…                 │  │  ← row 3 doubles (primaryContainer)
│  │ ·· ·· ··               │  │     2-dot indicators below numbers
│  │10│ 9│…                 │  │  ← row 4 doubles
│  │                        │  │  ← tier boundary: tonal shift (no hairline)
│  │20│19│…                 │  │  ← row 5 triples (primary)
│  │···│···│···              │  │     3-dot indicators below numbers
│  │10│ 9│…                 │  │  ← row 6 triples
│  └────────────────────────┘  │
├─────────────────────────────┤
│  [↩ Undo]    [NEXT ROUND]  │
└─────────────────────────────┘
```

### Typography
- AppBar title line 1: `textHeadingSmall`, `onSurface` — starting score
- AppBar title line 2: `textBodySmall`, `onSurfaceVariant` — leg indicator
- Player name: `textPlayerName` (ALL CAPS); active player uses `onSurface`, inactive uses `onSurfaceVariant` at 60% opacity; truncate with ellipsis if needed
- Active player score: `textScoreActive` — scales with N: 80sp (N=1), 64sp (N=2), 48sp (N=3–4), 36sp (N=5–6)
- Inactive player score: always one step smaller than active in the same game; same scale steps apply
- Round sum prefix (inline before remaining score): `textBodySmall`, `onSurfaceVariant`
- Dart indicator chip label: `textBodyMedium`, `onSurface`; round sum: `textHeadingSmall`, `primary`
- PPR: `textBodySmall`, `onSurfaceVariant`
- Segment button number: `textSegmentButton` (18sp Inter SemiBold)
- "NEXT ROUND" button: `textLabelLarge`
- Checkout banner text: `textBodyMedium`, `onSurface`; 💡 icon in `primary`

### Color Usage
- Active player panel: `colorActivePlayerBg` background, 4dp left border `colorActivePlayer`
- Active player score: `primary`
- Inactive player panel: `surface`
- Segment grid outer container: `surface` background, `radiusNone`. Fills full screen width (edge-to-edge).
- Individual cells: `radiusNone`. No explicit border — visual separation between tiers is provided by background color changes.
- Tier boundaries (rows 2→3, rows 4→5): tonal step from singles (`surfaceContainerLow`) to doubles (`primaryContainer`) to triples (`primary`) provides the separator — no hairline needed.
- Row 0 / rows 1–2 (singles): `surfaceContainerLow` background, `onSurface` text.
- Rows 3–4 (doubles): `primaryContainer` background, `onPrimaryFixed` text, 2 × 4dp filled dot indicators in `onPrimaryFixed`.
- Rows 5–6 (triples): `primary` background, `onPrimary` text, 3 × 4dp filled dot indicators in `onPrimary`.
- Undo button: icon in `onSurface`; disabled state 38% opacity
- "NEXT ROUND": `primary` filled button, `onPrimary` text (Action Button style — see DESIGN_SYSTEM §6.1)
- Dart indicator chip (thrown): `surfaceContainerLow` background, `outlineVariant` at 20% opacity border
- Dart indicator chip (remaining): outline circle, `outlineVariant` at 20% opacity
- Checkout banner background: `surfaceContainerLow`, left border `primary` (2dp)

### Special Notes
- **Score must never wrap or truncate.** Score panel width must be wide enough for "501" at 80sp. On narrow screens, reduce inactive score to `textScoreMedium` (48sp) before truncating.
- **Dart indicator row** sits between AppBar and scoreboard. Round sum on the left (bold, `primary`), then up to 3 chips — thrown darts show the segment label (e.g. "T20", "SB", "14"), remaining slots show an empty outline circle. Sum increments as darts land.
- **Segment input grid (contiguous tile layout):** The input area spans the full screen width (edge-to-edge, no horizontal margin). No padding inside the container — cells are flush against each other and against the container walls. No spacing between cells. Parent container: `radiusNone` (flat bar).

  Row 0: MISS / SB / DB — 3 equal-width cells. Rows 1–2: singles 20→11 and 10→1, 10 cells per row. Rows 3–4: doubles, same number order, 10 cells per row. Rows 5–6: triples, same number order, 10 cells per row. Cell heights flex equally across all 7 rows to fill available vertical space; minimum cell height 48dp.

  Cell borders: no explicit hairlines — tonal background changes between tiers (singles `surfaceContainerLow` → doubles `primaryContainer` → triples `primary`) provide visual separation. Ripple is clipped to the individual cell boundary (Material `InkWell` inside `radiusNone` cell).

  Dot indicators are rendered below the number within the cell using the cell's foreground color. No text multiplier label.

  Semantic label per cell: "Single [N]", "Double [N]", "Triple [N]", "Miss", "Single Bull", "Double Bull".
- **Player score panel:** The scoreboard is a single row of N equal-width columns (N = 1–6, enforced by the game config max). Each column contains a vertical stack: (1) round sum prefix + remaining score on one line — the round sum is the total of darts thrown so far this turn, shown in small text to the left of the main score; (2) player name (ALL CAPS, ▶ suffix for active player); (3) PPR, showing '—' until at least one turn is complete. Score font scales with N: 80sp / 64sp / 48sp / 36sp for N = 1 / 2 / 3-4 / 5-6. All columns are always visible; no scrolling or collapsing.
- **Checkout suggestion:** A full-width banner row is inserted between the scoreboard and the input grid whenever the active player's remaining score is ≤ 170. Background `surfaceContainerLow`, 2dp left border `primary`, 💡 icon + suggestion string (e.g. "T20 · T18 · D8"). Hidden otherwise — row collapses to zero height.
- The nav bar is hidden on this screen (full-screen game mode).

---

## 6. Cricket Board Page (`/game/cricket/:gameId`)

**File:** `lib/features/game/presentation/pages/cricket_board_page.dart`

### Layout Anatomy

Unified table where the scoreboard (left columns) and input buttons (right columns) share the same rows. The dart indicator sits between the AppBar and the table.

```
AppBar: "Cricket | Standard · Leg 1"         [⋮]
[Dart indicator: T20 | ○ | ○]
──────────────────────────────────────────────────
| 64      | 32      | [MISS ×2col ] | [UDO×1] |  ← header row
| ALICE   | BOB     |               |         |     score top, name below
| ⊗       | X       | [ 20 ]  | [ 20 ]  | [ 20 ] |
|         |         |         | [ ·· ] | [ ··· ]|
| /       | ⊗       | [ 19 ]  | [ 19 ]  | [ 19 ] |
| X       | X       | [ 18 ]  | [ 18 ]  | [ 18 ] |
| ─       | /       | [ 17 ]  | [ 17 ]  | [ 17 ] |
| ─       | ─       | [ 16 ]  | [ 16 ]  | [ 16 ] |
| ─       | ─       | [ 15 ]  | [ 15 ]  | [ 15 ] |
| ─       | ─       | [SB  ×1.5col] | [DB  ×1.5col] |
──────────────────────────────────────────────────
| (target+marks area — left)   | [NEXT PLAYER ×3col] |  ← footer
```

### Typography
- Dart indicator chip label: `textBodyMedium`, segment string (e.g. "T20", "SB"); empty slots: outline circle `○`
- Player score in header: `textScoreSmall` (36sp Space Grotesk Bold), `primary`
- Player name in header: `textLabelSmall`, `onSurface`, ALL CAPS
- Target label: `textSegmentButton` (18sp Inter SemiBold)
- Mark symbols: `textHeadingMedium`
- Input button number: `textSegmentButton` (18sp Inter SemiBold)
- "NEXT PLAYER" / "NEXT ROUND" cell: `textLabelLarge`
- "MISS" / "UNDO" cells: `textLabelLarge`
- "SB" / "DB" cells: `textSegmentButton` (matches number input cells)

### Mark Symbols

| Marks | Symbol | Color |
|-------|--------|-------|
| 0     | ─      | `onSurfaceVariant` |
| 1     | /      | `onSurface` |
| 2     | X      | `onSurface` (bold) |
| 3+    | ⊗      | `colorCricketClosed` (`#00FFAB`) |

### Input Cell Styling (contiguous tile layout)

Cells are flush, `radiusNone`, with no explicit border — tonal background changes between cell types (single `surfaceContainerLow` → double `primaryContainer` → triple `primary`) provide visual separation. Cell height: flex (expands equally across the 7 target rows to fill available screen height); minimum 36dp. Cell width: equal thirds of the input column group.

- Single cell: `surfaceContainerLow` background, `onSurface` text, no dot indicators.
- Double cell: `primaryContainer` background, `onPrimaryFixed` text, 2 × 4dp dot indicators below number.
- Triple cell: `primary` background, `onPrimary` text, 3 × 4dp dot indicators below number.

**Control cells** (MISS, UNDO, SB, DB, NEXT PLAYER) use the same flat tile style as number input cells: `radiusNone`, no explicit border, minimum height 56dp. They are laid out in the input column group using fractional widths:
- MISS: 2/3 of input width
- UNDO: 1/3 of input width
- SB: 1/2 of input width
- DB: 1/2 of input width
- NEXT PLAYER: full input width (3/3)

Control cells use `surfaceContainerLow` background and `onSurface` text at rest. UNDO is disabled (38% opacity) when no darts have been thrown in the current turn. Tapped state follows the same ripple/ink treatment as number cells.

### Color Usage
- Closed row (all players ≥3 marks): entire row at 38% opacity, `surfaceContainerHighest` tint; input buttons disabled
- Active player column header: `primary` score; subtle left border or background to indicate active
- Dart indicator chip (thrown): `surfaceContainerLow` background, `outlineVariant` at 20% opacity border, segment label
- Dart indicator chip (remaining): outline circle `○`, `outlineVariant` at 20% opacity
- MISS cell: `surfaceContainerLow` background, `onSurface` text — flat tile, no border
- UNDO cell: `surfaceContainerLow` background, `onSurface` text — disabled at 38% opacity when no darts thrown
- SB / DB cells: `surfaceContainerLow` background, `onSurface` text — flat tile, no explicit border
- NEXT PLAYER cell: `surfaceContainerLow` background, `onSurface` text — flat tile spanning full input width
- Input cell dividers: tonal background shifts between cell types — no 1dp hairline.

### Special Notes
- **Dart indicator** sits between AppBar and the table. Shows segment label (e.g. "T20", "SB", "19") for thrown darts; outline circle for remaining slots.
- **Header row** shows each player's current score (top) and name (bottom, ALL CAPS). MISS spans 2 input columns and UNDO spans 1 input column in this row; both are flat tiles matching the number cell style.
- **Target rows** each contain: marks-per-player columns (flexible) | 3 flush input cells (equal width, together occupying fixed space so each cell ≥ 48dp wide). The 3 input cells share the same row height as the rest of the row (minimum 56dp). Individual input cells have `radiusNone`; they are not wrapped in their own card. Cell separation is expressed through tonal background differences — no 1dp hairlines.
- **All-closed rows**: when every player has ≥3 marks on a number, the row is visually dimmed. Input buttons are disabled — the number is out of play.
- **Bull row**: no triple. SB and DB each span 1.5 columns of the input area.
- **Advance button**: placed as a page-level bottom bar (pinned, always visible) below the table. It must not be inside the scrollable table — it is a `SafeArea`-wrapped fixed-height (48dp) bar at the bottom of the screen. Label is "NEXT PLAYER" in multiplayer (≥2 players) and "NEXT ROUND" in single-player mode.
- **No scrolling**: The cricket table must never require scrolling. The 7 target rows flex equally to fill the available space between the dart indicator and the advance button. Minimum row height is 36dp.
- **No auto-advance**: inputting the third dart never triggers automatic player rotation. The player must tap the advance button to confirm and move on.
- No persistent bottom navigation bar (full-screen game mode).

---

## 7. Practice Board Page (`/game/practice/:gameId`)

**File:** `lib/features/game/presentation/pages/practice_board_page.dart`

There are 5 practice game types. All share a common chrome layout described here; per-type details follow in subsections 7a–7e.

### Shared Chrome Layout

```
┌─────────────────────────────────┐
│  AppBar: "[Game Name]"          │
│           "[progress subtitle]" │  ← varies per game type (see subsections)
│  ←  back → Home           [⋮] │  ← overflow menu
├─────────────────────────────────┤
│  [60]  [T20]  [○]  [○]     │  ← dart indicator row (matches X01/Cricket)
│  sum    dart1  dart2 dart3  │
├─────────────────────────────────┤
│                                 │
│  DartboardHighlightWidget       │  ← Expanded, fills remaining height
│  current target highlighted in  │
│  primary; all others at    │
│  35% opacity                    │
│                                 │
├─────────────────────────────────┤
│  PracticeTargetDisplayWidget    │
│  Large target label (48sp)      │  ← textScoreMedium Space Grotesk Bold, primary
│  Secondary metric               │  ← textBodyMedium, onSurfaceVariant
├─────────────────────────────────┤
│  PracticeInputButtonsWidget     │  ← varies per game type (see subsections)
├─────────────────────────────────┤
│  BottomBar (SafeArea)           │
│  [↩ Undo]  [MISS]  [ACTION]    │  ← ACTION varies per game type
└─────────────────────────────────┘
```

### Shared Typography
- AppBar title line 1: `textHeadingSmall`, `onSurface` — game name
- AppBar title line 2: `textBodySmall`, `onSurfaceVariant` — progress subtitle
- Dart indicator chip label: `textBodyMedium`, `onSurface`; round sum: `textHeadingSmall`, `primary`
- Target label: `textScoreMedium` (48sp Space Grotesk Bold), `primary`
- Secondary metric: `textBodyMedium`, `onSurfaceVariant`
- Bottom-bar action button: `textLabelLarge`
- Undo button: `textLabelLarge`; disabled at 38% opacity

### Shared Color Usage
- Dart indicator chip (thrown): `surfaceContainerLow` background, `outlineVariant` at 20% opacity border
- Dart indicator chip (remaining): outline circle, `outlineVariant` at 20% opacity
- DartboardHighlightWidget highlighted segment: `primary`
- DartboardHighlightWidget non-highlighted segments: `onSurface` at 35% opacity
- Bottom-bar primary action: `primary` filled button
- MISS button: `surfaceContainerLow` background, `outlineVariant` at 20% opacity border
- Undo button: icon/text in `onSurface`; disabled at 38% opacity

### Shared Special Notes
- **Dart indicator row** sits between AppBar and the dartboard/content area. It functions identically to X01 and Cricket: Round sum on the left (bold, `primary`), then up to 3 chips — thrown darts show the segment label (e.g. "T20", "SB", "14"), remaining slots show an empty outline circle. Sum increments as darts land.
- The nav bar is hidden on this screen (full-screen practice mode).
- `NEXT ROUND` in the bottom bar is enabled only when `dartsThrownInTurn == 3` (i.e. all 3 darts of the current turn have been registered).
- `MISS` in the bottom bar is always enabled (records a missed dart without leaving the input grid).
- Back button navigates to Home; no save/abandon dialog is required for practice.

---

### 7a. Around the Clock

**AppBar subtitle:** "Number: N / 20"

**Target display:**
- Large: current target number (1–20)
- Secondary: "Number N of 20"

**Dartboard:** Full board shown; current number's entire wedge highlighted in `primary`. In `doublesOnly` variant, only the double ring of the current number is highlighted; the single and triple rings for that number are shown at 60% opacity.

**Input bar — 3-cell contiguous row:**

A single-row flush tile grid of 3 equal-width cells spanning the full screen width (edge-to-edge, no horizontal margin — visually distinct from content cards above it). Parent container: `radiusNone` (flat bar). Minimum cell height: 56dp. Cells have no explicit border — tonal background differences between cell types provide separation.

```
│ S-N │ D-N │ T-N │
```

- S-N: `surfaceContainerLow` background, `onSurface` text, no dots.
- D-N: `primaryContainer` background, `onPrimaryFixed` text, 2 × 4dp dot indicators.
- T-N: `primary` background, `onPrimary` text, 3 × 4dp dot indicators.

In `doublesOnly` variant, `S-N` and `T-N` are visually dimmed: foreground at 38% opacity. Background remains full opacity. Cells stay tappable; the engine will not advance the target on a hit (only the double registers a hit and advances the target). The bottom bar provides the MISS button.

**Bottom bar right action:** `NEXT ROUND` — enabled only when `dartsThrownInTurn == 3`.

**Completion:** drill ends when the target would advance past 20. Show a winner modal with final stats and a "NEW DRILL" button that navigates to Home.

---

### 7b. Bob's 27

**AppBar subtitle:** "Target: D{N}"

**Target display:**
- Large: `D{N}` (e.g. "D5")
- Secondary: "Score: {score}" — score starts at 27 and can go negative

**Dartboard:** Doubles-only mode. Only the double ring of the current target number is highlighted; single and triple rings for that number are shown at 40% opacity; all other wedges at 35% opacity.

**Input bar — single contiguous button:**

A single full-width button spanning the screen width (edge-to-edge). Parent container: `radiusNone` (flat bar). Minimum height: 56dp.

```
│ [ Double {N} ] │
```

- Button: `primaryContainer` background, `onPrimaryFixed` text, 2 × 4dp dot indicators. Label: "Double {N}" (or "Double Bull" for Round 21).
- Tapping records a **Hit** (+2 × N points, or +50 for Bull).
- To record a **Miss**, use the MISS button in the bottom bar.

**Bottom bar right action:** `NEXT ROUND` — enabled only when `dartsThrownInTurn == 3`. However, the turn advances automatically after the 3rd input is registered.

**Bottom bar left action:** `MISS` — records a **single** missed dart (0 score). To record multiple misses, tap multiple times.

**Early end:** if score ≤ 0 after any round, the drill ends immediately. A bust modal shows the round reached and the final score, with a "NEW DRILL" button.

**Completion after Round 21 (Bull):** show a winner modal with final score and "NEW DRILL" → Home.

---

### 7c. Catch-40

**AppBar subtitle:** "Target: {target} · {dartsUsed}/6 darts"

**Target display:**
- Large: "{target}" (61–100)
- Secondary: "Score: {totalScore} | Max: 120"

**Dartboard:** No specific number is highlighted. Full board shown at normal opacity. Player calculates their own checkout route.

**Input grid — full segment grid (matching X01 board):**

```
[ MISS ]  [ SB ]  [ DB ]           ← row 0
[ 20 ][ 19 ][ 18 ][ 17 ][ 16 ][ 15 ][ 14 ][ 13 ][ 12 ][ 11 ]  ← row 1 (singles 20→11)
[ 10 ][  9 ][  8 ][  7 ][  6 ][  5 ][  4 ][  3 ][  2 ][  1 ]  ← row 2 (singles 10→1)
[ 20 ][ 19 ][ 18 ][ 17 ][ 16 ][ 15 ][ 14 ][ 13 ][ 12 ][ 11 ]  ← row 3 (doubles, ·· )
[ 10 ][  9 ][  8 ][  7 ][  6 ][  5 ][  4 ][  3 ][  2 ][  1 ]  ← row 4 (doubles, ·· )
[ 20 ][ 19 ][ 18 ][ 17 ][ 16 ][ 15 ][ 14 ][ 13 ][ 12 ][ 11 ]  ← row 5 (triples, ···)
[ 10 ][  9 ][  8 ][  7 ][  6 ][  5 ][  4 ][  3 ][  2 ][  1 ]  ← row 6 (triples, ···)
```

The full 7-row segment grid in this game type follows the identical contiguous-tile spec as the X01 Board (Section 5). All geometry, color tokens, dot indicators, tonal tier separation, and semantic labels are the same. Refer to Section 5.

> **Note:** this full-grid layout is the intended design using the contiguous tile spec (Section 5). The current 4-button `PracticeInputButtonsWidget` is a placeholder and must be replaced.

**Bottom bar right action:** `NEXT TARGET` — enabled only when:
-   Current target is checked out (score reduces to 0 via double).
-   OR 6 darts have been thrown for this target (failed attempt).

**Scoring Rules:**
-   Target sequence: 61 → 100 (40 targets).
-   Checkout in 2 darts: **3 points**.
-   Checkout in 3 darts: **2 points**. (Exception: Target 99 in 3 darts = **3 points**).
-   Checkout in 4–6 darts: **1 point**.
-   Failed checkout (after 6 darts or bust): **0 points**.

**Completion:** after target 100, show a summary modal with total score (max 120) and "NEW DRILL" → Home.

---

### 7d. Shanghai

**AppBar subtitle:** "Round N / {total}" (where total is 7, 10, 15, or 20)

**Target display:**
- Large: current round number (e.g. "3")
- Secondary: "Score: {score} | Round N/{total}"

**Dartboard:** Full board; current round number's entire wedge highlighted in `primary`.

**Input bar — 3-cell contiguous row:**

A single-row flush tile grid of 3 equal-width cells spanning the full screen width (edge-to-edge, no horizontal margin). Parent container: `radiusNone` (flat bar). Minimum cell height: 56dp. Cells have no explicit border — tonal background differences between cell types provide separation.

```
│ S-N │ D-N │ T-N │
```

- S-N: `surfaceContainerLow` background, `onSurface` text, no dots.
- D-N: `primaryContainer` background, `onPrimaryFixed` text, 2 × 4dp dot indicators.
- T-N: `primary` background, `onPrimary` text, 3 × 4dp dot indicators.

Only the current round number is shown (N = current round). MISS is in the bottom bar.

**Bottom bar right action:** `NEXT ROUND` — enabled only when `dartsThrownInTurn == 3`.

**Shanghai (Instant Win):** if S-N, D-N, and T-N are all hit in the same turn (in any order), the game is an **INSTANT WIN**. A "SHANGHAI!" banner flashes briefly (300ms scale-in, 1s visible) before showing the Game Summary modal (Winner state). Banner color: `primary` text on `primaryContainer` background.

**Completion:** Game ends when (a) the final round is completed, OR (b) a Shanghai is hit. Show a summary modal with total score and "Game Won" status if applicable.

---

## 8. Player List Page (`/players`)

**File:** `lib/features/players/presentation/pages/player_list_page.dart`

### Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "Players"  [+]    │
├─────────────────────────────┤
│  Scrollable player list     │
│   [Avatar] ALICE            │
│             3-dart avg 54.3 │
│   [Avatar] BOB              │
│             3-dart avg 41.0 │
│   …                         │
└─────────────────────────────┘
```

### Typography
- AppBar title: `textHeadingMedium`
- Player name: `textPlayerName` (ALL CAPS)
- Stat subtitle: `textBodySmall`, `onSurfaceVariant`

### Color Usage
- Player row: `surfaceContainerLow` background
- Avatar background: `surfaceContainerHighest`; initials: `onSurface`
- [+] FAB / AppBar icon: `primary`

### Special Notes
- Each row is minimum 64dp tall.
- Tap a row → navigates to PlayerDetailPage.
- Empty state: large icon + "No players yet. Tap + to add your first player."

---

## 9. Player Detail Page (`/players/:playerId`)

**File:** `lib/features/players/presentation/pages/player_detail_page.dart`

### Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "ALICE"       [🗑] │  ← only delete; no edit icon
├─────────────────────────────┤
│  Hero avatar (80dp)         │
│  [Avatar]                   │
│                             │
│  [  ALICE  ] ← inline editable name field
│                             │
├─────────────────────────────┤
│  Stat summary cards (2-col) │
│   [Games Played: 42]        │
│   [Win Rate:    62%]        │
│   [Darts Thrown: 1 204]     │
├─────────────────────────────┤
│  [VIEW STATISTICS]          │
│  [VIEW GAME HISTORY]        │
└─────────────────────────────┘
```

### Typography
- Player name: `textDisplayLarge` (32sp Space Grotesk Bold) — rendered as inline editable field
- Stat card value: `textScoreSmall` (36sp Space Grotesk Bold), `primary`
- Stat card label: `textLabelMedium`, `onSurfaceVariant`

### Color Usage
- Hero avatar: 80dp circular, `surfaceContainerHighest` background
- Stat cards: `surfaceContainerLow`, `radiusNone`, ambient shadow only
- Delete icon (🗑): `colorError` tint
- "VIEW STATISTICS" button: `primary` filled

### Special Notes
- **Remove "Member since"** — not shown.
- **Inline name editing:** The name below the avatar renders as a tappable `TextFormField` (or `InlineEditableText`). Tapping activates editing; pressing Return / tapping away saves (calls `updatePlayerName`). The AppBar title updates to match. Validation: same rules as Create Player (non-empty, unique, max 24 chars).
- **Avatar** auto-updates its initials as the name changes (same as Create Player page). No separate avatar color picker at this stage — avatar is initials-based only.
- **No edit (✏) icon in AppBar** — editing is done inline. Delete (🗑) icon remains.
- **Stat cards show game-type-agnostic metrics only:** Games Played, Win Rate, Darts Thrown. X01-specific metrics (3-dart avg, Checkout %) are not shown here.
- **"VIEW STATISTICS" button** (not "VIEW CAREER STATS") navigates to the player's stats page.
- Delete action shows a confirmation dialog: "Delete ALICE? This cannot be undone." with destructive confirm in `colorError`.

---

## 10. Create Player Page (`/players/add`)

**File:** `lib/features/players/presentation/pages/create_player_page.dart`

### Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "New Player"       │
├─────────────────────────────┤
│  Avatar preview (60dp)      │
│  [      Name field      ]   │
│                             │
│  [CREATE PLAYER]            │
└─────────────────────────────┘
```

### Typography
- AppBar title: `textHeadingMedium`
- Name field label: `textBodyMedium`, `onSurfaceVariant`
- Name field input: `textBodyLarge`
- Button: `textLabelLarge`

### Color Usage
- Input focused: 2dp bottom-bar in `primary`, expands from center on focus (per DESIGN_SYSTEM §6.2)
- Input unfocused: no visible border — tonal background (`surfaceContainerLow`) only
- Avatar preview: `surfaceContainerHighest` background, initials update as user types

### Special Notes
- "CREATE PLAYER" button disabled until name is non-empty and unique.
- Max name length: 24 characters. Character counter shown at 80% of limit.

---

## 12. Stats Root Page (`/stats`)

> **Deferred.** The `/stats` root entry point (reached from the Home Statistics card) is not yet specified. Its design depends on the leaderboard plan (Section 13). For now, navigating to `/stats` may redirect directly to a player-selection screen or show a placeholder. This section will be filled in when the leaderboard is planned.

---

## 13. Leaderboard Page (`/stats/leaderboard`)

> **Deferred.** The leaderboard is out of scope for the current iteration. The route `/stats/leaderboard` is reserved. This section will be fully specified when leaderboard design is planned.

---

## 14. Player Statistics Page (`/stats/player/:playerId`)

**File:** `lib/features/statistics/presentation/pages/player_stats_page.dart`

Per-player statistics page with in-page navigation across game types. Reached from PlayerDetailPage via the "VIEW STATISTICS" button.

### Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "ALICE — Stats" [←]│
├─────────────────────────────┤
│  [X01] [Cricket] [Practice] │  ← game-type tab bar
│        [Others]             │
├─────────────────────────────┤
│  Tab content (X01 shown)    │
│  ┌──────┐ ┌──────┐ ┌──────┐ │
│  │ Legs │ │ Legs │ │Solo  │ │  ← 3 summary cards
│  │Played│ │  Won │ │Games │ │
│  │  142 │ │  89  │ │  12  │ │
│  └──────┘ └──────┘ └──────┘ │
├─────────────────────────────┤
│  [All X01▾][501][301][...] │  ← variant chip selector
├─────────────────────────────┤
│  [Last 10] [Last 100] [All] │  ← time range segmented button
├─────────────────────────────┤
│  PPR trend (line chart)     │  ← sparkline / chart, fills width
│  ┌─────────────────────────┐│
│  │     ~54.3               ││
│  │  ╭──╮     ╭──╮          ││
│  │ ╭╯  ╰─╮  ╭╯  ╰─╮       ││
│  │─╯     ╰──╯      ╰──     ││
│  └─────────────────────────┘│
│  [📊 Overlay: Checkout %]   │  ← toggle chip to add CO% line
├─────────────────────────────┤
│  Detail table               │
│  Metric          │  Value   │
│  ─────────────────────────  │
│  PPR             │  54.3    │
│  First 9 PPR     │  64.1    │
│  Checkout %      │  32%     │
│  Highest checkout│  121     │
│  Win %           │  62%     │
│  60+ (total/leg) │ 145/4.2  │
│  100+(total/leg) │  43/1.2  │
│  140+(total/leg) │   8/0.2  │
│  180 (total/leg) │   2/0.06 │
└─────────────────────────────┘
```

### Game-Type Tab Bar
- Tabs: **X01**, **Cricket**, **Practice**, **Others**
- Tab indicator: `primary` underline, 2dp
- Active tab label: `primary`, `textLabelLarge`
- Inactive tab label: `onSurfaceVariant`, `textLabelLarge`
- Practice tab: Around the Clock variant is fully specified (see Practice Tab section below). All other practice variants show a "coming soon" placeholder.
- Others tab shows a "coming soon" placeholder (same desaturated treatment as Home coming-soon cards) at this stage.

### Summary Cards Row
- 3 cards in a single horizontal row, equal width, `surfaceContainerLow`, `radiusNone`, ambient shadow only
- **X01 cards:** Legs Played | Legs Won | Solo Games
  - "Solo Games" = number of distinct completed games (not legs — legs are sub-units of a game)
- Card value: `textScoreSmall` (36sp Space Grotesk Bold), `primary`
- Card label: `textLabelMedium`, `onSurfaceVariant`

### Variant Selector (X01 tab only)
- Horizontal scrollable chip row below the summary cards
- First chip: **"All X01"** (default selected)
- Additional chips: one per distinct starting score seen in the player's data (e.g. **"501"**, **"301"**)
- Selected chip: `primaryContainer` background, `onPrimaryFixed` text
- Unselected chip: `surfaceContainerHighest` background, `onSurfaceVariant` text
- Variant selection filters both the trend chart and the detail table
- Hidden on tabs without variants (Cricket, Others)
- **Practice tab has its own variant selector** — see Practice Tab section below

### Time Range Selector
- `SegmentedButton` with 3 options: **Last 10**, **Last 100**, **All**
- Default: **All**
- Applies to both the trend chart and the detail table
- `primary` selected segment fill

### Trend Chart
- Full-width line chart, minimum 160dp height
- X axis: game/leg index (oldest → newest, left → right)
- Y axis: PPR value; auto-scales to data range with a comfortable margin
- Line color: `primary`; filled area below line: `primaryContainer` at 30% opacity
- Chart background: `surfaceContainerLow`, `radiusNone`
- **Overlay toggle chip** below chart: "Checkout %" — when toggled on, a second line in `primaryFixedDim` is overlaid. The Y axis remains the same scale (CO% is rendered as a 0–100 value on the same axis; its secondary line label clarifies the scale)
- Tapping a data point shows a tooltip: PPR value (and CO% if overlay active) + game date
- Empty state (fewer than 2 data points): left-aligned "Not enough data yet" text, `textBodyMedium`, `onSurfaceVariant`

### Detail Table
- Two-column table: **Metric** (left, `textBodyMedium`, `onSurface`) | **Value** (right, `textBodyMedium`, `primary`)
- Rows (in order):

| Metric | Notes |
|--------|-------|
| PPR | Points Per Round (3-dart average) over selected range |
| First 9 PPR | Average of first 3 turns per leg only |
| Checkout % | Successful double-out attempts / total checkout attempts |
| Highest checkout | Best single checkout score in range |
| Win % | Legs won / legs played (as %) |
| 60+ (total / per leg) | Turns scoring 60–99 — total count and count÷legs |
| 100+ (total / per leg) | Turns scoring 100–139 |
| 140+ (total / per leg) | Turns scoring 140–179 |
| 180 (total / per leg) | Perfect turns |

- Alternating row tint: even rows `surfaceContainerLow`, odd rows `surface`
- "total / per leg" cells render as `"42 / 1.2"` inline
- Table scrolls as part of the overall page — it is not independently scrollable

### Cricket Tab

#### Summary Cards Row
- Same 3-card layout as X01: **Legs Played | Legs Won | Solo Games**
- Card value: `textScoreSmall` (36sp Space Grotesk Bold), `primary`
- Card label: `textLabelMedium`, `onSurfaceVariant`

#### Variant Selector (Cricket tab)
- Horizontal scrollable chip row below the summary cards
- Chips: **All Cricket** (default), **Standard**, **No Score**, **Cut Throat**, **Tactics**
- Selected chip: `primaryContainer` background, `onPrimaryFixed` text
- Unselected chip: `surfaceContainerHighest` background, `onSurfaceVariant` text
- Filters both the trend chart and the detail table

#### Trend Chart
- Same visual spec as X01 PPR chart, but Y-axis plots **MPT** (Marks Per Turn)
- Line color: `primary`; fill: `primaryContainer` at 30% opacity
- Tooltip: MPT value + game date
- Empty state: "Not enough data yet" (fewer than 2 data points)
- No overlay toggle (no second metric for cricket)

#### Detail Table (3-column layout — AVERAGE | BEST)

Column layout (same as X01):
- Label column: `Expanded`, `textBodyMedium`, `onSurface`
- Col 1 (average/total): fixed 80px, `textBodyMedium`, `primary`, right-aligned
- Col 2 (best/per-leg): fixed 80px, `textBodyMedium`, `primaryFixedDim`, right-aligned
- Header row: `textLabelSmall`, `onSurfaceVariant`, `letterSpacing: 0.8`
- Alternating row tint: even rows `surfaceContainerLow`, odd rows `surface`

Rows:

| Label | AVERAGE col | BEST col |
|-------|-------------|----------|
| **AVERAGE** header | — | **BEST** |
| MPT | Career avg MPT | Best single-leg MPT (`bestLegMpt`) |
| Hit rate | Career avg hit rate (%) | Best single-game hit rate (%) (`bestGameHitRate`) |
| Win % | Career win % | `—` |
| **TOTAL** header | — | **PER LEG** |
| 6+ mark turns | Total count | count ÷ legsPlayed (1 decimal) |
| 9 mark turns | Total count | count ÷ legsPlayed (1 decimal) |

Metric field sources in `PlayerStats`:
- `bestLegMpt` — best MPT in any single completed leg (null when no data)
- `bestGameHitRate` — best hit rate (0.0–1.0) in any single completed game (null when no data)
- Win % BEST column always renders `"—"` (no meaningful single-game best)

### Typography
- AppBar title: `textHeadingMedium`
- Summary card value: `textScoreSmall` (36sp Space Grotesk Bold), `primary`
- Summary card label: `textLabelMedium`, `onSurfaceVariant`
- Table metric label: `textBodyMedium`, `onSurface`
- Table value: `textBodyMedium`, `primary`
- Section dividers (if added): `textLabelSmall`, `onSurfaceVariant`, ALL CAPS

### Color Usage
- Summary cards: `surfaceContainerLow`, `radiusNone`, ambient shadow only
- Chart line: `primary`; chart area fill: `primaryContainer` 30% opacity
- Checkout % overlay line: `primaryFixedDim`
- Variant chips (selected): `primaryContainer` / `onPrimaryFixed`
- Variant chips (unselected): `surfaceContainerHighest` / `onSurfaceVariant`
- Time range selected segment: `primary` fill
- Table alternating rows: `surfaceContainerLow` / `surface`
- Coming-soon tab placeholder: `surfaceContainerHighest` background, `onSurfaceVariant` text + icon, `opacity: 0.6`

### Special Notes
- **Cricket tab is implemented** — see Cricket Tab section below.
- **Practice tab — Around the Clock** is fully specified — see Practice Tab section below. All other practice variants remain stubbed.
- **Others tab is stubbed:** shows a left-aligned "Stats for [game type] coming soon" placeholder. No summary cards, no chart, no table.
- **Variant selector** appears on the X01 tab, the Cricket tab, and the Practice tab. Hidden on the Others tab.
- **Time range** applies across the entire tab (chart + table). Switching range recomputes all displayed metrics.
- **No leaderboard** on this page. Strictly per-player, per-game-type stats.
- **Projection data dependency:** The trend chart requires time-series PPR data per leg/game. The current `PlayerStats` entity is a flat aggregate and does not carry time-series data. A new data structure (list of per-game snapshots) will be needed in `StatisticsRepository` and `PlayerStats`. This is flagged for the implementation ticket.
- **Route rename:** The previous route was `/stats/career/:playerId`. This spec uses `/stats/player/:playerId`. Implementation must update the router accordingly.

### Practice Tab

#### Variant Selector

- Horizontal scrollable chip row below the summary cards (same chip-row pattern as X01/Cricket)
- Chips (in order): **All Practice** (default selected), **Around the Clock**, **Bob's 27**, **Catch-40**, **Checkout Practice**, **Shanghai**
- Selected chip: `primaryContainer` background, `onPrimaryFixed` text
- Unselected chip: `surfaceContainerHighest` background, `onSurfaceVariant` text
- Hidden when the player has no practice data at all
- Selecting a chip filters the view to that practice variant only

#### Practice Tab — Non-ATC Variants (Stubbed)

All variants except **Around the Clock** show the coming-soon placeholder:
- Left-aligned `"Stats for [variant name] coming soon"` text
- `textBodyMedium`, `onSurfaceVariant`, `opacity: 0.6`
- `surfaceContainerHighest` background card, `radiusNone`

#### Practice Tab — Around the Clock Stats View

Shown when **Around the Clock** chip is selected (or when **All Practice** is selected and the player has ATC data).

**Time range selector:** `SegmentedButton` — **Last 10** | **Last 100** | **All** (default). "10/100" counts completed ATC sessions, not individual turns.

**Layout:**

```
┌─────────────────────────────────────────────────────────┐
│  [All Practice▾][ATC][Bob's 27][Catch-40][Checkout][...] │  ← variant chip row
├─────────────────────────────────────────────────────────┤
│  [Last 10] [Last 100] [All]                              │  ← time range
├─────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────┐  ┌─────────────────┐  │
│  │                               │  │ OVERALL         │  │
│  │   Annotated dartboard         │  │   72%           │  │
│  │   (hit rate % on each wedge)  │  ├─────────────────┤  │
│  │                               │  │ BEST            │  │
│  │                               │  │  20  94%        │  │
│  │                               │  │  19  91%        │  │
│  │                               │  │  18  88%        │  │
│  │                               │  ├─────────────────┤  │
│  │                               │  │ WEAKEST         │  │
│  │                               │  │   3  41%        │  │
│  │                               │  │   7  44%        │  │
│  │                               │  │  14  48%        │  │
│  └───────────────────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Layout proportions:**
- Dartboard container: **4/5** of horizontal space (`flex: 4`)
- Summary column: **1/5** of horizontal space (`flex: 1`)
- Both containers share the same height (intrinsic height of the dartboard)
- Minimum height of the combined row: board natural height (square aspect ratio filling 4/5 width)

---

##### Annotated Dartboard

- Full circular dartboard rendered at normal opacity using the same read-only dartboard component used elsewhere in the app (all interactive tap zones disabled)
- Each numbered wedge (1–20) shows its hit rate percentage at the **outer tip** of the wedge, just outside the board boundary
  - Text style: `textLabelSmall` (11sp Inter Regular), `onSurface`
  - Format: `"72%"` (no decimal places)
  - Segments with 0 attempts: render `"—"` instead of a percentage
- **Bull position:** hit rate shown as a centered label overlaid inside the bull circle (exception: concentric circular element — center-alignment is geometric, not editorial)
  - Format: `"DB 72%"` (prefix `"DB"` identifies the doubles bull / bullseye)
  - Covers inner bull (bullseye, 50-point ring) hit rate only
  - Text style: `textLabelSmall`, `onSurface`
- **Segment colours are not changed** — the dartboard uses standard alternating black/white wedge colours; hit rate labels use `onSurface` regardless of rate
- In `doublesOnly` variant: only `D1`–`D20` and `DB` are tracked; single and triple ring labels show `"—"`
- Hit rate percentages on the board update when the time range selection changes

---

##### Summary Column (1/5 width)

Single-column card (`surfaceContainerLow`, `radiusNone`, ambient shadow only) divided into three sections separated by `spacing.8` (1.75rem) vertical padding — no hairlines.

**Section 1 — Overall Hit Rate**
- Header label: `"OVERALL"`, `textLabelSmall`, `onSurfaceVariant`, ALL CAPS
- Value: overall hit rate as `"72%"`, `textScoreSmall` (36sp Space Grotesk Bold), `primary`
- Definition: total targets hit ÷ total darts thrown across all numbers in the selected range

**Section 2 — Best 3**
- Header: `"BEST"`, `textLabelSmall`, `onSurfaceVariant`, ALL CAPS
- 3 rows, sorted by hit rate descending; ties broken by segment number ascending
- Only segments with ≥ 1 attempt are eligible
- Each row:
  - Segment label (e.g. `"20"`, `"Bull"`): `textBodyMedium`, `primary` (`#006C46` — dark green signals positive/success)
  - Hit rate: e.g. `"94%"`, `textBodyMedium`, `onSurface`
  - Layout: segment label left-aligned, hit rate right-aligned within column width

**Section 3 — Weakest 3**
- Header: `"WEAKEST"`, `textLabelSmall`, `onSurfaceVariant`, ALL CAPS
- 3 rows, sorted by hit rate ascending; ties broken by segment number ascending
- Only segments with ≥ 1 attempt are eligible
- Each row:
  - Segment label: `textBodyMedium`, `colorError` (`#D32F2F`)
  - Hit rate: e.g. `"41%"`, `textBodyMedium`, `onSurface`
  - Layout: segment label left-aligned, hit rate right-aligned

**Segment label mapping for the summary column:**

| Game segment | Display label |
|---|---|
| Numbers 1–20 | `"1"` – `"20"` |
| Bull (DB / inner bull) | `"Bull"` |

In `doublesOnly` variant, Best/Weakest rows show only the double segments that were attempted.

**Edge cases:**
- Fewer than 3 attempted segments: show only the available rows (no placeholder dashes)
- No data at all: show `"—"` for the Overall value; Best and Weakest sections show `"No data yet"` in `textBodySmall`, `onSurfaceVariant`

---

##### Typography & Color Summary (ATC Stats View)

| Element | Style token | Color token |
|---|---|---|
| Hit rate label on dartboard wedge | `textLabelSmall` | `onSurface` |
| Overall hit rate value | `textScoreSmall` | `primary` |
| Section headers (OVERALL / BEST / WEAKEST) | `textLabelSmall` | `onSurfaceVariant` |
| Segment label — Best rows | `textBodyMedium` | `primary` |
| Segment label — Weakest rows | `textBodyMedium` | `colorError` |
| Hit rate value in Best/Weakest rows | `textBodyMedium` | `onSurface` |

---

##### ATC Variant Pooling

- By default (**All Practice** chip selected): ATC data from both `standard` and `doublesOnly` sub-variants is pooled together.
- When **Around the Clock** chip is selected: still pools both ATC sub-variants. A sub-variant chip row is **not** added at this stage.
- The `doublesOnly` display rule (single and triple rings show `"—"`) applies only when the player exclusively has `doublesOnly` data.

---

## 15. Post-Game Summary Page (`/post-game/:gameId`)

**File:** `lib/features/statistics/presentation/pages/post_game_summary_page.dart`

### Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "Game Summary"     │
│          (no back button)   │
├─────────────────────────────┤
│  ┌──────────────────────┐   │
│  │ 🏆 ALICE  WINNER     │   │  ← winner card (elevated)
│  │  Avg: 72.3  Darts: 43│   │
│  └──────────────────────┘   │
│  ┌──────────────────────┐   │
│  │  BOB                 │   │
│  │  Avg: 54.1  Darts: – │   │
│  └──────────────────────┘   │
├─────────────────────────────┤
│  [PLAY AGAIN] [DONE]        │
└─────────────────────────────┘
```

### Typography
- Winner name: `textDisplayLarge` (32sp), `colorWin`
- "WINNER" badge: `textLabelLarge`, `onPrimary` on `colorWin` chip
- Stat label: `textBodySmall`, `onSurfaceVariant`
- Stat value: `textHeadingMedium` (20sp Inter SemiBold)

### Color Usage
- Winner card: `colorWinContainer` background, 4dp `colorWin` left accent bar (semantic exception — same pattern as active player panel; not a divider)
- Loser card: `surfaceContainerLow`
- "PLAY AGAIN": `primary` filled
- "DONE": outlined style

### Special Notes
- AppBar has no back button (`automaticallyImplyLeading: false`) — routing is explicit.
- The winner card has an animated checkmark icon entrance (300ms scale in) when the page first appears.
- Amp up the winner presentation: large trophy icon in `colorWin`, winner name in `textDisplayLarge`.

---

## 16. History Page (`/history`)

**File:** `lib/features/history/presentation/pages/history_page.dart`

### Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "History"          │
├─────────────────────────────┤
│  Filter bar                 │
│  [All▾] [Date range▾] [✕]  │
├─────────────────────────────┤
│  Scrollable game list       │
│   ┌──────────────────────┐  │
│   │ X01 · 501            │  │
│   │ ALICE won · 3 legs   │  │
│   │ Mar 8 · 43 darts     │  │
│   └──────────────────────┘  │
│   (repeat, pagination)      │
└─────────────────────────────┘
```

### Typography
- AppBar title: `textHeadingMedium`
- Game type chip in card: `textLabelMedium`
- Winner line: `textBodyLarge`, `onSurface` — bold winner name
- Metadata (date, dart count): `textBodySmall`, `onSurfaceVariant`

### Color Usage
- Filter chips: `primaryContainer` (active), `surfaceContainerHighest` (inactive)
- Game card: `surfaceContainerLow`, `radiusNone`, ambient shadow only
- Game type label chip: `surfaceContainerHighest` background

### Special Notes
- Navigated to from the Home page via the History card. Back button returns to Home.
- Infinite scroll: `loadNextPage()` fires when within 200px of bottom. Loading indicator: `CircularProgressIndicator` in `primary` centered below last item.
- Empty state: centered icon + "No completed games yet." text.
- Shimmer skeleton placeholders on initial load (3 placeholder cards in `surfaceContainerHighest`).

---

## 17. Game Detail Page (`/game/history/:gameId`)

**File:** `lib/features/history/presentation/pages/game_detail_page.dart`

### Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "X01 · 501"  [←] │
├─────────────────────────────┤
│  Result header              │
│  ALICE won · 43 darts       │
│  Mar 8, 2026                │
├─────────────────────────────┤
│  Per-player stats cards     │
│   [Avg] [High checkout]     │
│   [Legs] [Darts thrown]     │
├─────────────────────────────┤
│  Leg breakdown table        │
│   Leg 1: ALICE 25 darts     │
│   Leg 2: BOB   31 darts     │
│   …                         │
└─────────────────────────────┘
```

### Typography
- Result header winner: `textHeadingLarge` (24sp), `colorWin`
- Date: `textBodySmall`, `onSurfaceVariant`
- Stat values: `textScoreSmall` (36sp Space Grotesk Bold), `onSurface`
- Leg table header: `textLabelMedium`, `onSurfaceVariant`
- Leg table rows: `textBodyMedium`

### Color Usage
- Result header background: `surfaceContainerLow`
- Winning player row in leg table: `primaryContainer` at 20% opacity background tint

---

## 18. Settings Page (`/settings`)

**File:** `lib/features/settings/presentation/pages/settings_page.dart`

### Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "Settings"         │
├─────────────────────────────┤
│  Theme section              │
│   [Dark Mode] toggle        │
│   [System default] option   │
│                             │
│  About section              │
│   [Version] …               │
│   [Open Source Licenses]    │
└─────────────────────────────┘
```

### Typography
- Section headers: `textLabelMedium`, `onSurfaceVariant`, ALL CAPS with `space2` (8dp) top + `space1` (4dp) bottom padding
- Setting label: `textBodyLarge`, `onSurface`
- Setting description: `textBodySmall`, `onSurfaceVariant`

### Color Usage
- Toggle active state: `primary` track
- Toggle inactive: `outlineVariant` track
- Section headers: no background, just typography treatment

### Special Notes
- Accessed via the gear icon (⚙) in the Home AppBar only. Back button returns to Home.
- Dark mode toggle respects `ThemeMode.system` as the default state.
- "Open Source Licenses" navigates to Flutter's built-in `LicensePage`.

---

## Cross-Screen Patterns

### Loading States

| Context | Pattern |
|---|---|
| Full page initial load | Centered `CircularProgressIndicator` in `primary` on `surface` |
| List initial load | 3 shimmer skeleton cards in `surfaceContainerHighest`, `radiusNone` |
| List pagination | Small `CircularProgressIndicator` centered below last item |
| Button async action | Inline `SizedBox(20×20)` `CircularProgressIndicator(strokeWidth: 2)` replaces button text |

### Error States

| Context | Pattern |
|---|---|
| Full page error | Centered `error_outline` icon (48dp) + error message text + "Retry" `TextButton` in `primary` |
| Snackbar (transient) | `colorErrorContainer` background, `colorOnErrorContainer` text, auto-dismiss 4s |
| Validation error (inline) | Field border turns `colorError`; helper text below in `colorError`, `textBodySmall` |

### Empty States

All empty states use:
- Left-aligned layout
- Large icon (64dp) in `onSurfaceVariant` at 60% opacity
- Primary message: `textBodyLarge`, `onSurface`
- Secondary message / CTA: `textBodyMedium`, `onSurfaceVariant`
- When there is a creation CTA, use a `FilledButton` in `primary`

### Dialogs

All confirmation dialogs:
- Title: `textHeadingSmall`
- Body: `textBodyMedium`
- Cancel button: `TextButton`, `onSurface`
- Confirm button: `FilledButton`, `primary` for neutral; `colorError` filled for destructive actions
- Corner radius: `radiusNone`
- Minimum dialog width: `min(screen_width - 48dp, 320dp)`
