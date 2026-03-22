# Design System — my-darts

**Theme name:** Kinetic Precision
**Last updated:** 2026-03-22
**Status:** Specification (pre-implementation)

---

## 1. Design Principles

### North Star: Kinetic Architect

The visual language is **Zero-Radius Brutalism** — editorial precision meets technical luxury. Every surface is intentional. Every edge is clean. The palette pairs neon green with charcoal-white in a way that reads as high-performance tooling, not a consumer app.

### P1 — Zero-Radius Brutalism
No border-radius on any component by default. Corners are square. Containment is expressed through tonal surface shifts and spacing — never by rounding edges. If a radius is applied, it is a deliberate exception, not a default.

### P2 — No-Line Rule
Never use 1px opaque borders as dividers. Surface hierarchy is communicated by tonal steps between surface tokens (`surface` → `surfaceContainerLow` → `surfaceContainerHighest`). When a ghost border is genuinely needed for a floating element, use `outlineVariant` at 20% opacity — never 100%.

### P3 — Technical Luxury
The aesthetic borrows from precision instruments and editorial sport media — not consumer dashboards. Bold, uppercase labels. Asymmetric accent bars. Neon `#00FFAB` on charcoal-white `#1A1C1C`. Whitespace is structural, not decorative.

### P4 — State is always visible
The active player, current score, darts thrown this turn, and remaining outs are always on screen during play. No action collapses this information. Status is conveyed by color and position — never by icon alone.

---

## 2. Color Tokens

### 2.1 Palette (Light Mode)

| Token | Hex | Usage |
|---|---|---|
| `surface` | `#F9F9F9` | App scaffold background (Level 0) |
| `surfaceContainerLow` | `#F3F3F3` | Distinct content zones / sections (Level 1) |
| `surfaceContainer` | `#EEEEEE` | Secondary navigation backgrounds, deep inset elements |
| `surfaceContainerLowest` | `#FFFFFF` | Pure white — "lifted" cards, dialogs (Level 2) |
| `surfaceContainerHighest` | `#E2E2E2` | Pressed states, inactive chips, progress track |
| `primary` | `#006C46` | Primary action text/icons (dark green for accessibility) |
| `primaryContainer` | `#00FFAB` | Brand neon — CTA button fills, active player accent |
| `onPrimaryFixed` | `#002112` | Text on `primaryContainer` (neon fill) |
| `primaryFixedDim` | `#00E297` | Hover / pressed state of `primaryContainer` |
| `onSurface` | `#1A1C1C` | Primary body text and icons |
| `outlineVariant` | `#B9CBBE` | Ghost borders at 20% opacity only — see No-Line Rule |
| `colorError` | `#D32F2F` | Bust indicator, validation errors |
| `colorOnError` | `#FFFFFF` | Text on error-colored backgrounds |
| `colorErrorContainer` | `#FFEBEE` | Bust snackbar background, error cards |
| `colorOnErrorContainer` | `#B71C1C` | Text inside error container |
| `colorScrim` | `#000000` | Modal backdrop at 80% opacity + 20px backdrop-blur |

### 2.2 Surface Hierarchy & Nesting

Treat the UI as a series of stacked, precision-cut physical layers. Hierarchy is achieved by "stacking" tones — not shadows or borders.

| Level | Token | Hex | Role |
|---|---|---|---|
| **0 — Base** | `surface` | `#F9F9F9` | Global scaffold background |
| **1 — Sections** | `surfaceContainerLow` | `#F3F3F3` | Distinct content zones |
| **2 — Active Cards** | `surfaceContainerLowest` | `#FFFFFF` | "Lift" through purity — white card on level-1 background creates a sharp, natural distinction without shadows |

### 2.3 Glass & Gradient Rule

To prevent the high-contrast palette from feeling flat:

- **Signature CTAs:** Use a linear gradient from `primary` (`#006C46`) to `primaryContainer` (`#00FFAB`) at a **135-degree angle** for hero call-to-action buttons.
- **Overlays:** Use `surface` (`#F9F9F9`) at **80% opacity** + **20px backdrop-blur** for floating modals or navigation bars to maintain Kinetic transparency.

### 2.4 Palette (Dark Mode)

> **Dark mode: TBD — to be specified in a future revision.**
> The Kinetic Precision spec covers Light Mode only. The tokens below are carried over from the prior "Court Ready" theme as a placeholder and should not be treated as final.

| Token | Hex | Usage |
|---|---|---|
| `colorBackground` | `#0F1117` | App scaffold background |
| `colorSurface` | `#1C1F26` | Cards, sheets |
| `colorSurfaceVariant` | `#272B34` | Input fields, inactive chips |
| `colorPrimary` | `#00E297` | Neon green (dim) for legibility on dark |
| `colorOnPrimary` | `#002112` | Text on primary buttons |
| `colorPrimaryContainer` | `#006C46` | Selection chips in dark mode |
| `colorOnPrimaryContainer` | `#00FFAB` | Text inside primary container |
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

### 2.5 Semantic Aliases (game-specific)

| Token | Resolves to | Meaning |
|---|---|---|
| `colorActivePlayer` | `primaryContainer` (`#00FFAB`) | Left border and tint on active player panel |
| `colorActivePlayerBg` | `surfaceContainerLow` (`#F3F3F3`) / dark: `#2A1515` | Panel background tint for active player |
| `colorInactiveScore` | `outlineVariant` (`#B9CBBE`) / dark: `#6B7280` | Score numeral for non-active players |
| `colorBust` | `colorError` | Bust flash overlay, snackbar |
| `colorCricketClosed` | `#00FFAB` | Cricket number closed indicator (neon accent) |
| `colorCricketLeading` | `primaryContainer` | Cricket player leading indicator |
| `colorWin` | `primary` (`#006C46`) | Win banner, end-game highlight |
| `colorWinContainer` | `surfaceContainerLow` / dark: `#1B3A1C` | Win screen card background |

---

## 3. Typography Tokens

### 3.1 Font Families

| Family | Weight used | Source | Purpose |
|---|---|---|---|
| **Space Grotesk** | Medium (500), Bold (700) | `google_fonts` | Display, headlines, labels — geometric, technical ("Architect" font) |
| **Inter** | Regular (400), SemiBold (600) | `google_fonts` | Body text, titles — neutral, maximum legibility at data density |

Fallback stack: `system-ui, sans-serif`

> **Game-specific override (TBD):** Score display numerals (active player score, inactive scores) may retain **Oswald Bold** as a sub-theme override to preserve the condensed, athletic aesthetic for large numeric readouts. This is under review and will be confirmed in `SCREEN_SPECS.md` before implementation.

### 3.2 Type Scale

| Token | Family | Weight | Size | Line height | Letter spacing | Case | Usage |
|---|---|---|---|---|---|---|---|
| `display-lg` | Space Grotesk | Medium | 3.5rem | 1.1 | -0.02em | — | Page titles, hero numerals |
| `headline-md` | Space Grotesk | Bold | 1.75rem | 1.2 | 0 | — | Section headers, dialog titles, card headers |
| `title-md` | Inter | SemiBold | 1.125rem | 1.4 | 0 | — | Subsection labels, player names in scoreboard |
| `body-md` | Inter | Regular | 0.875rem | 1.5 | 0 | — | Primary body content, list descriptions |
| `label-md` | Space Grotesk | Bold | 0.75rem | 1.3 | 0.05em | ALL CAPS | Button text, chips, tags, tab labels |

**Game-specific score tokens** (retained from prior spec, pending Oswald TBD resolution):

