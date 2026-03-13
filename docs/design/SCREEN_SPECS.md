# Screen Design Specifications — my-darts

**Theme:** Court Ready
**Last updated:** 2026-03-11
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
│  |▌ X01               →    │  ← left accent bar, colorPrimary
│  |▌ Cricket           →    │  ← colorSecondary
│  |▌ Practice          →    │  ← colorOnPrimaryContainer
│  |▌ Statistics        →    │  ← colorSecondary (same as Cricket)
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
- AppBar title: `textHeadingMedium`, `colorOnBackground`
- Game list item label: `textBodyLarge`, `colorOnBackground`
- Game list item subtitle: `textBodySmall`, `colorOnSurfaceVariant`
- "PLAY" section label: `textLabelSmall`, `colorOnSurfaceVariant`, uppercase
- History / Local Players nav card label: `textBodyLarge`, `colorOnBackground`

### Color Usage
- All game list cards: `colorSurface` background, `colorOutline` border (1dp), `radiusLarge` corner radius
- X01 left accent bar: `colorPrimary` (4dp)
- Cricket left accent bar: `colorSecondary` (4dp)
- Practice left accent bar: `colorOnPrimaryContainer` (4dp, dark red — the deep token from that container pair)
- Statistics left accent bar: `colorSecondary` (4dp)
- Chevron per card: matches the card's accent color
- History / Local Players nav cards: `colorSurface` background, `colorOutline` border
- Coming-soon cards: `colorSurfaceVariant` background, `colorOnSurfaceVariant` text, `opacity: 0.6`

### Special Notes
- The gear icon (⚙) in the AppBar navigates to Settings. Settings is not a card.
- The game list is a single-column vertical stack of full-width cards with `radiusLarge` corners and `64dp` minimum height.
- Each card has a 4dp left accent bar using the color tokens above; label is left-aligned; trailing chevron matches accent color.
- Optionally a subtitle line (`textBodySmall`, `colorOnSurfaceVariant`) can be shown — reserved for future use.
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
- Variant name: `textBodyLarge`, `colorOnBackground`
- Variant subtitle: `textBodyMedium`, `colorOnSurfaceVariant` (adapts to `colorOnPrimary` / `colorOnPrimaryContainer` on filled/selected pills)
- Hint line: `textBodySmall`, `colorOnSurfaceVariant`, centred

### Color Usage
- Selected variant card: `colorPrimaryContainer` background, `colorOnPrimaryContainer` text, left border 3dp `colorPrimary`
- Unselected card: `colorSurface`

### Special Notes
- Variants are tappable list tiles, minimum 64dp height.
- A single tap navigates directly to player selection with the variant pre-selected — no confirm button needed.
- Each variant card displays a **subtitle** (`textBodyMedium`, `colorOnSurfaceVariant`) summarising its default rules:
  - X01 presets: `"Double Out · 1 Leg"` (substituting the actual leg count for multi-leg presets)
  - Cricket presets: describe the variant rule and scoring threshold, e.g. `"Close 15–20 & Bull · 3 pts to win"` for Standard Cricket
  - Practice variants: **no subtitle** — the game name is self-describing and there are no configurable fields
  - Disabled Custom entry: **no subtitle**
- A **hint line** is rendered below the pill list in all categories:
  `"Select a preset — you can adjust the settings on the next screen"`
  Styled `textBodySmall`, `colorOnSurfaceVariant`, centred, with `space4` (16 dp) top padding.

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
- Config summary chip text: `textBodyMedium`, `colorOnBackground`
- Config summary chip edit icon: `colorPrimary`, 16 dp
- Selected player name: `textPlayerName` (ALL CAPS)
- Roster grid name: `textLabelSmall`, `colorOnBackground`, max 1 line, ellipsis overflow
- "START GAME" button: `textLabelLarge`, `colorOnPrimary`
- Modal title: `textHeadingSmall`

### Color Usage
- Config summary chip: `colorSurface` background, `colorOutline` border 1 dp, `radiusMedium` corner radius (12 dp); `colorPrimary` trailing edit icon
- Selected player area: `colorBackground`
- Roster grid container: `colorSurface` background, `colorOutline` border, `radiusMedium`
- Roster grid avatar (real player): `colorSecondaryContainer` background,
  `colorOnSecondaryContainer` initials
- Roster grid "+" card: `colorSurfaceVariant` background, `colorPrimary` "+" icon
- "START GAME" button disabled: 38% opacity when no players selected

