# Design System — DartLodge

**Theme name:** Dual-Tone Performance Framework
**Last updated:** 2026-04-01
**Status:** Active specification

---

## 1. Overview & Creative North Star

The "Creative North Star" of this design system is **Technical Kineticism**.

This is a "two-speed" experience designed to mirror the psychology of a darts player: the surgical, high-adrenaline focus of the throw (Match Mode) and the calm, analytical reflection of the clubhouse (Admin/Nav Mode). We break the "template" look by oscillating between aggressive, sharp-edged precision and soft, high-end editorial layouts.

- **Match Boards:** "Kinetic Precision." Rounded but tight `radiusSmall` (8dp) cells, high-contrast neon accents, and oversized typography that feels like a broadcast scoreboard. Player cards use `radiusLarge` (16dp) with soft elevation.
- **Admin/Nav:** "Soft Luxury." `radiusLarge` / `radiusXLarge` / `radiusFull`, generous whitespace, and tonal layering that feels like a premium Swiss watch application.

The app supports both **light and dark themes**. The default at first launch is **light mode**; user preference is persisted via `settingsProvider`.

### P1 — The No-Line Rule
Standard 1px borders are strictly prohibited for sectioning. To define boundaries:
- **Tonal Shifts:** Place a `surfaceContainerLow` card against a `surface` background.
- **Negative Space:** Use the Spacing Scale (`spacing-8` to `spacing-12`) to create structural "voids" that act as invisible dividers.

Ghost borders (see §2.4) are allowed only on floating / elevated elements where tonal contrast alone is insufficient.

### P2 — Sharp / Soft Radius System
Use the right radius token for the right context:
- `radiusSmall` (8dp): Match board interactive cells (segment buttons, dart badges, checkout banner).
- `radiusLarge` (16dp): Player cards (both active and inactive), stats cards, homepage kinetic cards, roster grid container, admin inputs.
- `radiusXLarge` (24dp): Segmented button groups in config, admin modals.
- `radiusFull` (9999dp): Selection chips, pill buttons.
- `radiusMedium` (12dp): Primary CTA buttons (START GAME, Next Turn), config summary chip.
- `radiusNone` (0dp): Reserved for the **bust flash animation only** (temporary border-radius override during the 1.1s bust feedback cycle).

Never use arbitrary radii outside this set.

### P3 — State is Always Visible
The active player, current score, darts thrown this turn, and remaining outs are always on screen during play. Status is conveyed by color and position — never by icon alone.

---

## 2. Color Tokens

### 2.1 Dark Mode Palette

