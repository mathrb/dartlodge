# Design System — my-darts

**Theme name:** Court Ready
**Last updated:** 2026-03-10
**Status:** Specification (pre-implementation)

---

## 1. Design Principles

### P1 — Legible at arm's length
A player glances at the board mid-game with a dart in hand. Every score, every status indicator must be readable in under one second from 60 cm. No information may be buried behind hover states, small font sizes, or low-contrast color pairings.

### P2 — One action per thumb reach
The primary action on any game screen must be reachable without repositioning the hand. Destructive or irreversible actions (undo, end game) require a second confirmation tap. Navigation is driven by tappable cards on the Home page. There is no persistent navigation bar and no hamburger menu. Game boards are full-screen with no navigation chrome.

### P3 — State is always visible
The active player, current score, darts thrown this turn, and remaining outs are always on screen during play. No action collapses this information. Status is conveyed by color and position — never by icon alone.

### P4 — Sports clarity over decoration
The visual language borrows from broadcast scoreboards, not consumer apps. Bold condensed numerals. High-contrast on dark panels. No drop shadows on interactive elements. Whitespace is used to separate logic, not to pad.

---

## 2. Color Tokens

### 2.1 Palette (Light Mode)

| Token | Hex | Usage |
|---|---|---|
| `colorBackground` | `#F7F8FA` | App scaffold background |
| `colorSurface` | `#FFFFFF` | Cards, sheets, dialogs |
| `colorSurfaceVariant` | `#F1F3F5` | Input fields, inactive chips |
| `colorPrimary` | `#C62828` | Brand red — CTA buttons, active player accent, score highlight |
| `colorOnPrimary` | `#FFFFFF` | Text/icons on primary-colored elements |
| `colorPrimaryContainer` | `#FFCDD2` | Selection chips, tags, highlighted rows |
| `colorOnPrimaryContainer` | `#7F0000` | Text inside primary container elements |
| `colorSecondary` | `#1A237E` | Active player name, links, focused ring |
| `colorOnSecondary` | `#FFFFFF` | Text on secondary-colored elements |
| `colorSecondaryContainer` | `#E8EAF6` | Secondary selection states |
| `colorOnSecondaryContainer` | `#0D1257` | Text inside secondary container |
| `colorError` | `#D32F2F` | Bust indicator, validation errors |
| `colorOnError` | `#FFFFFF` | Text on error-colored backgrounds |
| `colorErrorContainer` | `#FFEBEE` | Bust snackbar background, error cards |
| `colorOnErrorContainer` | `#B71C1C` | Text inside error container |
| `colorOutline` | `#E5E7EB` | Dividers, card borders |
| `colorOutlineVariant` | `#D1D5DB` | Input borders (unfocused) |
| `colorOnBackground` | `#111827` | Primary body text |
| `colorOnSurface` | `#111827` | Text on cards |
| `colorOnSurfaceVariant` | `#6B7280` | Secondary labels, captions, placeholder text |
| `colorScrim` | `#000000` | Modal backdrop at 50% opacity |

### 2.2 Palette (Dark Mode)

| Token | Hex | Usage |
|---|---|---|
| `colorBackground` | `#0F1117` | App scaffold background |
| `colorSurface` | `#1C1F26` | Cards, sheets |
| `colorSurfaceVariant` | `#272B34` | Input fields, inactive chips |
| `colorPrimary` | `#EF5350` | Slightly lighter red for legibility on dark |
| `colorOnPrimary` | `#7F0000` | Text on primary buttons (inverted) |
| `colorPrimaryContainer` | `#7F0000` | Selection chips in dark mode |
| `colorOnPrimaryContainer` | `#FFCDD2` | Text inside primary container |
| `colorSecondary` | `#7986CB` | Active player accent, links |
| `colorOnSecondary` | `#0D1257` | Text on secondary elements |
| `colorSecondaryContainer` | `#1A237E` | Secondary selection |
| `colorOnSecondaryContainer` | `#E8EAF6` | Text inside secondary container |
| `colorError` | `#EF5350` | Bust, validation |
| `colorOnError` | `#7F0000` | Text on error background |
| `colorErrorContainer` | `#370B0A` | Bust snackbar background |
| `colorOnErrorContainer` | `#FFCDD2` | Text inside error container |
| `colorOutline` | `#374151` | Dividers |
| `colorOutlineVariant` | `#4B5563` | Input borders |
| `colorOnBackground` | `#F9FAFB` | Primary body text |
| `colorOnSurface` | `#F9FAFB` | Text on cards |
| `colorOnSurfaceVariant` | `#9CA3AF` | Secondary labels |

### 2.3 Semantic Aliases (game-specific)