### Special Notes
- **Config summary chip** sits immediately below the AppBar as a full-width tappable row:

  ```
  ┌──────────────────────────────────────────┐
  │  501 · Double Out · 1 Leg             ✏  │
  └──────────────────────────────────────────┘
  ```

  - Background `colorSurface`; border 1 dp `colorOutline`; corner radius `radiusMedium` (12 dp); padding 12 dp horizontal, 10 dp vertical.
  - Left text: config summary string (`textBodyMedium`, `colorOnBackground`).
  - Right icon: `edit_outlined` in `colorPrimary`, 16 dp.
  - Tapping anywhere on the chip opens the Game Config bottom sheet (Section 4).
  - The chip re-renders immediately after settings are applied — it always reflects the current live config.
  - The AppBar on this page carries **no ⚙ settings icon** — the chip is the sole entry point to game config. The ⚙ icon is used exclusively on the Home page (→ Settings).

  **Config summary string format:**

  | Game type | Format |
  |---|---|
  | X01 | `"{score} · {outStrategy} Out · {legsToWin == 1 ? '1 Leg' : 'Best of N'}"` |
  | Cricket | `"{variant} · {N} {N == 1 ? 'pt' : 'pts'} to win"` |
  | Practice | game name only (no configurable fields to surface) |

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
  `colorSecondaryContainer`.
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
│                             │
│  [APPLY SETTINGS]           │
└─────────────────────────────┘
```

### Typography
- Sheet title: `textHeadingMedium`
- Field labels: `textBodyMedium`, `colorOnSurfaceVariant`
- Dropdown values: `textBodyLarge`, `colorOnBackground`
- Apply button: `textLabelLarge`, `colorOnPrimary` on `colorPrimary`

### Color Usage
- Sheet background: `colorSurface`
- Drag handle: `colorOutline`
- Stepper (−/+) buttons: outlined style, `colorPrimary` border + text
- Count value between steppers: `textHeadingMedium`, `colorOnBackground`

### Special Notes
- Opened via the config summary chip on the Player Selection page (Section 3).
- Sheet height: `isScrollControlled: true` with `maxChildSize: 0.75`.
- Stepper buttons minimum 48×48dp touch target.
- All changes are held in local state until "APPLY SETTINGS" is tapped — tapping the drag-handle drag area dismisses without saving.

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
│  │  MISS  │  SB·25│ DB·50 │  │  ← row 0: 3 equal cells, hairlines
│  ├────────────────────────┤  │  ← 1dp colorOutlineVariant group separator
│  │20│19│18│17│16│15│14│13│12│11│  ← row 1 singles (colorSurface)
│  │10│ 9│ 8│ 7│ 6│ 5│ 4│ 3│ 2│ 1│  ← row 2 singles
│  ├────────────────────────┤  │  ← 1dp colorOutlineVariant group separator
│  │20│19│…                 │  │  ← row 3 doubles (colorPrimaryContainer)
│  │ ·· ·· ··               │  │     2-dot indicators below numbers
│  │10│ 9│…                 │  │  ← row 4 doubles
│  ├────────────────────────┤  │  ← 1dp colorOutlineVariant group separator
│  │20│19│…                 │  │  ← row 5 triples (colorPrimary)
│  │···│···│···              │  │     3-dot indicators below numbers
│  │10│ 9│…                 │  │  ← row 6 triples
│  └────────────────────────┘  │
├─────────────────────────────┤
│  [↩ Undo]    [NEXT ROUND]  │
└─────────────────────────────┘
```

### Typography
- AppBar title line 1: `textHeadingSmall`, `colorOnBackground` — starting score
- AppBar title line 2: `textBodySmall`, `colorOnSurfaceVariant` — leg indicator
- Player name: `textPlayerName` (ALL CAPS); active player uses `colorSecondary`, inactive uses `colorOnSurfaceVariant`; truncate with ellipsis if needed
- Active player score: `textScoreActive` — scales with N: 80sp (N=1), 64sp (N=2), 48sp (N=3–4), 36sp (N=5–6)
- Inactive player score: always one step smaller than active in the same game; same scale steps apply
- Round sum prefix (inline before remaining score): `textBodySmall`, `colorOnSurfaceVariant`
- Dart indicator chip label: `textBodyMedium`, `colorOnSurface`; round sum: `textHeadingSmall`, `colorPrimary`
- PPR: `textBodySmall`, `colorOnSurfaceVariant`
- Segment button number: `textSegmentButton` (18sp DM Sans SemiBold)
- "NEXT ROUND" button: `textLabelLarge`
- Checkout banner text: `textBodyMedium`, `colorOnBackground`; 💡 icon in `colorPrimary`