The dark palette is rooted in `surface` (#0c0e10), providing a deep, obsidian base that allows the neon `primaryFixed` (#00FFAB) to vibrate with intensity.

| Token | Hex | Usage |
|---|---|---|
| `surface` | `#0C0E10` | App scaffold background — Level 0 base |
| `surfaceContainerLowest` | `#000000` | Match Mode deepest background / most inset cells |
| `surfaceContainerLow` | `#111416` | Level-1 sections, active player card bg |
| `surfaceContainer` | `#171A1C` | Level-2 interactive cards, inactive player card bg |
| `surfaceContainerHigh` | `#1E2124` | Intermediate elevation |
| `surfaceContainerHighest` | `#242729` | Singles segment buttons, bottom bar bg, config summary chip |
| `surfaceBright` | `#2B2C2C` | Level-3 popovers / floating elements |
| `primary` | `#AFFFD1` | Primary action text / icons |
| `onPrimary` | `#004A2F` | Text on `primary` backgrounds |
| `primaryFixed` | `#00FFAB` | Brand neon — CTA fills, active player accent, dart badges |
| `primaryFixedDim` | `#00F2A2` | Hover / pressed neon state |
| `onPrimaryFixed` | `#002112` | Text on any neon fill — 8.9:1 contrast |
| `onSurface` | `#E7E5E5` | Primary body text and icons |
| `onSurfaceVariant` | `#ACABAA` | Secondary labels, metadata, placeholder text |
| `outlineVariant` | `#46484A` | Ghost border at 20% opacity only — see No-Line Rule |
| `outline` | `#767575` | Structural outlines when required |
| `secondary` | `#1FC46A` | Secondary actions (variant selection highlight) |
| `secondaryContainer` | `#004520` | "Latest played" card background |
| `onSecondaryContainer` | `#40D97C` | Text on `secondaryContainer` |
| `error` | `#EE7D77` | Bust indicator, validation errors |
| `onError` | `#490106` | Text on error-colored backgrounds |
| `errorContainer` | `#7F2927` | Bust snackbar background, error cards |
| `onErrorContainer` | `#FF9993` | Text inside error container |
| `scrim` | `#000000` | Modal backdrop at 80% opacity + 20px backdrop-blur |
| `kineticSplashColor` | `#0D00FFAB` | Ripple / ink-well splash — neon at 5% opacity |

### 2.2 Light Mode Palette

The light palette uses a warm neutral base with the same neon `primaryFixed` (#00FFAB) as the brand anchor.

| Token | Hex | Usage |
|---|---|---|
| `surface` | `#F9F9F9` | App scaffold background — Level 0 base |
| `surfaceContainerLowest` | `#FFFFFF` | Lifted cards / dialogs |
| `surfaceContainerLow` | `#F3F3F3` | Level-1 sections, active player card bg |
| `surfaceContainer` | `#EEEEEE` | Level-2 interactive cards, inactive player card bg |
| `surfaceContainerHighest` | `#E2E2E2` | Singles segment buttons, config summary chip |
| `primary` | `#006C46` | Primary action text / icons |
| `onPrimary` | `#FFFFFF` | Text on `primary` backgrounds |
| `primaryFixed` | `#00FFAB` | Brand neon — CTA fills, active player accent |
| `primaryFixedDim` | `#00E297` | Hover / pressed neon state |
| `onPrimaryFixed` | `#002112` | Text on any neon fill — 8.9:1 contrast |
| `onSurface` | `#1A1C1C` | Primary body text and icons |
| `onSurfaceVariant` | `#6B7070` | Secondary labels, metadata, placeholder text |
| `outlineVariant` | `#B9CBBE` | Ghost border at 20% opacity only |
| `error` | `#D32F2F` | Bust indicator, validation errors |
| `onError` | `#FFFFFF` | Text on error-colored backgrounds |
| `errorContainer` | `#FFEBEE` | Bust snackbar background, error cards |
| `onErrorContainer` | `#B71C1C` | Text inside error container |
| `kineticSplashColor` | `#0D00FFAB` | Ripple — neon at 5% opacity (same as dark) |

### 2.3 Surface Hierarchy & Nesting

Treat the UI as physical layers of glass.

| Level | Token | Dark Hex | Light Hex | Role |
|---|---|---|---|---|
| **0 — Base** | `surface` | `#0C0E10` | `#F9F9F9` | Global scaffold background |
| **1 — Sections** | `surfaceContainerLow` | `#111416` | `#F3F3F3` | Distinct content zones, active player card |
| **2 — Cards** | `surfaceContainer` | `#171A1C` | `#EEEEEE` | Interactive cards, inactive player card |
| **3 — Popovers** | `surfaceBright` | `#2B2C2C` | — | Floating elements, modals (dark mode) |

`surfaceContainerHighest` sits above Level 2 and is used for singles segment buttons and the bottom action bar.

### 2.4 Glass & Gradient Rule

For the homepage **Kinetic Card** decoration, use a linear gradient at **135°** from `#66232629` (dark warm grey, 40% opacity) to `#CC111416` (obsidian, 80% opacity), with a 1px ghost border at `#0DFFFFFF` (white, 5% opacity). This gives cards a "lithium-ion" depth regardless of light/dark mode.

For modal overlays: use `scrim` (`#000000`) at **80% opacity** + **20px backdrop-blur**.

### 2.5 The "Ghost Border" Fallback

If contrast is required for accessibility, use a "Ghost Border": `outlineVariant` at **10–20% opacity**. Never use 100% opacity. Standard usage:
- Active player card: `primaryFixed` @ 20%
- Inactive player card: `outlineVariant` @ 10%
- Dart badges: `primaryFixed` @ 20%

### 2.6 Semantic Aliases (game-specific)

These aliases exist in `AppColors` / `AppColorsDark` but game board widgets often reference `ColorScheme` tokens directly.

| Token | Light resolves to | Dark resolves to | Meaning |
|---|---|---|---|
| `activePlayerBg` | `surfaceContainerLow` (`#F3F3F3`) | `surfaceContainerHigh` (`#1E2124`) | Panel background tint for active player — *game board widgets use `cs.surfaceContainerLow` directly* |
| `inactiveScore` | `outlineVariant` (`#B9CBBE`) | `onSurfaceVariant` (`#ACABAA`) | Score numeral for non-active players — *game board widgets use `cs.onSurfaceVariant` directly* |
| `cricketClosed` | `primaryFixed` | `primaryFixed` | Cricket number closed indicator |
| `win` | `primary` | `primary` | Win banner, end-game highlight |
| `winContainer` | `surfaceContainerLow` | `surfaceContainerLow` | Win screen card background |

---

## 3. Typography Tokens

### 3.1 Font Families

| Family | Weight used | Source | Purpose |
|---|---|---|---|
| **Space Grotesk** | Medium (500), Bold (700) | `google_fonts` | Display, headlines, labels, scores — geometric, technical ("Oche Precision") |
| **Inter** | Regular (400), SemiBold (600), Medium (500) | `google_fonts` | Body text, titles, game segment buttons — neutral clarity |

Fallback stack: `system-ui, sans-serif`

### 3.2 Type Scale

| Token | Family | Weight | Size | Line height | Letter spacing | Usage |
|---|---|---|---|---|---|---|
| `display-lg` | Space Grotesk | Medium (500) | 3.5rem / 56px | 1.1 | -0.02em | Live scores in Match Mode, hero numerals |
| `headline-lg` | Space Grotesk | Bold (700) | 1.5rem / 24px | 32/24 | 0 | Section headers |
| `headline-md` | Space Grotesk | Bold (700) | 1.75rem / 28px | 1.2 | 0 | Screen titles |
| `headline-sm` | Space Grotesk | SemiBold (600) | 1.25rem / 20px | 28/20 | 0 | Sub-screen titles, dialogs |
| `title-md` | Inter | SemiBold (600) | 1.125rem / 18px | 1.4 | 0 | Subsection labels |
| `body-lg` | Inter | Regular (400) | 1rem / 16px | 24/16 | 0 | Primary body text |
| `body-md` | Inter | Regular (400) | 0.875rem / 14px | 1.5 | 0 | All administrative data, list descriptions |
| `body-sm` | Inter | Regular (400) | 0.75rem / 12px | 16/12 | 0 | Captions, metadata |
| `label-lg` | Space Grotesk | Medium (500) | 0.875rem / 14px | 20/14 | 0.05em | Upper label — navigation rows |
| `label-md` | Space Grotesk | Bold (700) | 0.75rem / 12px | 1.3 | 0.05em | Button text, chips, tab labels — ALL CAPS |
| `label-sm` | Space Grotesk | Bold (700) | 0.6875rem / 11px | 1.45 | 0.05em | Over-line text above a headline. Use `primaryFixed` color. |
| `player-name` | Inter | SemiBold (600) | 1rem / 16px | 20/16 | 0.075em | Player names in player selection roster |

**Game-specific score tokens:**

| Token | Family | Weight | Size | Usage |
|---|---|---|---|---|
| `textScoreActive` | Space Grotesk | Bold (700) | 80px | Active player score — 1-player game |
| `textScoreLarge` | Space Grotesk | Bold (700) | 64px | Active player score — 2-player game |
| `textScoreMedium` | Space Grotesk | Bold (700) | 48px | 3–4 player games; post-game summary, leaderboard top |
| `textScoreSmall` | Space Grotesk | Bold (700) | 36px | 5+ player games; history list scores, stat cards |
| `textScoreInactive` | Space Grotesk | Bold (700) | 56px | Inactive player scores |
| `textSegmentButton` | Inter | SemiBold (600) | 18px | Dart segment grid button numbers |
| `textMultiplierLabel` | Inter | Medium (500) | 11px | "DBL" / "TRP" labels on segment buttons |

**Dynamic score sizing rule (game board):**

Both active and inactive scores scale with player count.

| Player count | Active score token | Inactive score token |
|---|---|---|
| 1 | `textScoreActive` (80px) | `textScoreInactive` (56px) |
| 2 | `textScoreLarge` (64px) | `textScoreMedium` (48px) |
| 3–4 | `textScoreMedium` (48px) | `textScoreSmall` (36px) |
| 5+ | `textScoreSmall` (36px) | `textScoreSmall` (36px) |

### 3.3 Usage Rules

- `headline-md` screen titles use ALL CAPS. Apply via `toUpperCase()` on the string — do not rely on CSS `text-transform`.
- **Game board player names** use `label-md` (Space Grotesk Bold 12px) rendered ALL CAPS with `letterSpacing: 1.2`. Active players in `primaryFixed`, inactive in `onSurfaceVariant`.
- `player-name` (Inter 16px SemiBold) is for player selection roster cells, not the in-game scoreboard.
- `label-md` is the correct token for all interactive control labels — buttons, chips, tab labels.
- `label-sm` in `primaryFixed` color is used for "over-line" text (small text above a headline).
- Minimum rendered size is 11px. Never go below this.
- Score numerals must never truncate or wrap. Constrain the container width, not the text size.
- Never mix Space Grotesk and Inter within the same UI element (e.g. a single label line).

---

## 4. Spacing Scale

Base unit: **4dp**

| Token | Value | Usage |
|---|---|---|
| `space1` | 4dp | Minimum internal padding — icon gap, tight chip padding |
| `space2` | 8dp | Compact padding — list tile vertical padding, small gaps |
| `space3` | 12dp | No-divider gap between list items (replaces 1px lines) |
| `space4` | 16dp | Standard content padding (horizontal page margin) |
| `space5` | 20dp | Card internal padding (top/bottom), player selection horizontal padding |
| `space6` | 24dp | Section spacing within a screen |
| `space8` | 32dp | Section headers below previous content |
| `space10` | 40dp | Large visual break between major layout regions |
| `space12` | 48dp | Empty state illustration margin |
| `space16` | 64dp | Bottom padding for scrollable content above nav bar |

**Page horizontal margin:** `space4` (16dp) on both sides.
**Bottom safe area:** All scrollable content must include `space16` (64dp) bottom padding.

---

## 5. Elevation & Depth

### Tonal Layering (Admin views)

Avoid shadows in Admin views. Instead, stack tonal surface tokens to create an "inset" look. Hierarchy is expressed through tonal stepping alone — never through drop shadows or borders.

### Elevation Shadow (Active Player Card — Match Mode)

Active player cards use a soft directional shadow:
- **Color:** `Colors.black` at 50% opacity
- **Blur:** 24px
- **Offset:** 4px down
- **Spread:** -4px

This creates depth separation between the active and inactive player cards without a harsh border.

### The "Ghost Border" Fallback

If contrast is required for accessibility on a floating element, use a "Ghost Border": `outlineVariant` at **10–20% opacity**. Never use 100% opacity.

---

## 6. Shape Tokens

### Radius System

| Token | Value | Context | Notes |
|---|---|---|---|
| `radiusNone` | 0dp | **Bust flash animation only** | Temporarily overrides card radius during the 1.1s bust feedback cycle |
| `radiusSmall` | 8dp | **Match Board interactive cells** | Segment buttons, dart badges, checkout banner, stepper buttons |
| `radiusMedium` | 12dp | **Primary CTA buttons, config chip** | START GAME, Next Turn, config summary chip |
| `radiusLarge` | 16dp | Player cards, admin cards, stats cards, kinetic homepage cards, roster grid | Standard card radius for both match and admin |
| `radiusXLarge` | 24dp | Segmented button group containers, admin modals | Large CTA / sheet feel |
| `radiusFull` | 9999dp | Selection chips, pill buttons | Fully rounded |

**Rule:** Use the token that matches the component context above. Never use arbitrary values outside this set.

---

## 7. Components

### 7.1 Match-Speed Components (Kinetic Precision)

*Designed for high-contrast, peripheral-vision readability.*

**Score Input Buttons (Dart Grid Cells)**
- Border-radius: `radiusSmall` (8dp)
- Cell spacing: 4dp (between cells and rows)
- Minimum height: 48dp
- Splash: `kineticSplashColor` (#0D00FFAB)
- Text: `textSegmentButton` (18px Inter SemiBold)
- Tier differentiation:

| Tier | Background | Text color | Dots |
|---|---|---|---|
| Singles (10–20) | `surfaceContainerHighest` | `onSurface` | None |
| Doubles (D1–D20) | `surfaceContainerLow` | `onSurfaceVariant` | 2 × 4dp `primaryFixed` @ 70% |
| Triples (T1–T20) | `surfaceContainer` | `onSurfaceVariant` | 3 × 4dp `primaryFixed` @ 70% |
| MISS | `surfaceContainerLowest` | `onSurface` | None |
| Bull 25 (Outer) | `surfaceContainerHighest` | `onSurface` | `primaryFixed` @ 70% subtext |
| Bull 50 (Double) | `primaryFixed` | `onPrimaryFixed` | `onPrimaryFixed` subtext |

**Active Player Card**
- Border-radius: `radiusLarge` (16dp)
- Background: `surfaceContainerLow`
- Left accent bar: 4dp solid `primaryFixed`
- Border: 1px `primaryFixed` @ 20% opacity
- Shadow: `Colors.black` @ 50%, blur 24px, offset 4dp down, spread -4dp
- Player name: `label-md`, ALL CAPS, `letterSpacing: 1.2`, `primaryFixed` color
- Score numeral: dynamic sizing (see §3.2), `onSurface`, with `primaryFixed` @ 30% text shadow (10px blur)

**Inactive Player Card**
- Entire card wrapped in `Opacity(0.7)`
- Border-radius: `radiusLarge` (16dp)
- Background: `surfaceContainer`
- No left accent, no shadow
- Border: 1px `outlineVariant` @ 10% opacity
- Player name: `label-md`, ALL CAPS, `letterSpacing: 1.2`, `onSurfaceVariant` color
- Score numeral: dynamic sizing (see §3.2), `onSurfaceVariant`

**Game Status Bar**
- Background: `surfaceContainerLow` @ 50% opacity
- Bottom edge: 1px `outlineVariant` @ 10% opacity (exception to No-Line Rule — structural boundary at top of game area)
- Horizontal padding: 24dp
- Text: `label-sm` at 10px, `onSurfaceVariant`, letterSpacing 1.2
- Separator dots: 4×4dp circular, `outlineVariant` @ 30%
- Vertical dividers: 1dp × 16dp, `outlineVariant` @ 20%
- **Dart badges:** bg `primaryFixed` @ 10%, border 1px `primaryFixed` @ 20%, `radiusSmall` (8dp), padding `6h / 2v`, text `label-md` in `primaryFixed`

**Checkout Banner**
- Background: `surfaceContainer`
- Border-radius: `radiusSmall` (8dp)
- Padding: `16h / 12v`
- Left accent: 2dp solid `primaryFixed` (visible only when checkout is active)
- Label: `label-sm`, `onSurfaceVariant`, letterSpacing 1.2
- Suggestions: `label-lg`, `primaryFixed`
- Entry animation: 200ms opacity/size transition

**Bottom Action Bar**
- Background: `surfaceContainerHighest` @ 60% opacity
- Top edge: 1px `surfaceContainer` @ 30% opacity
- Padding: `12h / 12v / 16 bottom` (with SafeArea)
- **Undo button:** 56×56dp, `radiusLarge` (16dp), outlined style
- **Next Turn button:** `FilledButton`, `primaryFixed` bg, `onPrimaryFixed` text, `radiusMedium` (12dp), min-height 56dp

**The "Oche" Progress Bar**
- Height: 2px line across the top of the Match Board
- Color: `primaryFixed`
- No rounded ends (`radiusNone`)
- Animation: linear fill only

### 7.2 Admin-Speed Components (Soft Luxury)

*Designed for tactile comfort and high-end feel.*

**Kinetic Homepage Game Card**
- Height: 80dp
- Background: `kineticCardDecoration()` — gradient `#66232629` → `#CC111416`, 135°, 1px `#0DFFFFFF` ghost border
- Border-radius: `radiusLarge` (16dp)
- Icon container: 44×44dp, `radiusLarge`, `primaryFixed` @ 12% bg, 1px `primaryFixed` @ 25% border, icon 22dp
- Label: uppercase, `label-md` + w700 + letterSpacing 0.5, `onSurface`
- Subtitle: uppercase, `label-sm`, `onSurfaceVariant`, letterSpacing 0.8
- Chevron icon: 20dp, `onSurfaceVariant`
- Splash: `kineticSplashColor`
- Gap between cards: 12dp

**Flat Navigation Row (Homepage)**
- Padding: `4h / 14v`
- Icon: 20dp, `onSurfaceVariant`
- Label: uppercase, `label-lg` + letterSpacing 0.8
- Descriptor: uppercase, `label-sm`, `onSurfaceVariant`, letterSpacing 0.8
- Ink-well: `radiusLarge`, splash `onSurface` @ 6%, highlight `onSurface` @ 3%
- Gap between rows: 4dp

**Primary Action Button (START GAME, primary CTAs)**
- Border-radius: `radiusMedium` (12dp)
- Height: 56dp, width: full
- Background: `primaryFixed` (`#00FFAB`)
- Text: `onPrimaryFixed` (`#002112`) — `label-md`, ALL CAPS, letterSpacing 0.8
- Disabled: 38% opacity

**Segmented Button Group (Config)**
- Container background: `surfaceContainerLow`, padding 6dp, `radiusXLarge` (24dp)
- Button height: 48dp, inner `radiusLarge` (16dp)
- Selected: `primaryFixed` bg, `onPrimaryFixed` text

**Config Summary Chip (Player Selection)**
- Min height: 48dp
- Background: `surfaceContainerHighest`
- Padding: `20h / 8v`
- Border-radius: `radiusMedium` (12dp)
- Content: icon + config text + edit icon
- Text: `label-md`, `onSurface`

**Active Lineup Card (Selected player in Player Selection)**
- Height: 56dp
- Background: `surfaceContainerLow`
- Border-radius: `radiusLarge` (16dp)
- Border: 1px `primaryFixed` @ 20% opacity
- Content: drag handle, avatar, position badge, name, avg score, remove button
- Position badge: `primaryFixed` bg for player 1, `outlineVariant` for others

**Roster Grid (Player Selection)**
- 4-column grid layout
- Container: `surfaceContainerLow` bg, `radiusLarge` (16dp)
- Cell size: ~screenWidth ÷ 4 (square)
- Player cell: 40dp avatar (circle with initials), name below
- Selected state: check circle overlay at 60% opacity
- Disabled state: 40% opacity

**Stats Cards**
- Border-radius: `radiusLarge` (16dp)
- Background: `surfaceContainerLow`
- No borders — tonal background provides hierarchy

**Selection Chips**
- Border-radius: `radiusFull` (pill)
- Unselected: `surfaceContainerHighest` background, `onSurfaceVariant` text
- Selected: `primaryFixed` background, `onPrimaryFixed` text

**Secondary Button**
- Background: transparent
- Border: Ghost Border — `outlineVariant` at 20% opacity
- Text: `onSurface` — `label-md`, ALL CAPS
- Border-radius: `radiusXLarge` (24dp)
- Padding: 14dp vertical, 24dp horizontal

**Input Fields**
- Background: `surfaceContainerLow`
- Border-radius: `radiusLarge` (16dp)
- Focus indicator: 2dp bottom bar in `primary` expanding from center
- Label: `label-sm` — Space Grotesk Bold, ALL CAPS — at 60% opacity (unfocused), 100% (focused)

### 7.3 Performance Graph

- Plot area: `surfaceContainerLow` background
- Trend line: gradient stroke from `primary` to `primaryFixedDim`
- No grid lines — use `surfaceContainerHigh` for axis ticks only

### 7.4 Overlays & Modals

- Backdrop: `scrim` (`#000000`) at **80% opacity** + **20px backdrop-blur**
- Sheet / dialog surface: `surfaceBright` (`#292C30`)
- Border-radius: `radiusXLarge` (24dp)
- Entry animation: slide up 200ms `easeOut`; dismiss: slide down 200ms `easeIn`

---

## 8. Do's and Don'ts

### Do

- **Asymmetric Spacing (Admin):** Use `spacing-16` for top padding and `spacing-8` for sides for a "gallery" feel.
- **Context-appropriate radii:** Use `radiusSmall` for game board cells, `radiusLarge` for cards, `radiusMedium` for primary buttons, `radiusFull` for chips.
- **Typographic Hierarchy:** Use `label-sm` in `primaryFixed` color for over-line text to ground the technical feel.
- **No-Line Separation:** Replace dividers with a 12dp gap (`space3`) or a subtle `surface` → `surfaceContainerLow` tonal shift.
- Apply `primaryFixed` (`#00FFAB`) as the single brand neon accent.
- Use the ghost border (`outlineVariant` at 10–20% opacity) only when tone alone cannot provide a boundary.
- Use the 4dp `primaryFixed` strike bar on the left edge of a card for "active" / "selected" state.
- Use `kineticSplashColor` (#0D00FFAB) as the ripple color on all interactive elements.

### Don't

- **No 1px Lines:** Never use a line to separate list items. Use a 12dp gap or a tonal surface shift.
- **No Pure Black:** Avoid `#000000` except for `surfaceContainerLowest` in Match Mode. Use `surface` as the main canvas to maintain depth.
- **No arbitrary radii:** Stick to the six defined tokens. Never invent values like 4dp, 6dp, or 20dp.
- Don't use `primaryFixed` (`#00FFAB`) as text color on dark backgrounds — pair it with `onPrimaryFixed` (`#002112`) on neon fills.
- Don't use `outlineVariant` at full (100%) opacity.
- Don't add shadows beyond the active-player-card shadow spec (§5).
- Don't mix Space Grotesk and Inter within the same UI element.
- Don't use `radiusNone` outside the bust flash animation.

---

## 9. Minimum Tap Target Rules

**Absolute minimum:** 48×48dp for any interactive element.

| Element | Minimum touch target | Recommended visual size |
|---|---|---|
| Segment cell — 3-cell bar (Practice, Cricket input) | 56dp height × ⅓ row width | 56dp height |
| Segment cell — 10-column grid (X01, Catch-40, Checkout Practice) | 48dp height × ~39dp width | 48dp height; width = screen width ÷ 10 |
| Undo button | 56×56dp | 56×56dp |
| Next Turn button | 56dp height, full width | 56dp height |
| Chip / filter pill | 48dp height × auto width | 36dp visual height |
| Player row in selection list | 56dp height | 56dp |
| Bottom sheet drag handle | 48×48dp centered tap area | 4×32dp visual bar |
| Dialog action button | 48dp height | 40dp visual |
| FAB (start game) | 56×56dp | 56×56dp |
| Homepage game card | 80dp height, full width | 80dp height |
| Flat nav row | 48dp touch height | 48dp visual |

**Game board special rules:**

**3-cell bar:** cells expand to one-third of available width. Minimum 56dp height. No exception.

**10-column contiguous grid** (X01 Board, Catch-40, Checkout Practice): 10 cells per row keeps all 20 numbers in 2 rows per tier. On a 390dp device this yields ~39dp cell widths — an **accepted exception** because cells are densely packed with no gaps, and minimum cell height is 48dp. Every cell must carry a full `semanticsLabel`.

---

## 10. Interactive States

### 10.1 Pressed State

Ripple color: `kineticSplashColor` (`#0D00FFAB`, neon @ 5%). No scale transforms — avoid "pop" animations during rapid dart entry.

**Kinetic Shift:** Primary buttons shift to `primaryFixedDim` (`#00E297`) background on press.

### 10.2 Focused State (keyboard / accessibility)

2dp outline in `primaryFixed` (`#00FFAB`) with 2dp offset. Never use the browser default outline style.

### 10.3 Disabled State

- Opacity: 38% on the element's normal foreground color.
- Background: `surfaceContainerHighest`.
- No ripple. Always include a `Tooltip` explaining why disabled.

### 10.4 Active Player Highlight

Active player panel:
- Left border: 4dp solid `primaryFixed`
- Border: 1px `primaryFixed` @ 20% opacity
- Background: `activePlayerBg` (`surfaceContainerLow`)
- Shadow: blur 24px, offset 4dp down, spread -4dp
- Score numeral: dynamic size (see §3.2), `onSurface` color with 30% opacity text shadow (10px blur)
- Player name: `player-name` style, ALL CAPS, `primaryFixed` color, letterSpacing 1.2

All other player panels:
- No left border, no shadow
- Background: `surfaceContainer`
- Border: 1px `outlineVariant` @ 10%
- Score numeral: `textScoreInactive`, `onSurfaceVariant`
- Player name: `player-name` style, ALL CAPS, `onSurfaceVariant` color

### 10.5 Bust Feedback

1. Snackbar: `errorContainer` background, `onErrorContainer` text, "BUST" in `headline-sm`.
2. Auto-dismisses after 2 seconds.
3. Active player card animation (1.1s total):
   - Background transitions to `errorContainer` @ 12% opacity (300ms in)
   - Border becomes 3px solid `error` (300ms in)
   - Card border-radius temporarily overrides to `radiusNone` (0dp) during flash
   - Hold for 500ms, then fade back out over 300ms
4. No full-screen overlay — scoreboard remains readable throughout.

### 10.6 Win State

1. Full-screen win banner slides up from bottom (covers game board).
2. Winner name in `display-lg`, `win` color.
3. Two actions: "Post-Game Summary" (primary) and "Play Again" (secondary).

### 10.7 Loading State

Centered `CircularProgressIndicator` in `primary`. Sits on `surface`. List skeletons (shimmer placeholders) for history list initial load.

---

## 11. Animation Guidelines

- **Duration:** 200ms for micro-interactions. 350ms for page transitions and panel expansions.
- **Easing:** `easeInOut` for symmetric animations. `easeOut` entering. `easeIn` leaving.
- **Score update:** Counter rolldown (250ms, linear) for active player score only. Inactive scores update instantly.
- **No decorative animations** during active gameplay. No particles, confetti, or idle animations.
- **Respect `MediaQuery.disableAnimations`.** All transitions collapse to instant when reduced motion is on.

---

## 12. Iconography

Use `material_symbols_outlined` (weight 300, opticalSize 24) for all icons.

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
| `delete` | Delete player (destructive — error tint) |
| `check_circle` | Checkout success, win |
| `error` | Bust, validation error |
| `arrow_back` | Navigation back |
| `close` | Dismiss dialog |
| `filter_list` | History filter |
| `expand_more` | Expandable sections |

All icons at 24dp visual size, 48dp touch target. Icon-only buttons must have a `Tooltip`.

---

## 13. Accessibility

- **Contrast ratios:** All text/background combinations meet WCAG 2.1 AA (4.5:1 body, 3:1 large text ≥18sp Bold).
- **Primary neon fill:** `primaryFixed` (`#00FFAB`) must only carry text in `onPrimaryFixed` (`#002112`) — 8.9:1 contrast.
- **Score numerals** at 48px+ meet large-text threshold. `onSurfaceVariant` on `surfaceContainer` meets AA for large text. Active score (`onSurface`) = high contrast.
- **Semantic labels:** All `IconButton` and image elements include `semanticsLabel`.
- **Screen reader order:** Scoreboard panels announced in turn order (active player first). Segment grid announces as "Single [number]", "Double [number]", "Triple [number]".
- **Text scaling:** Layouts must not break at 1.4×. Score numerals may clip at 2.0× — accepted given sport context.

---

## 14. Implementation Files (Code Phase)

| File | Purpose |
|---|---|
| `lib/core/utils/app_colors.dart` | `AppColors` / `AppColorsDark` — all color token constants, both light and dark |
| `lib/core/utils/app_text_styles.dart` | `AppTextStyles` — Space Grotesk (display/headlines/labels/scores) + Inter (body/titles/segment buttons) |
| `lib/core/utils/app_theme.dart` | `AppTheme.light()` / `AppTheme.dark()` — radius tokens, `kineticCardDecoration()`, `kineticSplashColor` |
| `lib/core/utils/app_spacing.dart` | Spacing constants (`space1` … `space16`) |
| `lib/app/app.dart` | `themeMode` read from `settingsProvider`, defaults to `ThemeMode.light` |