| Token | Family | Weight | Size | Line height | Usage |
|---|---|---|---|---|---|
| `textScoreActive` | Oswald / Space Grotesk Bold | Bold | 80sp | 80sp | Active player score |
| `textScoreInactive` | Oswald / Space Grotesk Bold | Bold | 56sp | 56sp | Inactive player scores |
| `textScoreMedium` | Oswald / Space Grotesk Bold | Bold | 48sp | 52sp | Post-game summary, leaderboard top |
| `textScoreSmall` | Oswald / Space Grotesk Bold | Bold | 36sp | 40sp | History list scores, stat cards |
| `textSegmentButton` | Inter | SemiBold | 18sp | 18sp | Dart segment grid button numbers |
| `textMultiplierLabel` | Inter | Medium | 11sp | 14sp | "DBL" / "TRP" labels on segment buttons |

### 3.3 Usage Rules

- Never use score display tokens for non-numeric content.
- `title-md` (player names in scoreboard) must always render in ALL CAPS via `toUpperCase()` on the string — do not rely on CSS `text-transform`.
- `label-md` (Space Grotesk Bold, ALL CAPS) is the correct token for all interactive control labels — buttons, chips, tab labels. Do not substitute Inter for label text.
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

**Named layout tokens (Kinetic Precision additions):**

| Token | rem | px equivalent | Usage |
|---|---|---|---|
| `spacing.8` | 1.75rem | ≈ 28px | Intra-component gap for grouped elements |
| `spacing.10` | 2.25rem | ≈ 36px | Data-point separation within cards and data grids |
| `spacing.16` | 3.5rem | ≈ 56px | Section separation, editorial card-to-card gap |
| `spacing.24` | 5.5rem | ≈ 88px | Hero section top margin, major layout region separation |

**Page horizontal margin:** `space4` (16dp) on both sides.
**Bottom safe area:** All scrollable content must include `space16` (64dp) bottom padding to clear the system navigation bar on devices that use on-screen gesture navigation.

---

## 5. Shape Tokens

### Zero-Radius Brutalism

`radiusNone` (0dp) is the **default for all components**. Do not add border-radius without a documented reason.

| Token | Value | Status | Notes |
|---|---|---|---|
| `radiusNone` | 0dp | **Active — default** | Buttons, cards, inputs, sheets, dialogs |
| `radiusXSmall` | 4dp | Deprecated | Do not use in new work |
| `radiusSmall` | 8dp | Deprecated | Do not use in new work |
| `radiusMedium` | 12dp | Deprecated | Do not use in new work |
| `radiusLarge` | 16dp | Deprecated | Do not use in new work |
| `radiusXLarge` | 24dp | Deprecated | Do not use in new work |
| `radiusFull` | 9999dp | Deprecated | Do not use in new work |

**Ghost Border fallback:** When a floating element requires a boundary for legibility, use `outlineVariant` (`#B9CBBE`) at **20% opacity**. Never at 100% opacity.

**Ambient shadow:** `0px 20px 40px rgba(26,28,28,0.04)` — 4% opacity only. Do not use heavier shadows.

**Contiguous grid containers:** Game board input grids (X01, Practice) span the full screen width (edge-to-edge) and use `radiusNone` to maximize tap area and visual clarity. Cell separators use tonal surface shifts — not 1px opaque hairlines.

---

## 6. Components

### 6.1 Buttons

**Primary Button**
- Background: `primaryContainer` (`#00FFAB`)
- Label: `onPrimaryFixed` (`#002112`) — `label-md` (Space Grotesk Bold, ALL CAPS, 0.05em letter-spacing)
- Border-radius: 0dp (`radiusNone`)
- Padding: 14dp vertical, 24dp horizontal
- No shadow

**Secondary Button**
- Background: transparent
- Border: 1px Ghost Border — `outlineVariant` (`#B9CBBE`) at 20% opacity
- Label: `onSurface` (`#1A1C1C`) — `label-md`, ALL CAPS
- Border-radius: 0dp
- Padding: 14dp vertical, 24dp horizontal

**Hover / Pressed Interaction**
- Primary: background shifts to `primaryFixedDim` (`#00E297`); element offsets **2px up and 2px right** ("kinetic" shift)
- Secondary: border opacity increases to 60%
- No scale transforms