### Color Usage
- Active player panel: `colorActivePlayerBg` background, 4dp left border `colorActivePlayer`
- Active player score: `colorPrimary`
- Inactive player panel: `colorSurface`
- Segment grid outer container: `colorSurface` background, `radiusNone`. Fills full screen width (edge-to-edge).
- Individual cells: `radiusNone`. Each cell draws only its right and bottom 1dp `colorOutline` hairline border.
- Tier boundaries (rows 2→3, rows 4→5): 1dp `colorOutlineVariant` separator (slightly stronger than `colorOutline`).
- Row 0 / rows 1–2 (singles): `colorSurface` background, `colorOnSurface` text.
- Rows 3–4 (doubles): `colorPrimaryContainer` background, `colorOnPrimaryContainer` text, 2 × 4dp filled dot indicators in `colorOnPrimaryContainer`.
- Rows 5–6 (triples): `colorPrimary` background, `colorOnPrimary` text, 3 × 4dp filled dot indicators in `colorOnPrimary`.
- Undo button: icon in `colorOnSurface`; disabled state 38% opacity
- "NEXT ROUND": `colorPrimary` filled button
- Dart indicator chip (thrown): `colorSurface` background, `colorOutline` border
- Dart indicator chip (remaining): outline circle, `colorOutline`
- Checkout banner background: `colorSurfaceVariant`, left border `colorPrimary` (2dp)

### Special Notes
- **Score must never wrap or truncate.** Score panel width must be wide enough for "501" at 80sp. On narrow screens, reduce inactive score to `textScoreMedium` (48sp) before truncating.
- **Dart indicator row** sits between AppBar and scoreboard. Round sum on the left (bold, `colorPrimary`), then up to 3 chips — thrown darts show the segment label (e.g. "T20", "SB", "14"), remaining slots show an empty outline circle. Sum increments as darts land.
- **Segment input grid (contiguous tile layout):** The input area spans the full screen width (edge-to-edge, no horizontal margin). No padding inside the container — cells are flush against each other and against the container walls. No spacing between cells. Parent container: `radiusNone` (flat bar).

  Row 0: MISS / SB / DB — 3 equal-width cells. Rows 1–2: singles 20→11 and 10→1, 10 cells per row. Rows 3–4: doubles, same number order, 10 cells per row. Rows 5–6: triples, same number order, 10 cells per row. Cell heights flex equally across all 7 rows to fill available vertical space; minimum cell height 48dp.

  Cell borders: each cell draws its right and bottom 1dp `colorOutline` hairline only (so shared edges are always 1dp, not 2dp). Tier-boundary rows use `colorOutlineVariant` for the horizontal separator. Ripple is clipped to the individual cell boundary (Material `InkWell` inside `radiusNone` cell).

  Dot indicators are rendered below the number within the cell using the cell's foreground color. No text multiplier label.

  Semantic label per cell: "Single [N]", "Double [N]", "Triple [N]", "Miss", "Single Bull", "Double Bull".