| Token | Resolves to | Meaning |
|---|---|---|
| `colorActivePlayer` | `colorPrimary` | Left border and tint on active player panel |
| `colorActivePlayerBg` | `#FFF5F5` / dark: `#2A1515` | Panel background tint for active player |
| `colorInactiveScore` | `#9CA3AF` / dark: `#6B7280` | Score numeral for non-active players |
| `colorBust` | `colorError` | Bust flash overlay, snackbar |
| `colorCricketClosed` | `#4CAF50` | Cricket number closed indicator |
| `colorCricketLeading` | `colorPrimary` | Cricket player leading indicator |
| `colorWin` | `#2E7D32` | Win banner, end-game highlight |
| `colorWinContainer` | `#E8F5E9` / dark: `#1B3A1C` | Win screen card background |

---

## 3. Typography Tokens

### 3.1 Font Families

| Family | Weight used | Source | Purpose |
|---|---|---|---|
| **Oswald** | Bold (700) | `google_fonts` | Score display, large numerals — condensed, athletic |
| **DM Sans** | Regular (400), Medium (500), SemiBold (600) | `google_fonts` | All UI text — player names, labels, navigation |

Fallback stack: `system-ui, sans-serif`

### 3.2 Type Scale

| Token | Family | Weight | Size | Line height | Letter spacing | Usage |
|---|---|---|---|---|---|---|
| `textScoreActive` | Oswald | Bold | 80sp | 80sp | 0 | Active player score |
| `textScoreInactive` | Oswald | Bold | 56sp | 56sp | 0 | Inactive player scores |
| `textScoreMedium` | Oswald | Bold | 48sp | 52sp | 0 | Post-game summary score, leaderboard top score |
| `textScoreSmall` | Oswald | Bold | 36sp | 40sp | 0 | History list scores, stat cards |
| `textDisplayLarge` | DM Sans | SemiBold | 32sp | 40sp | -0.5 | Page titles (rare) |
| `textHeadingLarge` | DM Sans | SemiBold | 24sp | 32sp | 0 | Section headers, dialog titles |
| `textHeadingMedium` | DM Sans | SemiBold | 20sp | 28sp | 0 | Card headers, player name in scoreboard |
| `textHeadingSmall` | DM Sans | SemiBold | 16sp | 24sp | 0.15 | Subsection labels, stat titles |
| `textBodyLarge` | DM Sans | Regular | 16sp | 24sp | 0 | Primary body content |
| `textBodyMedium` | DM Sans | Regular | 14sp | 20sp | 0.1 | Secondary body, list descriptions |
| `textBodySmall` | DM Sans | Regular | 12sp | 16sp | 0.2 | Captions, timestamps |
| `textLabelLarge` | DM Sans | Medium | 14sp | 20sp | 0.5 | Button text, tab labels |
| `textLabelMedium` | DM Sans | Medium | 12sp | 16sp | 0.5 | Chips, tags |
| `textLabelSmall` | DM Sans | Medium | 11sp | 16sp | 0.5 | Badge text, small indicators |
| `textPlayerName` | DM Sans | SemiBold | 16sp | 20sp | 1.5 | Player name in scoreboard — ALL CAPS |
| `textSegmentButton` | DM Sans | SemiBold | 18sp | 18sp | 0 | Dart segment grid button numbers |
| `textMultiplierLabel` | DM Sans | Medium | 11sp | 14sp | 0.5 | "DBL" / "TRP" labels on segment buttons |

### 3.3 Usage Rules

- Never use `textScoreActive` or `textScoreInactive` for non-numeric content.
- `textPlayerName` must always render in ALL CAPS via `TextStyle.letterSpacing` and `toUpperCase()` on the string — do not rely on CSS `text-transform`.
- Minimum rendered size is 11sp. Never go below this for any text users need to read.
- Score numerals must never truncate or wrap. Constrain the container width, not the text size.

---

## 4. Spacing Scale

Base unit: **4dp**

| Token | Value | Usage |
|---|---|---|
| `space1` | 4dp | Minimum internal padding — icon gap, tight chip padding |
| `space2` | 8dp | Compact padding — list tile vertical padding, small gaps |
| `space3` | 12dp | Icon + label gaps, input field internal padding |
| `space4` | 16dp | Standard content padding (horizontal page margin) |
| `space5` | 20dp | Card internal padding (top/bottom) |
| `space6` | 24dp | Section spacing within a screen |
| `space8` | 32dp | Section headers below previous content |
| `space10` | 40dp | Large visual break between major layout regions |
| `space12` | 48dp | Empty state illustration margin |
| `space16` | 64dp | Bottom padding for scrollable content above nav bar |

