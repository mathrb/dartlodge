# Camera-first distance readability — design

**Date:** 2026-06-12
**Status:** validated (brainstorming session with owner)
**Scope:** camera-first layouts only (X01, Cricket, Practice boards). Manual-mode layouts unchanged.

## Problem

In camera-first mode the phone is mounted near the board and the player reads it
from the oche (~2.4 m). At that distance:

- the 3-dart band (`ProminentDartBandWidget`, 64 px slots, `headlineMedium`
  text ≈ 4–5 mm physical) is too small to read;
- the cricket marks strip (`CricketMarksStripWidget`, 22 px columns, text
  glyphs `·/X⊗` in `labelSmall`/`labelLarge`) is effectively illegible.

Rule of thumb: comfortable reading at 2.4 m needs ~15–20 mm character height,
i.e. 4–5× current sizes. That space cannot come from nowhere — today the camera
preview fills the entire flexible region.

## Decisions (owner-validated)

1. **The camera preview is near-useless during play** once calibrated. It
   collapses to a **vignette by default**; game info takes the freed space.
   No near/far toggle — the vignette IS the camera-first default.
2. Tapping the vignette **expands** the preview (to check framing /
   calibration). It **auto-collapses** on any `currentTurnDarts` change —
   new dart OR turn advance, both mean you're done checking — or after
   ~10 s without interaction.