- **Player score panel:** The scoreboard is a single row of N equal-width columns (N = 1–6, enforced by the game config max). Each column contains a vertical stack: (1) round sum prefix + remaining score on one line — the round sum is the total of darts thrown so far this turn, shown in small text to the left of the main score; (2) player name (ALL CAPS, ▶ suffix for active player); (3) PPR, showing '—' until at least one turn is complete. Score font scales with N: 80sp / 64sp / 48sp / 36sp for N = 1 / 2 / 3-4 / 5-6. All columns are always visible; no scrolling or collapsing.
- **Checkout suggestion:** A full-width banner row is inserted between the scoreboard and the input grid whenever the active player's remaining score is ≤ 170. Background `colorSurfaceVariant`, 2dp left border `colorPrimary`, 💡 icon + suggestion string (e.g. "T20 · T18 · D8"). Hidden otherwise — row collapses to zero height.
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
| 64      | 32      | [MISS]  | [UNDO]  |  ← header row
| ALICE   | BOB     |         |         |     score top, name below
| ⊗       | X       | [ 20 ] | [ 20 ] | [ 20 ] |
|         |         |        | [ ·· ] | [ ··· ]|   dots below number (not on a different row, just below number)
| /       | ⊗       | [ 19 ] | [ 19 ] | [ 19 ] |
| X       | X       | [ 18 ] | [ 18 ] | [ 18 ] |
| ─       | /       | [ 17 ] | [ 17 ] | [ 17 ] |
| ─       | ─       | [ 16 ] | [ 16 ] | [ 16 ] |
| ─       | ─       | [ 15 ] | [ 15 ] | [ 15 ] |
| ─       | ─       | [Bull] | [Bull] | (gap)  |   no triple for Bull
──────────────────────────────────────────────────
| (target+marks area — left)   | [NEXT PLAYER]  |  ← footer: input-column width only
```

### Typography
- Dart indicator chip label: `textBodyMedium`, segment string (e.g. "T20", "SB"); empty slots: outline circle `○`
- Player score in header: `textScoreSmall` (36sp Oswald Bold), `colorPrimary`
- Player name in header: `textLabelSmall`, `colorOnBackground`, ALL CAPS
- Target label: `textSegmentButton` (18sp DM Sans SemiBold)
- Mark symbols: `textHeadingMedium`
- Input button number: `textSegmentButton` (18sp DM Sans SemiBold)
- "NEXT PLAYER": `textLabelLarge`
- "MISS" / "UNDO": `textLabelLarge`

### Mark Symbols

| Marks | Symbol | Color |
|-------|--------|-------|
| 0     | ─      | `colorOnSurfaceVariant` |
| 1     | /      | `colorOnBackground` |
| 2     | X      | `colorOnBackground` (bold) |
| 3+    | ⊗      | `colorCricketClosed` (#4CAF50) |

### Input Cell Styling (contiguous tile layout)

Cells are flush, `radiusNone`, separated by 1dp `colorOutline` hairlines (right and bottom of each cell). Minimum cell height: 56dp (cricket target rows). Cell width: equal thirds of the input column group.

- Single cell: `colorSurface` background, `colorOnSurface` text, no dot indicators.
- Double cell: `colorPrimaryContainer` background, `colorOnPrimaryContainer` text, 2 × 4dp dot indicators below number.
- Triple cell: `colorPrimary` background, `colorOnPrimary` text, 3 × 4dp dot indicators below number.
- Bull triple slot: blank `colorSurfaceVariant` cell, no tap handler, small "≡DB" label in `textLabelSmall` `colorOnSurfaceVariant`.

### Color Usage
- Closed row (all players ≥3 marks): entire row at 38% opacity, `colorSurfaceVariant` tint; input buttons disabled
- Active player column header: `colorPrimary` score; subtle left border or background to indicate active
- Dart indicator chip (thrown): `colorSurface` background, `colorOutline` border, segment label
- Dart indicator chip (remaining): outline circle `○`, `colorOutline`
- MISS button: `colorSurface`, `colorOutline` border
- UNDO button: icon or text in `colorOnSurface`; disabled at 38% opacity
- NEXT PLAYER: `colorPrimary` filled button
- Input cell dividers: 1dp `colorOutline` hairline (right and bottom of each cell).

### Special Notes
- **Dart indicator** sits between AppBar and the table. Shows segment label (e.g. "T20", "SB", "19") for thrown darts; outline circle for remaining slots.
- **Header row** shows each player's current score (top) and name (bottom, ALL CAPS). MISS and UNDO sit in the input columns of this row.
- **Target rows** each contain: fixed-width target label column (48dp) | marks-per-player columns (flexible) | 3 flush input cells (equal width, together occupying fixed space so each cell ≥ 48dp wide). The 3 input cells share the same row height as the rest of the row (minimum 56dp). Individual input cells have `radiusNone`; they are not wrapped in their own card. Cell dividers are 1dp `colorOutline` hairlines.
- **All-closed rows**: when every player has ≥3 marks on a number, the row is visually dimmed. Input buttons are disabled — the number is out of play.
- **Bull row**: no triple button. Triple bull maps to double bull in cricket (3 marks from T = 3 marks from DB in terms of scoring), but the input only exposes SB and DB. The T slot is empty.
- **NEXT PLAYER button**: placed in the footer row, right-aligned, same column width as the input buttons (3 × 48dp). Left portion of footer row is empty space.
- No persistent bottom navigation bar (full-screen game mode).
- FAB (📊) in bottom-right opens stats overlay — keep as-is.

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
│                                 │
│  DartboardHighlightWidget       │  ← Expanded, fills remaining height
│  current target highlighted in  │
│  colorPrimary; all others at    │
│  35% opacity                    │
│                                 │
├─────────────────────────────────┤
│  PracticeTargetDisplayWidget    │
│  Large target label (48sp)      │  ← textScoreMedium Oswald, colorPrimary
│  Secondary metric               │  ← textBodyMedium, colorOnSurfaceVariant
├─────────────────────────────────┤
│  PracticeInputButtonsWidget     │  ← varies per game type (see subsections)
├─────────────────────────────────┤
│  BottomBar (SafeArea)           │
│  [↩ Undo]  [MISS]  [ACTION]    │  ← ACTION varies per game type
└─────────────────────────────────┘
```