**Page horizontal margin:** `space4` (16dp) on both sides.
**Bottom safe area:** All scrollable content must include `space16` (64dp) bottom padding to clear the system navigation bar on devices that use on-screen gesture navigation.

---

## 5. Shape Tokens

| Token | Value | Usage |
|---|---|---|
| `radiusNone` | 0dp | Dividers, full-bleed banners |
| `radiusXSmall` | 4dp | Chips, small badges |
| `radiusSmall` | 8dp | Input fields, small cards |
| `radiusMedium` | 12dp | Standard cards, dialogs |
| `radiusLarge` | 16dp | Bottom sheets, game board button groups |
| `radiusXLarge` | 24dp | Hero cards (game result) |
| `radiusFull` | 9999dp | Avatar, FAB, pill buttons |

**Elevation / shadows:**

| Level | Usage | Shadow |
|---|---|---|
| 0 | Background, flat elements | None |
| 1 | Standard cards | `0 1px 3px rgba(0,0,0,0.08)` |
| 2 | Elevated cards, dropdowns | `0 4px 8px rgba(0,0,0,0.12)` |
| 3 | Dialogs, modals | `0 8px 24px rgba(0,0,0,0.16)` |

Do not add shadows to interactive controls (buttons, chips). Shadows communicate elevation, not interactivity.

**Contiguous grid containers:** When a group of interactive cells forms a flush tile grid (no gaps, no individual border-radius), a parent `ClipRRect` at `radiusMedium` (12dp) gives the group rounded corners as a unit. **Exception:** Game board input grids (X01, Practice) span the full screen width (edge-to-edge) and use `radiusNone` to maximize tap area and visual clarity. Cell borders are 1dp `colorOutline` hairlines — not padding or spacing. Each cell draws only its trailing (right) and bottom edge, so shared borders between adjacent cells remain 1dp.

---

## 6. Minimum Tap Target Rules

**Absolute minimum:** 48×48dp for any interactive element.

| Element | Minimum touch target | Recommended visual size |
|---|---|---|
| Segment cell — 3-cell bar (Practice 3-button types, Cricket input) | 56dp height × ⅓ row width | 56dp height |
| Segment cell — 10-column grid (X01, Catch-40, Checkout Practice) | 48dp height × ~39dp width | 48dp height; width = screen width ÷ 10 |
| Undo / correction button | 48×48dp | 44×36dp visual, 48dp touch |
| Chip / filter pill | 48dp height × auto width | 36dp visual height |
| Player row in selection list | 56dp height | 56dp |
| Bottom sheet drag handle | 48×48dp centered tap area | 4×32dp visual bar |
| Dialog action button | 48dp height | 40dp visual |
| FAB (start game) | 56×56dp | 56×56dp |

**Game board special rules:**

**3-cell bar** (practice games with a single active target; Cricket input columns): cells expand to one-third of available width. Minimum 56dp height. No exception.

**10-column contiguous grid** (X01 Board, Catch-40, Checkout Practice): 10 cells per row keeps all 20 numbers in 2 rows per tier without reordering the dartboard clock sequence. On a 390dp device this yields ~39dp cell widths — an **accepted exception** because:
- Cells are densely packed with no gaps, making horizontal mis-taps unlikely.
- Minimum cell height is 48dp.
- Every cell must carry a full `semanticsLabel` (e.g. "Triple 20", "Double Bull").
- Never reduce cell height below 48dp. Never add more than 10 columns per row.

**Responsive fallback** (narrow devices, screen width < 360dp): switch to 5 columns × 4 rows per tier. Implementation detail; not required for the primary 390dp layout.

---

## 7. Interactive States

### 7.1 Pressed State

All pressable surfaces use a ripple / ink effect constrained to the element boundary. Ripple color is `colorOnSurface` at 12% opacity (light) / 16% opacity (dark). No scale transforms on press — avoid "pop" animations during rapid dart entry.

### 7.2 Focused State (keyboard / accessibility)

Focused interactive elements show a 2dp outline in `colorSecondary` with 2dp offset. Never use the browser default outline style.

### 7.3 Disabled State

- Opacity: 38% on the element's normal foreground color.
- Background: `colorSurfaceVariant`.
- No ripple, no hover color change.
- Always include a `Tooltip` explaining why the element is disabled.

### 7.4 Active Player Highlight

The active player's panel receives:
- Left border: 4dp solid `colorActivePlayer` (`#C62828` / `#EF5350` dark)
- Background: `colorActivePlayerBg` (`#FFF5F5` / `#2A1515` dark)
- Score numeral: `textScoreActive` in `colorPrimary`
- Player name: `textPlayerName` in `colorSecondary`
- Dart count indicators: visible (filled dots for thrown darts, outline dots for remaining)