### 6.2 Input Fields

- Background: `surfaceContainerLow` (`#F3F3F3`)
- Border-radius: 0dp
- Bottom-bar focus indicator: 2dp solid `primary` (`#006C46`) that **expands from the center** on focus — replaces any full-border focus ring
- Unfocused: no visible border (tonal background only)
- Label: `label-sm` — Space Grotesk, Bold, ALL CAPS — at 60% opacity (unfocused), 100% opacity (focused)

### 6.3 Cards & Data Grids

- Background: `surfaceContainerLow` (`#F3F3F3`)
- Border-radius: 0dp
- No internal dividers — use `spacing.8` (1.75rem) or `spacing.10` (2.25rem) to separate data points within a card
- Accent bar: 4px vertical left border in `primary` (`#006C46`) to denote focus on active list items or selected cards
- Padding: `space5` (20dp) internal, `space4` (16dp) horizontal page margin

### 6.4 Kinetic Progress Bar

- Track height: 2px
- Track color: `surfaceContainerHighest` (`#E2E2E2`)
- Fill color: `primaryContainer` (`#00FFAB`)
- Ends: squared (no border-radius)
- No animation easing on fill — linear only

### 6.5 Overlays & Modals

- Backdrop: `colorScrim` (`#000000`) at **80% opacity** + **20px backdrop-blur**
- Sheet / dialog surface: `surfaceContainerLowest` (`#FFFFFF`)
- Border-radius: 0dp — no rounded bottom-sheet handles
- Entry animation: slide up 200ms `easeOut`; dismiss: slide down 200ms `easeIn`

---

## 7. Do's and Don'ts

### Do

- **Embrace White Space:** Use the `spacing.16` (3.5rem) and `spacing.24` (5.5rem) tokens to create an editorial, "high-end gallery" feel.
- **Align to the Grid:** Every element must snap to the spacing scale. Precision is our brand.
- **High Contrast:** Use `onSurface` (`#1A1C1C`) for all primary text to ensure maximum readability against the light background.
- Use tonal surface steps (`surface` → `surfaceContainerLow` → `surfaceContainerLowest`) to create hierarchy without borders.
- Apply `primaryContainer` (`#00FFAB`) as the single brand neon accent — CTA fills, progress fills, active player indicators.
- Use the ghost border (`outlineVariant` at 20% opacity) only when a floating element needs a boundary that tone alone cannot provide.
- Use the 4px `primary` accent bar on the left edge of a card to communicate "active" or "selected" state.

### Don't

- **No Border Radius:** Never use `border-radius`. Not even 2px. All corners must be 90 degrees.
- **No Generic Grays:** Avoid middle-of-the-road grays. Stick to the tonal surface tokens provided (`surface`, `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerLowest`, `surfaceContainerHighest`) to maintain the "Kinetic Architect" warmth.
- **No Center Alignment:** Use left-aligned "Editorial" layouts. Center-alignment feels like a template; asymmetrical left-alignment feels designed.
- Don't use 1px opaque borders as dividers — ever.
- Don't use `primaryContainer` (`#00FFAB`) as text color on white — it fails WCAG contrast. Always pair with `onPrimaryFixed` (`#002112`) on neon fills.
- Don't add drop shadows beyond the ambient shadow (`rgba(26,28,28,0.04)` at 4% opacity).
- Don't mix Space Grotesk and Inter within the same UI element (e.g. a single label line).
- Don't use `outlineVariant` at full (100%) opacity.

---

## 8. Minimum Tap Target Rules

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

## 9. Interactive States

### 9.1 Pressed State

All pressable surfaces use a ripple / ink effect constrained to the element boundary. Ripple color is `onSurface` at 12% opacity (light) / 16% opacity (dark). No scale transforms on press — avoid "pop" animations during rapid dart entry.

### 9.2 Focused State (keyboard / accessibility)