### Shared Typography
- AppBar title line 1: `textHeadingSmall`, `colorOnBackground` — game name
- AppBar title line 2: `textBodySmall`, `colorOnSurfaceVariant` — progress subtitle
- Target label: `textScoreMedium` (48sp Oswald Bold), `colorPrimary`
- Secondary metric: `textBodyMedium`, `colorOnSurfaceVariant`
- Bottom-bar action button: `textLabelLarge`
- Undo button: `textLabelLarge`; disabled at 38% opacity

### Shared Color Usage
- DartboardHighlightWidget highlighted segment: `colorPrimary`
- DartboardHighlightWidget non-highlighted segments: `colorOnSurface` at 35% opacity
- Bottom-bar primary action: `colorPrimary` filled button
- MISS button: `colorSurface` background, `colorOutline` border
- Undo button: icon/text in `colorOnSurface`; disabled at 38% opacity

### Shared Special Notes
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

**Dartboard:** Full board shown; current number's entire wedge highlighted in `colorPrimary`. In `doublesOnly` variant, only the double ring of the current number is highlighted; the single and triple rings for that number are shown at 60% opacity.

**Input bar — 3-cell contiguous row:**

A single-row flush tile grid of 3 equal-width cells spanning the full screen width (edge-to-edge, no horizontal margin — visually distinct from content cards above it). Parent container: `radiusNone` (flat bar). Minimum cell height: 56dp. Cells separated by 1dp `colorOutline` vertical hairlines.

```
│ S-N │ D-N │ T-N │
```

- S-N: `colorSurface` background, `colorOnSurface` text, no dots.
- D-N: `colorPrimaryContainer` background, `colorOnPrimaryContainer` text, 2 × 4dp dot indicators.
- T-N: `colorPrimary` background, `colorOnPrimary` text, 3 × 4dp dot indicators.

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

**Input bar — 3-cell contiguous row:**

A single-row flush tile grid of 3 equal-width cells spanning the full screen width (edge-to-edge, no horizontal margin). Parent container: `radiusNone` (flat bar). Minimum cell height: 56dp. Cells separated by 1dp `colorOutline` vertical hairlines.

```
│ S-N │ D-N │ T-N │
```

- S-N: `colorSurface` background, `colorOnSurface` text, no dots.
- D-N: `colorPrimaryContainer` background, `colorOnPrimaryContainer` text, 2 × 4dp dot indicators.
- T-N: `colorPrimary` background, `colorOnPrimary` text, 3 × 4dp dot indicators.

`S-N` and `T-N` are visually dimmed: foreground at 38% opacity. Background remains full opacity. They are tappable but the engine treats them as failures for that round (scoring penalty applies). The MISS button in the bottom bar records all 3 darts as missed.

**Bottom bar right action:** `NEXT ROUND` — enabled only when `dartsThrownInTurn == 3`.

**Early end:** if score ≤ 0 after any round, the drill ends immediately. A bust modal shows the round reached and the final score, with a "NEW DRILL" button.

**Completion after round 20:** show a winner modal with final score and "NEW DRILL" → Home.

---

### 7c. Catch-40

**AppBar subtitle:** "Round N / {total}" (default total = 8)

**Target display:**
- Large: "≥40 pts" (the round score threshold)
- Secondary: "Round N/{total} · scored: {roundScore}" — `roundScore` is the sum of the current turn's darts (derived in UI; not persisted separately)

**Dartboard:** No specific number is highlighted. Full board shown at normal opacity (all segments score their face value).

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

All segments score their face value: T20 = 60, D20 = 40, 20 = 20, SB = 25, DB = 50.

The full 7-row segment grid in this game type follows the identical contiguous-tile spec as the X01 Board (Section 5). All geometry, hairline dividers, color tokens, dot indicators, and semantic labels are the same. Refer to Section 5.

> **Note:** this full-grid layout is the intended design using the contiguous tile spec (Section 5). The current 4-button `PracticeInputButtonsWidget` is a placeholder and must be replaced.