All other player panels:
- No left border
- Background: `colorSurface`
- Score numeral: `textScoreInactive` in `colorInactiveScore`
- Player name: `textPlayerName` in `colorOnSurfaceVariant`

### 7.5 Bust Feedback

When a bust occurs:
1. Snackbar appears at bottom: `colorErrorContainer` background, `colorOnErrorContainer` text, "BUST" label in `textHeadingSmall`, with the dart that caused the bust shown.
2. Snackbar auto-dismisses after 2 seconds.
3. Active player panel flashes `colorError` border once (300ms fade in, 500ms hold, 300ms fade out).
4. No full-screen overlay — the scoreboard must remain readable throughout.

### 7.6 Win State

When a player wins:
1. Full-screen win banner slides up from bottom (covers game board).
2. Winner name in `textDisplayLarge`, `colorWin`.
3. Final score and checkout dart shown.
4. Two actions: "Post-Game Summary" (primary) and "Play Again" (secondary).

### 7.7 Loading State

Async operations (load game, fetch history) show a centered `CircularProgressIndicator` in `colorPrimary`. The indicator sits on `colorBackground` — never on a card. List skeletons (shimmer placeholders) are used for the history list when initial data is loading.

---

## 8. Animation Guidelines

- **Duration:** 200ms for micro-interactions (button state changes, chip selection). 350ms for page transitions and panel expansions.
- **Easing:** `easeInOut` for symmetric animations. `easeOut` for items entering the screen. `easeIn` for items leaving.
- **Score update:** Score numerals animate with a counter rolldown (250ms, linear) only when the active player's score changes. Inactive player scores update instantly.
- **No decorative animations.** Never add particle effects, confetti, or idle animations that play during active gameplay. They interfere with focus.
- **Respect `MediaQuery.disableAnimations`.** When system-level reduced motion is on, all transitions collapse to instant.

---

## 9. Iconography

Use `material_symbols_outlined` (weight 300, opticalSize 24) for all icons. Do not mix icon sets.

| Icon | Usage |
|---|---|
| `sports_bar` or custom dartboard SVG | App icon, home page hero |
| `undo` | Undo last dart |
| `person` | Player |
| `leaderboard` | Statistics / leaderboard |
| `history` | Game history |
| `settings` | Settings |
| `add` | New player, add action |
| `edit` | Edit player |
| `delete` | Delete player (destructive — red tint) |
| `check_circle` | Checkout success, win |
| `error` | Bust, validation error |
| `arrow_back` | Navigation back |
| `close` | Dismiss dialog |
| `filter_list` | History filter |
| `expand_more` | Expandable sections |

All icons rendered at 24dp visual size, 48dp touch target. Icon-only buttons must have a `Tooltip` with a descriptive label.

---

## 10. Accessibility

- **Contrast ratios:** All text/background combinations meet WCAG 2.1 AA (4.5:1 for body text, 3:1 for large text ≥18sp Bold).
- **Score numerals** at 56sp+ meet large-text threshold; `colorInactiveScore` (#9CA3AF) on `colorSurface` (#FFFFFF) = 2.85:1. **Exception granted** for inactive score — it is intentionally de-emphasized and not a primary information carrier. Active score (`colorPrimary` on `colorSurface`) = 5.9:1. Meets AA.
- **Semantic labels:** All `IconButton` and image elements include `semanticsLabel`.
- **Screen reader order:** Scoreboard panels are announced in turn order (active player first). Dart segment grid announces as "Single [number]", "Double [number]", "Triple [number]".
- **Text scaling:** Layouts must not break at system text scale 1.4×. Score numerals may clip at 2.0× — this is acceptable given the sport context (scorer controls text scale setting).

---

## 11. Implementation Files (Code Phase)

When approved, implement in this order:

| File | Purpose |
|---|---|
| `pubspec.yaml` | Add `google_fonts: ^6.x` |
| `lib/core/utils/app_colors.dart` | `AppColors` class with all color token constants |
| `lib/core/utils/app_text_styles.dart` | `AppTextStyles` class with all typography token constants |
| `lib/core/utils/app_spacing.dart` | `AppSpacing` class with spacing scale constants |
| `lib/core/utils/app_theme.dart` | `AppTheme.light()` and `AppTheme.dark()` returning `ThemeData` |
| `lib/app/app.dart` | Replace inline `ThemeData` with `AppTheme.light()` / `AppTheme.dark()` |

No widget files change in the initial token implementation pass. Tokens are wired into `ThemeData` so that `Theme.of(context)` picks them up automatically via Material 3 color scheme. Widget-level migration (replacing hardcoded colors/styles) is a follow-on pass.
