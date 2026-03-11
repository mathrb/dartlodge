# SCR-001 — Home Page

**Route:** `/`
**File:** `lib/features/game/presentation/pages/home_page.dart`

---

## Design Principles

- **P1 — Readable at a glance:** All destinations visible without scrolling; section grouping makes intent immediately clear.
- **P2 — Primary actions reachable from rest position:** Game list cards are large tap targets in the natural thumb zone; no hamburger or buried navigation.
- **P4 — Scorecard visual language:** Section labels with accent bars echo the broadcast-scoreboard aesthetic used throughout the app.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│  Darts                   ⚙ │  ← AppBar: title left, gear icon right → Settings
├─────────────────────────────┤
│  PLAY                       │  ← section label (textLabelSmall, ALL CAPS)
│  ┌────────────────────────┐ │
│  │ ▌ X01             →   │ │  ← 4dp left accent colorPrimary
│  │ ▌ Cricket          →   │ │  ← 4dp left accent colorSecondary
│  │ ▌ Practice         →   │ │  ← 4dp left accent colorOnPrimaryContainer
│  │ ▌ Statistics       →   │ │  ← 4dp left accent colorSecondary
│  └────────────────────────┘ │
│  ┌────────────────────────┐ │
│  │ History            →   │ │  ← full-width nav card
│  └────────────────────────┘ │
│  ┌────────────────────────┐ │
│  │ Local Players      →   │ │  ← full-width nav card
│  └────────────────────────┘ │
│  (Coming soon, desaturated) │
│  [Game Lobby]               │
│  [VS Friends]               │
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** Fixed at top. Title "Darts" left-aligned. Gear icon (48×48dp tap target) right-aligned.
- **PLAY section:** Section label immediately below AppBar with `space4` (16dp) horizontal margin and `space2` (8dp) top padding. Followed by a single grouped card containing 4 stacked rows — X01, Cricket, Practice, Statistics — each with its own 4dp left accent bar and a trailing chevron. The entire group shares one card container (1dp border, `radiusLarge`).
- **History card:** Full-width standalone card below the PLAY group. Minimum 64dp height.
- **Local Players card:** Full-width standalone card below History. Minimum 64dp height.
- **Coming-soon section:** Two desaturated cards at the bottom — "Game Lobby" and "VS Friends". Visually muted; no tap handler.

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title "Darts" | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| "PLAY" section label | `textLabelSmall` (DM Sans Medium 11sp, ALL CAPS) | `colorOnSurfaceVariant` |
| Game list item label (X01, Cricket, Practice, Statistics) | `textBodyLarge` (DM Sans Regular 16sp) | `colorOnBackground` |
| History / Local Players nav card label | `textBodyLarge` | `colorOnBackground` |
| Coming-soon card label | `textLabelMedium` (DM Sans Medium 12sp) | `colorOnSurfaceVariant` |
| Future subtitle text (reserved) | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |

---

## Colors

| Element | Token |
|---|---|
| AppBar background | `colorBackground` |
| Gear icon | `colorOnBackground` |
| PLAY group card background | `colorSurface` |
| PLAY group card border | 1dp `colorOutline` |
| PLAY group card corner radius | `radiusLarge` (16dp) |
| X01 left accent bar (4dp wide) | `colorPrimary` |
| Cricket left accent bar (4dp wide) | `colorSecondary` |
| Practice left accent bar (4dp wide) | `colorOnPrimaryContainer` |
| Statistics left accent bar (4dp wide) | `colorSecondary` |
| Trailing chevron | matches the card row's accent bar color |
| History card background | `colorSurface` |
| History card border | 1dp `colorOutline` |
| History card corner radius | `radiusLarge` (16dp) |
| Local Players card background | `colorSurface` |
| Local Players card border | 1dp `colorOutline` |
| Local Players card corner radius | `radiusLarge` (16dp) |
| Coming-soon card background | `colorSurfaceVariant` |
| Coming-soon card text | `colorOnSurfaceVariant` |
| Coming-soon card opacity | 0.6 on the entire card |

---

## Interactions

- **PLAY group rows:** Each row is a full-width tap target. Minimum row height: 64dp. Ripple effect uses `colorOnSurface` at 12% opacity, clipped to row boundary. Tap navigates to the Variant Selection page for that game type (`/game/variant-selection/:gameType`).
- **History card:** Full-width tap target, minimum 64dp height. Tap navigates to `/history`.
- **Local Players card:** Full-width tap target, minimum 64dp height. Tap navigates to `/players`.
- **Statistics row:** Tap navigates to Career Stats `/stats/player` (player stats overview — not a player selection screen).
- **Gear icon:** 48×48dp tap target in AppBar. Tap navigates to `/settings`.
- **Coming-soon cards:** `onTap` is null. Pointer cursor semantics: `SystemMouseCursors.forbidden`. Include `Tooltip` widget with text "Coming soon" on each card.
- **Chevron:** Color always matches the accent bar of its row. No separate tap behavior — the whole row is the tap target.

---

## Edge Cases

- **No loading state:** Home page content is static. No async data is required at this level. The screen renders immediately.
- **No empty state:** The game list (X01, Cricket, Practice, Statistics) is always populated with 4 fixed entries; these are not loaded from a data source.
- **Coming-soon cards:** Always rendered desaturated (opacity 0.6) regardless of connectivity or any backend state.

---

## Special Notes

- There is **no persistent bottom navigation bar** anywhere in the app. Home is the sole navigation hub. All destinations are reached from this screen or via the AppBar on a nested screen.
- Settings is accessible **only** via the gear icon in the AppBar; it does not appear as a card on this screen.
- The Statistics row navigates to Career Stats. This is intentional — no player selection intermediate step.
- The PLAY section groups all 4 game-mode rows into a single card container with shared `radiusLarge` corners and 1dp border. Individual rows inside the group use `radiusNone` on their own backgrounds so they appear as a unified block.
- Minimum card height: 64dp for all tappable rows.
- Page horizontal margin: `space4` (16dp) on both sides.
- Bottom of page must respect safe area (`space16` / 64dp bottom safe area).