**Bottom bar right action:** `NEXT ROUND` — enabled only when `dartsThrownInTurn == 3`.

**Completion:** after all rounds, show a summary modal with total score across all rounds and "NEW DRILL" → Home.

---

### 7d. Shanghai

**AppBar subtitle:** "Round N / {total}" (default total = 7)

**Target display:**
- Large: current round number (e.g. "3")
- Secondary: "Score: {score} | Round N/{total}"

**Dartboard:** Full board; current round number's entire wedge highlighted in `colorPrimary`.

**Input bar — 3-cell contiguous row:**

A single-row flush tile grid of 3 equal-width cells spanning the full screen width (edge-to-edge, no horizontal margin). Parent container: `radiusNone` (flat bar). Minimum cell height: 56dp. Cells separated by 1dp `colorOutline` vertical hairlines.

```
│ S-N │ D-N │ T-N │
```

- S-N: `colorSurface` background, `colorOnSurface` text, no dots.
- D-N: `colorPrimaryContainer` background, `colorOnPrimaryContainer` text, 2 × 4dp dot indicators.
- T-N: `colorPrimary` background, `colorOnPrimary` text, 3 × 4dp dot indicators.

Only the current round number is shown (N = current round). MISS is in the bottom bar.

**Bottom bar right action:** `NEXT ROUND` — enabled only when `dartsThrownInTurn == 3`.

**Shanghai bonus:** if S-N, D-N, and T-N are all hit in the same turn (in any order), a "SHANGHAI!" banner flashes briefly (300ms scale-in, 1s visible) before the round advances. Color: `colorPrimary` text on `colorPrimaryContainer` background.

**Completion:** after all rounds, show a summary modal with total score and "NEW DRILL" → Home.

---

### 7e. Checkout Practice

**AppBar subtitle:** "{successes}/{attempts} checkouts"

**Target display:**
- Large: current checkout finish value (e.g. "170")
- Secondary: route hint shown step-by-step as darts land.
  - Before any dart: "○ · ○ · ○"
  - After first correct dart (e.g. T20): "T20 · ○ · ○"
  - After second correct dart (e.g. T20 again): "T20 · T20 · ○"
  - After completion (e.g. DB): "T20 · T20 · DB"
  - Correct hits render in `colorPrimary`; wrong hits render in `colorError`; unfilled slots are "○" in `colorOutline`

**Dartboard:** Full board at normal opacity. No specific segment is pre-highlighted; the player must navigate to their own segment.

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

The full 7-row segment grid in this game type follows the identical contiguous-tile spec as the X01 Board (Section 5). All geometry, hairline dividers, color tokens, dot indicators, and semantic labels are the same. Refer to Section 5.

A wrong dart (segment that does not match the expected route step) resets `routeProgress` to 0 and marks the turn as failed; the remaining darts of the turn are still thrown but cannot succeed.

> **Note:** this full-grid layout is the intended design using the contiguous tile spec (Section 5). The current 4-button `PracticeInputButtonsWidget` is a placeholder and must be replaced.

**Bottom bar:** No MISS button in bottom bar (MISS is entered via the input grid row 0). The bottom bar right action is `END DRILL` (filled, `colorPrimary`) — always enabled once `dartsThrownInTurn == 3`. There is no `NEXT ROUND` button; the turn advances automatically after 3 darts have been registered.

**Route progress:** `routeProgress` in `CompetitorState` tracks how many segments of the current route have been hit correctly (0, 1, or 2). A correct hit increments it. A wrong hit resets it to 0 and marks the attempt as failed.

**Completion:** no automatic end — the player ends the drill explicitly via `END DRILL`. A summary modal shows Attempts, Successes, and success rate (e.g. "5/8 = 62.5%"), with "NEW DRILL" → Home.

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
- Stat subtitle: `textBodySmall`, `colorOnSurfaceVariant`

### Color Usage
- Player row: `colorSurface` background, `colorOutline` divider
- Avatar background: `colorSecondaryContainer`; initials: `colorOnSecondaryContainer`
- [+] FAB / AppBar icon: `colorPrimary`

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
- Player name: `textDisplayLarge` (32sp DM Sans SemiBold) — rendered as inline editable field
- Stat card value: `textScoreSmall` (36sp Oswald Bold), `colorPrimary`
- Stat card label: `textLabelMedium`, `colorOnSurfaceVariant`