3. Cricket shows the **full grid** at distance (all players' marks + scores),
   not a reduced "my targets" view — it is the complete tactical picture.
4. The **round counter stays small** (status bar) — it is near-distance info.
5. UNDO / NEXT bottom bar unchanged — tapped up close when pulling darts; the
   NEXT pulse is already a colour signal visible at distance.

## Layout (cricket shown; X01/practice analogous)

```
ÉTAT VIGNETTE (défaut)                       ÉTAT AGRANDI (au tap)
┌─────────────────────────────┐             ┌─────────────────────────────┐
│ ‹  CRICKET · standard    ⋮  │             │ ‹  CRICKET · standard    ⋮  │
│    Leg 1 · Round 3          │             │    Leg 1 · Round 3          │
├─────────────────────────────┤             ├─────────────────────────────┤
│     20 19 18 17 16 15 B     │             │     20 19 18 17 16 15 B     │
│ ALICE ⊗  ⊗  ╳  ／ ·  · · 120│   GRILLE    │ ALICE ⊗ ⊗ ╳ ／· · ·     120 │
│ BOB   ⊗  ╳  ·  ·  ／ · ·  85│   GRANDE    │ BOB   ⊗ ╳ · · ／· ·      85 │
│                             │             ├─────────────────────────────┤
│                             │             │ ┌─────┐ ┌─────┐ ┌─────┐     │
├─────────────────────────────┤             │ │ T20 │ │ 19  │ │  +  │     │
│ ┌───────┐┌───────┐┌───────┐ │             │ └─────┘ └─────┘ └─────┘     │
│ │  T20  ││  19   ││   +   │ │   BANDE     ├─────────────────────────────┤
│ └───────┘└───────┘└───────┘ │   ~110 px   │       CAMÉRA                │
├─────────────────────────────┤             │   (plein écran, overlay     │
│ ▒▒▒▒▒ caméra ~96 px ▒▒ [📷] │   VIGNETTE  │    détection ; auto-repli   │
│ (3 darts detected) 🧹 ⏹     │   + bar     │    prochain dart / 10 s)    │
├─────────────────────────────┤             ├─────────────────────────────┤
│  [ ↩ UNDO ]   [ NEXT ▸ ]    │             │  [ ↩ UNDO ]   [ NEXT ▸ ]    │
└─────────────────────────────┘             └─────────────────────────────┘
```

## Components

### 1. Camera vignette

- The `YOLOView` is **never remounted** (camera re-init / blackscreen class of
  bugs, see #467): same widget identity, same key; only the layout constraint
  changes between ~96 px and `Expanded`. Detection runs identically in both
  states. Animate with `AnimatedSize` **only if** device verification shows
  CameraX platform-view resize doesn't glitch; otherwise switch between the two
  states without animation.
- Geometry, precisely: today's `expand: false` band renders the preview at a
  fixed 140 px (`SizedBox(height: 140)` in `AutoScorerYoloPreview.build`) with
  the control bar + hint BELOW it (not included in the 140). The vignette is
  that same band-style layout with the preview reduced to a NEW ~96 px height;
  the expanded state is the current `expand: true` camera-first variant
  (preview fills the `Expanded`). One number to pick at implementation time:
  the vignette preview height (~96 px target, tune on device).
- **`expand` is today a `final` constructor parameter** baked in at `main.dart`'s
  `boardCameraPreviewBuilderProvider` override — toggling it by building a new
  `AutoScorerBoardOverlay(expand: …)` restructures the subtree around the
  preview (`Expanded > Padding` vs `Padding` parents) and risks exactly the
  platform-view churn this design forbids. The implementation must make the
  vignette/expanded flip **runtime-mutable inside the overlay** (e.g. driven by
  a `ValueListenable`/core holder provider the board bumps, or overlay-internal
  state with a collapse signal), keeping the `YOLOView`'s element identity
  stable across the flip (`GlobalKey` if the wrapper structure must change).
  Device-verify the flip does not re-bind the camera.
- **Control bar stays visible in both states** (it lives under the preview in
  `AutoScorerBoardOverlay._barRow`): `AutoScorerStatusChip` + Remove darts +
  Stop. The chip's alert states (`Camera moved`, `needs calibration`,
  `Turn full — advance`) already render on `errorContainer` — a colour blob
  readable at 2.4 m. Bump the chip typography one step. No separate warning
  badge needed.
- Manual capture button (data-collection opt-in) keeps its top-right corner
  position on the preview in both states (near-distance, rare use).
- **Idle/aim** flow unchanged: before the camera runs, the vignette region
  shows the existing "Start camera" row / error text.
- Expanded-state ownership: the **board** owns the `expanded` boolean (it must
  re-flow grid/band when the camera grows). Tap on the vignette toggles it;
  auto-collapse on `currentTurnDarts` change (boards already watch it) +
  ~10 s timer.

### 2. Cricket marks grid (distance version of `CricketMarksStripWidget`)

- Column widths are **flex-derived, not fixed**: the 7 target columns share
  the width remaining after name + score (which shrink-to-fit), yielding
  ~36–44 px per cell on common 360–412 dp screens (vs 22 px fixed today).
  Fixed 44 px cells would NOT fit (68 + 7×44 + 44 + padding ≈ 452 px > 412 dp)
  — flexing is what makes "no horizontal scroll" hold. The existing
  `SingleChildScrollView` safety net is removed; rows ~56 px for 2 players,
  compressing to ~40 px at 3–4 players. Score renders inline at the end of
  each player's row (as in the mockups).
- Marks become **painted glyphs** (`CustomPaint`): slash, cross,
  circled-cross with ~4 px strokes — at distance stroke weight carries
  legibility, not font size.
- Colour semantics: closed (3+) = `primaryFixed` filled; 1–2 marks =
  `onSurface`; unmarked = faint ghost dot. **Dead target** (closed by all):
  header dimmed + struck through, marks greyed.
- Headers `titleMedium`; scores `headlineMedium`; player names stay
  `labelMedium` ALL-CAPS `letterSpacing: 1.2` (the DESIGN_SYSTEM rule #434/#449
  both initially missed); active player row highlighted, inactive scores
  `onSurfaceVariant` (existing DESIGN_SYSTEM rules).
- Painted glyphs lose the text finders (`X`, `⊗`) — expose `Semantics`
  labels ("2 marks", "closed") for tests and accessibility.

### 3. Prominent dart band

- Slots grow from 64 px to ~110 px; segment text `scoreMedium` (48 px — the
  design doc originally said `displaySmall`, which does not exist in
  `AppTextStyles`). The existing `FittedBox(scaleDown)` stays and only ever
  shrinks the one long SEGMENT LABEL (`MISS`, a word, ~10 % at 412 dp) —
  the DESIGN_SYSTEM "score numerals never scale" rule targets point-total
  numerals, not segment labels (owner-validated trade-off, PR #481 review).
- Behaviour unchanged: tap thrown slot = correction, tap empty slot (`+`) =
  manual entry, gating identical.

### 4. X01 / practice

- `HeroMetricWidget` / `PracticeTargetDisplayWidget(heroSize: true)` already
  at distance size — unchanged.
- `X01OtherPlayersStripWidget` / `PracticePlayersStripWidget`: bump ~1.5×.
- `_CheckoutBanner` (X01 checkout suggestion): keep position (between hero and
  strip); verify at-distance legibility and bump if needed (PR 1).
- Both get the shared bigger band + vignette for free.

## Audit — current camera-first inventory vs this design

| Element | Fate |
|---|---|
| Header + status bar (config, leg, round) | unchanged (round = near info, decision 4) |
| Cricket grid / X01 hero + checkout banner / practice target | grid redesigned; hero unchanged; banner size-checked |
| Other-players strips | ~1.5× |
| 3-dart band (correction + manual entry) | ~110 px, `displaySmall` |
| Bottom bar UNDO / NEXT (+ pulse) | unchanged |
| `AutoScorerStatusChip` (status + alerts) | kept under vignette in both states, typo +1 |
| Remove darts / Stop buttons | kept (control bar) |
| Manual capture button | kept (preview corner) |
| Start camera / error row (idle/aim) | unchanged in vignette region |
| "Tap a dart to correct" hint | kept under control bar |

## Delivery (serial PRs)

1. `feat/` enlarge dart band (+ checkout-banner size check) — trivial,
   shippable alone.
2. `feat/` cricket grid: CustomPaint marks + colours + Semantics.
3. `feat/` camera vignette: board-owned expand state, auto-collapse,
   chip typo bump. Riskiest — verify platform-view resize on a real device
   via the PR APK artifact before merging.

## Testing

- Camera-first chrome is widget-testable (override `autoScoringEnabledProvider`
  fake + `boardCameraPreviewBuilderProvider` stub): vignette default state,
  tap-to-expand, auto-collapse on dart-count change and on timer (fake async),
  control bar present in both states.
- Grid: `Semantics`-based finders replace text glyph finders.
- Band: size/typography assertions updated in the same session as the refactor
  (CLAUDE.md rule).
- Device-only: actual `YOLOView` resize behaviour — sideload the PR APK.
