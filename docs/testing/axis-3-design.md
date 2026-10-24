# Axis 3 — Visual design — detailed test plan

> **Status: pass 1 (checklists per dimension).** Axis 3 is fundamentally *visual*:
> pass 1 produces the **compliance checklists** + the **gallery of surfaces to capture**;
> **pass 2** (deferred) captures each surface in Pixel 6a portrait and inspects it against the checklists.
> Parent: `docs/plans/2026-06-19-1.0-verification-plan.md` §5. Execution mechanics: see
> `axis-1-correctness.md` §2 (rails, Pixel 6a viewport 412×915, semantics gotchas).

---

## 1. Purpose & oracles

Verify that every screen follows the design system and that the whole is consistent.
**Method = screenshot + eyeball inspection against tokens** (no DOM asserts).

- Oracle: `docs/design/DESIGN_SYSTEM.md` (realigned #585) + `lib/core/utils/{app_colors,app_text_styles,app_spacing}.dart` + `lib/core/theme/app_theme.dart`.
- Rail: `[web]` for token compliance + consistency (Pixel 6a portrait, light AND dark); `[device]` for real physical readability at a distance (#477) — not reproducible on web (DPR 1).

---

## 2. Dimensions

### 2.1 Colour tokens
**Compliance checklist**
- [ ] Active score = `onSurface`; inactive/opponent = `onSurfaceVariant` (+ inactive card `Opacity(0.7)`); practice target = `primary`.
- [ ] `label-sm` over-line above a hero = `primaryFixed` (`#00FFAB`), not `onSurfaceVariant`.
- [ ] `primary` adapts to the theme (light `#006D45` / dark `#AFFFD1`); neon `primaryFixed` constant across themes; text on a neon fill = `onPrimaryFixed`.
- [ ] Board player name: active `primaryFixed`, inactive `onSurfaceVariant`.
- [ ] Win banner = `win`→`primary`; bust = `errorContainer`/`onErrorContainer` + `error` flash.
- [ ] `award`/`success` brightness-aware (via `AppTheme.award/success(context)`) — lighter in dark mode.
- [ ] Avatar identity palette: 8 fixed hues, stable per player, initial in `onAvatar`; same player = same colour everywhere.
- [ ] Segment buttons per tier (Singles `surfaceContainerHighest`/`onSurface`; Doubles/Triples `onSurfaceVariant` + dots `primaryFixed`@70%; Bull 50 background `primaryFixed`).
- [ ] No colour literal outside the §2 palette in widgets.
- [ ] Won't-fix exceptions (do NOT report): dartboard/heatmap domain colours (§7.6, #195); ~41 component-local alpha literals (§5).

### 2.2 Typography
**Compliance checklist**
- [ ] Only two families (Space Grotesk for scores/display/labels; Inter for body/buttons); no mixing within one element.
- [ ] Screen titles `headline-md` ALL CAPS; sizes ≥ 11px.
- [ ] Board player names = `labelMedium` ALL CAPS `letterSpacing 1.2` (≠ the roster's `player-name`, Inter 16px).
- [ ] Score token by player count (1p `scoreActive` 80 / 2p `scoreLarge` 64 / 3-4p `scoreMedium` 48 / 5+ `scoreSmall` 36; inactive one step down).
- [ ] Scores never truncated/wrapped; **no `FittedBox(scaleDown)` on a score** (constrained container).
- [ ] Camera-first exception: `FittedBox(scaleDown)` tolerated only on segment LABELS.
- [ ] Segment buttons `segmentButton` (Inter SemiBold 18); multiplier `multiplierLabel` (Inter Medium 11).
- [ ] Numbers via `StatFormatter` (no superfluous decimal zeros → that betrays an inline `toStringAsFixed`).

### 2.3 Spacing / layout
**Compliance checklist**
- [ ] Horizontal page margin = `space4` (16dp) everywhere; 4dp grid (no 5/7/10/14/18 outside documented tokens).
- [ ] Radii: cards `radiusLarge` 16; CTA/config chip `radiusMedium` 12; strip/segment/badge cells `radiusSmall` 8; modals/segmented `radiusXLarge` 24; pills `radiusFull`.
- [ ] No-Line Rule: spacing (`space6/8/10`) instead of 1px dividers (the only tolerated line = status bar bottom edge `outlineVariant`@10%).
- [ ] Segment grid touch target ≥ 48dp.
- [ ] Scrollable bottom padding = `space16` (64dp) above the nav bar; top/bottom SafeArea (Pixel 6a notch/gesture bar).
- [ ] **No overflow/clipping at 412×915** (no yellow-black stripes, no unintended ellipsis, no truncated card).
- [ ] Active card: 4dp left accent + shadow (`opacityActiveCardShadow` 0.50); inactive without shadow.
- [ ] Strips (X01/Cricket/Practice) aligned with each other (padding 16h/4v, 8dp gap).

### 2.4 Camera-first / at-distance (#477)
> Web: `CameraPreview` is stubbed, but the **chrome** is rendered via `dartlodgeSim.enableAutoScoring()`. Real physical readability = **device-only**.

**Compliance checklist**
- [ ] Prominent band: ~110px slots, `scoreMedium` (48px) `primaryFixed` numerals; long label (`MISS`) in `FittedBox(scaleDown)` without wrapping; short numerals not inflated.
- [ ] Thrown slot = `primaryFixed`@10% fill + ghost border@20% `radiusMedium`; empty slot = `surfaceContainer` + `more_horiz` (or `add_circle_outline` if manual entry is enabled).
- [ ] Hero: `scoreActive` 80px `onSurface`, 1 line, never scaled; `labelSmall` `primaryFixed` over-line above.
- [ ] Secondary strips subordinate to the hero (~1.5× compact, don't compete with the value).
- [ ] Cricket: `CricketMarkPainter` ~4px strokes (slash/cross/circled cross), 3+ in `primaryFixed`, dead targets dimmed; flex columns without horizontal scroll (2-4 players).
- [ ] Single camera area filling the remaining height, with no dead zone below it (#760) + control bar underneath; `GameStatusBarWidget(showDarts:false)` (darts only in the band, not duplicated).
- [ ] Identical composition across X01/Cricket/Practice (no per-game size drift).
- **Device-only**: readability at ~2.4 m, live preview taking all the space left (no more collapse/expand since #760).

### 2.5 Cross-screen consistency
**Compliance checklist**
- [ ] Game summary card identical in the History list ↔ detail/post-game (`radiusLarge`, typography, winner/loser colours).
- [ ] AVG badge (dart-badge `primaryFixed`@10% / border@20% / `radiusSmall`) identical everywhere (picker, roster, cards).
- [ ] `kineticCardDecoration` identical (135° gradient, ghost border@10%, `radiusLarge`) on Home & setup cards; `kineticSplashColor` splash (no "pop" scale).
- [ ] `AppHeader` (logo/back/action) positioned/styled identically on Home/History/Stats/Players/Settings.
- [ ] Stats tabs, nav rows, segment grid consistent across screens.
- [ ] Light/System/Dark theme parity (3-way selector): every screen readable/consistent in both; neon `primaryFixed` constant, `primary` adaptive.
- [ ] Consistent empty states (message typography, iconography, placement).
- [ ] Variant labels: Title Case in picker/header vs lowercase in History = **intentional** (CLAUDE.md), don't report.

### 2.6 Heatmap
**Compliance checklist**
- [ ] Cold→hot colormap (transparent→blue→cyan→yellow→red), dense=red, intuitive with no inversion; alpha grows with density (no opaque halo).
- [ ] Smooth KDE rendering (Gaussian + `FilterQuality.medium`), not blocky despite the 64×64 grid; density clipped to the disc (round clipPath).
- [ ] Self-drawn board correct (20 alternating black/cream segments, green/red double/triple rings, single+double bull, 20 at the top); square (AspectRatio 1, maxWidth 320) without distortion.
- [ ] Board colours = domain literals (#195), not tokens — don't report.
- [ ] Section title `labelSmall` CAPS `letterSpacing 1.2` (`primaryFixed` all-time / `onSurfaceVariant` post-game).
- [ ] Multi-player post-game: `SegmentedButton` selector per competitor; "N darts not located" note if mixed.
- [ ] Section auto-hidden (`SizedBox.shrink`) if no position is located — no empty board/flash.
- [ ] All-time: one board per gameType tab, visibly ignores the `TimeRangeSelector`.
- [ ] ⚠️ **To confirm (oracle gap)**: no segment numbers and no colour legend/scale (DESIGN_SYSTEM says "readable legend" — the widget doesn't draw one).

### 2.7 Transient / empty states (visual)
> The *look* of the states (the *behaviour* is in axis 2 §3.2).

**Compliance checklist**
- [ ] Empty states: consistent 64px outline icon in `onSurfaceVariant` (Players/History/Stats); title in the same token; uniform icon→label rhythm; centred.
- [ ] Consistent loading: centred `primary` `CircularProgressIndicator`; skeleton that matches the final shape (`surfaceContainerHighest` fill, not a hardcoded grey).
- [ ] No flash/layout jump on load→data (the placeholder occupies the final region).
- [ ] Errors via `ErrorRetryWidget` (icon + title + bounded message + retry), not a raw red dump.
- [ ] Press feedback: `kineticSplashColor` ripple + kinetic shift towards `primaryFixedDim` (§10.1), no "pop".

---

## 3. Gallery of surfaces to capture (pass 2)

> Capture each surface in Pixel 6a portrait, **light AND dark**. List derived from the dimensions.

- **Home** (kinetic cards + nav rows) · **Setup** (variant, player selection, lineup, config sheet)
- **Manual boards**: X01 (1/2/3-4/5+ players), Cricket, Count Up, Practice (ATC/Catch40/Bob's27/Checkout)
- **Camera-first boards** (via sim `enableAutoScoring`): X01, Cricket, Practice
- **Post-game summary** (+ win banner, per-player heatmap, multi-player selector)
- **History** (list, game detail) · **Stats** (tab, player stats, all-time heatmap, AVG badges)
- **Players** (list, detail, create, edit) · **Achievements** · **Settings** (3-way theme, sections)
- **Unhappy states**: empty Players/History/Stats; a loading/skeleton; DB-error surface
- **Bust snackbar/flash**; modals (leg/win); achievement toast

## 4. Likely findings (to confirm visually in pass 2)

> Spotted by the pass-1 agents' code analysis — **hypotheses**, to validate on a screenshot before any issue.

- **F? (P2)** — DB-error surface (`app.dart` `error:` branch) = `Center(child: Text('Database failed to open: $e'))`: raw string, no icon/theme/localization/retry (seen on device during the resolution validation). Design + UX finding candidate.
- **F? (P2)** — Hardcoded non-localized labels: `'Retry'` (`ErrorRetryWidget`), `'Page not found'`/`'Error'` (router `_errorPage`).
- **F? (P2)** — Empty-state inconsistency: icon→label gap 16dp (Players/Stats) vs 8dp (History); History title in body vs `titleLarge` elsewhere.
- **F? (P2)** — Non-uniform loading: Players has a shaped skeleton, History/Stats a plain spinner.
- **F? (P2, oracle gap)** — Heatmap without legend/scale or segment numbers, whereas DESIGN_SYSTEM §7.6 mentions a "readable legend". Decide: add the legend OR fix the oracle.

## 5. Pass 2 (capture + inspection)

_[to run: app launched in Pixel 6a portrait, sim bridge for camera-first/heatmap; capture the §3 gallery; tick the §2 checklists; confirm/refute the §4 findings.]_

## 6. Output

- Confirmed design findings → log `docs/testing/findings-2026-06.md` (plan §8 format).
- Any visual regressions → screenshot baseline (optional, post-1.0).