### Color Usage
- Hero avatar: 80dp circular, `colorSecondaryContainer` background
- Stat cards: `colorSurface`, `radiusMedium`, elevation 1
- Delete icon (🗑): `colorError` tint
- "VIEW STATISTICS" button: `colorPrimary` filled

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
- Name field label: `textBodyMedium`, `colorOnSurfaceVariant`
- Name field input: `textBodyLarge`
- Button: `textLabelLarge`

### Color Usage
- Input border focused: `colorPrimary`
- Input border unfocused: `colorOutlineVariant`
- Avatar preview: `colorSecondaryContainer` background, initials update as user types

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
- Tab indicator: `colorPrimary` underline, 2dp
- Active tab label: `colorPrimary`, `textLabelLarge`
- Inactive tab label: `colorOnSurfaceVariant`, `textLabelLarge`
- Cricket, Practice, and Others tabs show a "coming soon" placeholder (same desaturated treatment as Home coming-soon cards) at this stage

### Summary Cards Row
- 3 cards in a single horizontal row, equal width, `colorSurface`, `radiusMedium`, elevation 1
- **X01 cards:** Legs Played | Legs Won | Solo Games
  - "Solo Games" = number of distinct completed games (not legs — legs are sub-units of a game)
- Card value: `textScoreSmall` (36sp Oswald Bold), `colorPrimary`
- Card label: `textLabelMedium`, `colorOnSurfaceVariant`

### Variant Selector (X01 tab only)
- Horizontal scrollable chip row below the summary cards
- First chip: **"All X01"** (default selected)
- Additional chips: one per distinct starting score seen in the player's data (e.g. **"501"**, **"301"**)
- Selected chip: `colorPrimaryContainer` background, `colorOnPrimaryContainer` text
- Unselected chip: `colorSurfaceVariant` background, `colorOnSurfaceVariant` text
- Variant selection filters both the trend chart and the detail table
- Hidden on tabs without variants (Cricket, Practice, Others)

### Time Range Selector
- `SegmentedButton` with 3 options: **Last 10**, **Last 100**, **All**
- Default: **All**
- Applies to both the trend chart and the detail table
- `colorPrimary` selected segment fill

### Trend Chart
- Full-width line chart, minimum 160dp height
- X axis: game/leg index (oldest → newest, left → right)
- Y axis: PPR value; auto-scales to data range with a comfortable margin
- Line color: `colorPrimary`; filled area below line: `colorPrimaryContainer` at 30% opacity
- Chart background: `colorSurface`, `radiusMedium`
- **Overlay toggle chip** below chart: "Checkout %" — when toggled on, a second line in `colorSecondary` is overlaid. The Y axis remains the same scale (CO% is rendered as a 0–100 value on the same axis; its secondary line label clarifies the scale)
- Tapping a data point shows a tooltip: PPR value (and CO% if overlay active) + game date
- Empty state (fewer than 2 data points): centered "Not enough data yet" text, `textBodyMedium`, `colorOnSurfaceVariant`

### Detail Table
- Two-column table: **Metric** (left, `textBodyMedium`, `colorOnBackground`) | **Value** (right, `textBodyMedium`, `colorPrimary`)
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

- Alternating row tint: even rows `colorSurface`, odd rows `colorBackground`
- "total / per leg" cells render as `"42 / 1.2"` inline
- Table scrolls as part of the overall page — it is not independently scrollable

### Typography
- AppBar title: `textHeadingMedium`
- Summary card value: `textScoreSmall` (36sp Oswald Bold), `colorPrimary`
- Summary card label: `textLabelMedium`, `colorOnSurfaceVariant`
- Table metric label: `textBodyMedium`, `colorOnBackground`
- Table value: `textBodyMedium`, `colorPrimary`
- Section dividers (if added): `textLabelSmall`, `colorOnSurfaceVariant`, ALL CAPS

### Color Usage
- Summary cards: `colorSurface`, `radiusMedium`, elevation 1
- Chart line: `colorPrimary`; chart area fill: `colorPrimaryContainer` 30% opacity
- Checkout % overlay line: `colorSecondary`
- Variant chips (selected): `colorPrimaryContainer` / `colorOnPrimaryContainer`
- Variant chips (unselected): `colorSurfaceVariant` / `colorOnSurfaceVariant`
- Time range selected segment: `colorPrimary` fill
- Table alternating rows: `colorSurface` / `colorBackground`
- Coming-soon tab placeholder: `colorSurfaceVariant` background, `colorOnSurfaceVariant` text + icon, `opacity: 0.6`