Focused interactive elements show a 2dp outline in `primaryContainer` (`#00FFAB`) with 2dp offset. Never use the browser default outline style.

### 9.3 Disabled State

- Opacity: 38% on the element's normal foreground color.
- Background: `surfaceContainerHighest`.
- No ripple, no hover color change.
- Always include a `Tooltip` explaining why the element is disabled.

### 9.4 Active Player Highlight

The active player's panel receives:
- Left border: 4dp solid `colorActivePlayer` (`primaryContainer` / `#00FFAB`)
- Background: `colorActivePlayerBg` (`surfaceContainerLow` / dark: `#2A1515`)
- Score numeral: `textScoreActive` in `primary` (`#006C46`)
- Player name: `title-md` in `onSurface`
- Dart count indicators: visible (filled dots for thrown darts, outline dots for remaining)

All other player panels:
- No left border
- Background: `surface`
- Score numeral: `textScoreInactive` in `colorInactiveScore`
- Player name: `title-md` in `onSurface` at 60% opacity

### 9.5 Bust Feedback

When a bust occurs:
1. Snackbar appears at bottom: `colorErrorContainer` background, `colorOnErrorContainer` text, "BUST" label in `headline-md`, with the dart that caused the bust shown.
2. Snackbar auto-dismisses after 2 seconds.
3. Active player panel flashes `colorError` left border once (300ms fade in, 500ms hold, 300ms fade out).
4. No full-screen overlay — the scoreboard must remain readable throughout.

### 9.6 Win State

When a player wins:
1. Full-screen win banner slides up from bottom (covers game board).
2. Winner name in `display-lg`, `colorWin`.
3. Final score and checkout dart shown.
4. Two actions: "Post-Game Summary" (primary) and "Play Again" (secondary).

### 9.7 Loading State

Async operations (load game, fetch history) show a centered `CircularProgressIndicator` in `primary`. The indicator sits on `surface` — never on a card. List skeletons (shimmer placeholders) are used for the history list when initial data is loading.

---

## 10. Animation Guidelines

- **Duration:** 200ms for micro-interactions (button state changes, chip selection). 350ms for page transitions and panel expansions.
- **Easing:** `easeInOut` for symmetric animations. `easeOut` for items entering the screen. `easeIn` for items leaving.
- **Score update:** Score numerals animate with a counter rolldown (250ms, linear) only when the active player's score changes. Inactive player scores update instantly.
- **No decorative animations.** Never add particle effects, confetti, or idle animations that play during active gameplay. They interfere with focus.
- **Respect `MediaQuery.disableAnimations`.** When system-level reduced motion is on, all transitions collapse to instant.

---

## 11. Iconography

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

## 12. Accessibility

- **Contrast ratios:** All text/background combinations meet WCAG 2.1 AA (4.5:1 for body text, 3:1 for large text ≥18sp Bold).
- **Primary neon fill:** `primaryContainer` (`#00FFAB`) must only carry text in `onPrimaryFixed` (`#002112`) — contrast ratio 8.9:1. Never use `#00FFAB` as text color on white surfaces.
- **Score numerals** at 56sp+ meet large-text threshold; `colorInactiveScore` (`outlineVariant` `#B9CBBE`) on `surface` (`#F9F9F9`) = approximately 2.7:1. **Exception granted** for inactive score — it is intentionally de-emphasized and not a primary information carrier. Active score (`primary` `#006C46` on `surfaceContainerLowest` `#FFFFFF`) = 7.8:1. Meets AAA.
- **Semantic labels:** All `IconButton` and image elements include `semanticsLabel`.
- **Screen reader order:** Scoreboard panels are announced in turn order (active player first). Dart segment grid announces as "Single [number]", "Double [number]", "Triple [number]".
- **Text scaling:** Layouts must not break at system text scale 1.4×. Score numerals may clip at 2.0× — this is acceptable given the sport context (scorer controls text scale setting).

---

## 13. Implementation Files (Code Phase)

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