### Special Notes
- **Cricket, Practice, Others tabs are stubbed:** show a centred "Stats for [game type] coming soon" placeholder. No summary cards, no chart, no table.
- **Variant selector** appears only on the X01 tab (and future tabs where variants apply). Hidden otherwise.
- **Time range** applies across the entire tab (chart + table). Switching range recomputes all displayed metrics.
- **No leaderboard** on this page. Strictly per-player, per-game-type stats.
- **Projection data dependency:** The trend chart requires time-series PPR data per leg/game. The current `PlayerStats` entity is a flat aggregate and does not carry time-series data. A new data structure (list of per-game snapshots) will be needed in `StatisticsRepository` and `PlayerStats`. This is flagged for the implementation ticket.
- **Route rename:** The previous route was `/stats/career/:playerId`. This spec uses `/stats/player/:playerId`. Implementation must update the router accordingly.

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
- "WINNER" badge: `textLabelLarge`, `colorOnPrimary` on `colorWin` chip
- Stat label: `textBodySmall`, `colorOnSurfaceVariant`
- Stat value: `textHeadingMedium` (20sp DM Sans SemiBold)

### Color Usage
- Winner card: `colorWinContainer` background, 2dp `colorWin` border
- Loser card: `colorSurface`
- "PLAY AGAIN": `colorPrimary` filled
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
- Winner line: `textBodyLarge`, `colorOnBackground` — bold winner name
- Metadata (date, dart count): `textBodySmall`, `colorOnSurfaceVariant`

### Color Usage
- Filter chips: `colorPrimaryContainer` (active), `colorSurfaceVariant` (inactive)
- Game card: `colorSurface`, `radiusMedium`, elevation 1
- Game type label chip: `colorSecondaryContainer` background

### Special Notes
- Navigated to from the Home page via the History card. Back button returns to Home.
- Infinite scroll: `loadNextPage()` fires when within 200px of bottom. Loading indicator: `CircularProgressIndicator` in `colorPrimary` centered below last item.
- Empty state: centered icon + "No completed games yet." text.
- Shimmer skeleton placeholders on initial load (3 placeholder cards in `colorSurfaceVariant`).

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
- Date: `textBodySmall`, `colorOnSurfaceVariant`
- Stat values: `textScoreSmall` (36sp Oswald Bold), `colorOnBackground`
- Leg table header: `textLabelMedium`, `colorOnSurfaceVariant`
- Leg table rows: `textBodyMedium`

### Color Usage
- Result header background: `colorSurface`
- Winning player row in leg table: `colorPrimaryContainer` subtle tint

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
- Section headers: `textLabelMedium`, `colorOnSurfaceVariant`, ALL CAPS with `space2` (8dp) top + `space1` (4dp) bottom padding
- Setting label: `textBodyLarge`, `colorOnBackground`
- Setting description: `textBodySmall`, `colorOnSurfaceVariant`

### Color Usage
- Toggle active state: `colorPrimary` track
- Toggle inactive: `colorOutlineVariant` track
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
| Full page initial load | Centered `CircularProgressIndicator` in `colorPrimary` on `colorBackground` |
| List initial load | 3 shimmer skeleton cards in `colorSurfaceVariant`, `radiusMedium` |
| List pagination | Small `CircularProgressIndicator` centered below last item |
| Button async action | Inline `SizedBox(20×20)` `CircularProgressIndicator(strokeWidth: 2)` replaces button text |

### Error States

| Context | Pattern |
|---|---|
| Full page error | Centered `error_outline` icon (48dp) + error message text + "Retry" `TextButton` in `colorPrimary` |
| Snackbar (transient) | `colorErrorContainer` background, `colorOnErrorContainer` text, auto-dismiss 4s |
| Validation error (inline) | Field border turns `colorError`; helper text below in `colorError`, `textBodySmall` |

### Empty States

All empty states use:
- Centered layout
- Large icon (64dp) in `colorOnSurfaceVariant` at 60% opacity
- Primary message: `textBodyLarge`, `colorOnBackground`
- Secondary message / CTA: `textBodyMedium`, `colorOnSurfaceVariant`
- When there is a creation CTA, use a `FilledButton` in `colorPrimary`

### Dialogs

All confirmation dialogs:
- Title: `textHeadingSmall`
- Body: `textBodyMedium`
- Cancel button: `TextButton`, `colorOnBackground`
- Confirm button: `FilledButton`, `colorPrimary` for neutral; `colorError` filled for destructive actions
- Corner radius: `radiusMedium` (12dp)
- Minimum dialog width: `min(screen_width - 48dp, 320dp)`
