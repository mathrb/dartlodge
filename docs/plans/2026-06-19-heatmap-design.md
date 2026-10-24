# Impact heatmap — Design

**Date:** 2026-06-19
**Status:** approved (brainstorming), epic to be created

## Summary

With auto-assist (camera auto-scoring), we know the precise position of every
dart on the board. We want to show that information as a **density heatmap**
on a mock board, in two places:

1. **End of game** (X01, Cricket, …) — per player, with a selector.
2. **Statistics section** — aggregated per player, filterable by game type and by time range.

The `(x,y)` position is **not captured/persisted today** (the detector computes it
but it is thrown away after the segment is classified). The work therefore splits into two
phases: **Phase 1 = capture pipeline**, **Phase 2 = visualization**. The heatmap only
shows games played with auto-assist *after* Phase 1 (no backfill).

## Founding decision: coordinate convention

At emission, the auto-scorer normalizes the dart's canonical position into a
frame that is **stable and independent of the model and the calibration**:

- origin `(0,0)` = centre of the board;
- radius `1.0` = outer edge of the **double** ring;
- "20 at the top" orientation, aligned with `kDartboardClockOrder`;
- a miss outside the double has a radius `> 1.0` (kept — miss patterns are useful).

### Why "20 at the top" works even when the board is rotated

The canonical frame isn't anchored to the camera/phone orientation but to
the **4 calibration points** (anatomical landmarks of the board, detected by the model
as 4 distinct classes). See `canonicalTransform()` in
`lib/features/auto_scorer/domain/scoring/homography.dart`:

```
cal1 = wire 5/20  → TOP      (cx, cy - r)
cal2 = wire 3/17  → BOTTOM   (cx, cy + r)
cal3 = wire 8/11  → LEFT     (cx - r, cy)
cal4 = wire 13/6  → RIGHT    (cx + r, cy)
```

The homography straightens the board (even rotated, even seen at an angle) so that cal1 always
lands at the top. It's **the same transformation that already makes segment scoring
work**: if a `T20` is scored correctly with the board mounted crooked, the heatmap point
necessarily lands in the right place. The heatmap **inherits for free** the scorer's
orientation correctness.

The only failure case: the model confuses the identity of the calibration points (180° flip). But
then the scoring itself is wrong — an existing model/calibration accuracy topic (#393,
probe territory), not a new failure mode introduced by the heatmap.

We don't reorient anything ourselves: we store the canonical position the scorer already
computes, normalized by the `radius` of the `CanonicalTransform`.

**Display orientation (#697).** The scoring frame anchors the **5/20 wire at the top**
(`cal1 → top`), so the centre of segment 20 falls ~9° clockwise from
vertical, not on it. `HeatmapDartboardWidget` applies a **display rotation**
(`kHeatmapDisplayRotation = -π/20`, i.e. −½ segment) to the whole thing — wedges **and** density
image together — to show a standard "20 at the top" board (5/20 wire ~9° left of
vertical). Stored data and homography unchanged; the hits stay in their
wedge since both layers rotate together.

## Phase 1 — Capture pipeline

Carry the normalized `(x,y)` from the tracker all the way to the event and the table.

1. **Normalization at the source** (auto_scorer, domain). The tracker already has
   `TrackedDart.boardPosition` (canonical units) + `centre`/`radius` via
   `CanonicalTransform`. The normalization `(p - centre) / radius` leading to the
   "centre=0, double-ring=1" frame would be written:
   ```
   x = (boardPosition.x - centre.x) / radius
   y = (boardPosition.y - centre.y) / radius
   ```
   > **⚠️ /plan finding (#572):** `DartTracker._normalise` **already** applies this
   > formula when building the candidates, so `TrackedDart.boardPosition` is **already**
   > in this frame (verified by `scoreDartAt(..., 1.0)` where `rDouble = 1.0`). Applying it
   > again at emission would **double-normalize**. SI-1 is therefore only a
   > pass-through + a noise guard (`r > 1.5` → null position, segment kept).
   > SI-2/SI-3 must **not** re-normalize.

   `SessionFrameResult.emittedDarts` now carries `(segment, x, y)` instead of just the
   `segment`.

2. **The `DartInputSink` port** (core/domain):
   `submitDart(String segment)` → `submitDart(String segment, {double? x, double? y})`.
   Raw doubles (the core port must not depend on the auto_scorer's `BoardPoint` type).
   Manual entry → nothing passed → `null`.

3. **Emission use cases** (`ProcessDartUseCase`, `ProcessCricketDartUseCase`, practice
   paths) accept optional `x,y` and pass them along:
   - **`buildDartThrownEvent`** → new payload keys `x`, `y` (omitted if null).
     Update `docs/GAME-EVENT-SPECIFICATIONS.md` + the payload key-set test.
   - **`DartThrow` insertion** → the `x`/`y` fields (already on the entity) are finally
     filled in.

4. **Corrections.** `DartCorrected` (via `UndoLastDartUseCase`) re-emits **without** a position
   → the corrected dart has `x/y = null` (conservative choice: a correction signals a
   doubtful detection). Check that replay/supersession doesn't re-inherit the old
   position.

### No database migration

The `dart_throws.x` / `.y` columns (`REAL nullable`) **have existed since schema v1**
(`drift_schemas/drift_schema_v1.json`), but have never been filled. Populating them is a
**content write**, not a structural change → **no `databaseVersion` bump,
no `onUpgrade`, no snapshot regeneration**. No backfill: past games and
manual darts stay `NULL` and are naturally excluded.

## Phase 2 — Visualization

### Heatmap widget

New shared widget `lib/core/widgets/heatmap_dartboard_widget.dart`
(`HeatmapDartboardWidget`, `StatelessWidget`). Stacked like `AtcAnnotatedDartboardWidget`:

```
Stack(
  DartboardHighlightWidget(noHighlight: true),   // realistic mock board, reused
  Positioned.fill(CustomPaint(painter: _HeatmapPainter(points, ...))),
)
```

The painter consumes a `List<({double x, double y})>` of normalized positions (exact
continuous position, **not** per-segment frequencies like ATC).

### Density algorithm (KDE)

In `_HeatmapPainter`:
1. bin the points onto a grid (~64×64) covering `[-1.1, 1.1]²`;
2. Gaussian smoothing (configurable kernel radius — small for end-of-game / few points,
   larger for big volumes);
3. normalize to `0..1` then map onto a cold→hot colormap (transparent → blue →
   cyan → yellow → red) with increasing alpha;
4. paint via `canvas.drawImage` of a `ui.Image` generated from the grid (perf: not N
   circles), clipped to the board's disc.

Perf: O(grid), not O(points²) — thousands of points in stats stay smooth. The
KDE+colormap function is **extracted as pure Dart** (testable outside the canvas).

### Data retrieval

Positions are **raw per-dart facts** (like `segment`/`score`), not a computed stat
→ we do **not** go through `PlayerStatsAssembler`. Direct read of `dart_throws`
`WHERE x IS NOT NULL` (also the fastest path).

New method on the statistics repository (interface + drift impl):
```dart
Future<List<DartPosition>> getDartPositions({
  String? gameId,                 // end of game: one game
  required String playerId,
  GameType? gameType,             // stats: filter by game
  DateTime? from, DateTime? to,   // stats: time range filter
});
// DartPosition = (double x, double y, String? segment)  — new small domain entity
```
Family provider `dartHeatmapProvider(filter)` → `AsyncValue<List<DartPosition>>`.

### Integration point A — end of game

In `GameSummarySectionWidget` (core/widgets), after the stats table: a "Heatmap"
section with a **player selector** (segmented control over the competitors), each
rendering `HeatmapDartboardWidget` for `(gameId, playerId)`. Section hidden if the game has
no position (played manually); "N manual darts not located" counter if
mixed.

### Integration point B — statistics

`PlayerStatsPage` is **already per player** and **already split into tabs** X01 / Cricket /
Practice / Others (= a free "game type" filter) and already has `TimeRangeSelector`
(= the "time range" filter). We add a heatmap section in the relevant tabs, fed
by `dartHeatmapProvider(playerId, gameType: <tab>, from/to: <TimeRange>)`. "Global" =
TimeRange "all" + aggregate.

## Edge cases

- **Misses outside the double** (`r > 1.0`): kept/displayed, grid extended to `[-1.1, 1.1]²`.
  Guard: `r > 1.5` = noise → discarded.
- **Bull** (SB/DB): positions close to the centre, no special handling.
- **Mixed game**: only located darts count; "N not located" counter.
- **Cross-model comparability**: positions normalized in the calibration-anchored canonical frame
  → comparable across model versions (they inherit the scorer's correctness).

## Tests

- **Phase 1**: normalization math (unit); the use cases inject `x/y` into the
  payload **and** into `DartThrow`; update the payload key-set test; correction → `null`;
  manual path → `null`; `getDartPositions` filters (game/player/type/time range) and **excludes
  NULLs** (contract).
- **Phase 2**: pure KDE+colormap function (binning/Gaussian/mapping) outside the canvas; widget
  tests for the hidden empty state + player switch. Real rendering on device isn't
  widget-testable (camera/device).

## Non-goals (YAGNI)

- No backfill of past games.
- No per-segment heatmap (we have the continuous position).
- No live heatmap during the game (post-game + stats only).
- No image export.
- No side-by-side comparison of two players.
- Time range filter = reuse of `TimeRangeSelector` (no custom date picker).

## Split into sub-issues

| #     | Phase | Content |
|-------|-------|---------|
| SI-1  | 1     | Normalization at emission + `SessionFrameResult` carries `(segment,x,y)` (auto_scorer) |
| SI-2  | 1     | `DartInputSink.submitDart({x,y})` + board sink impls forward it |
| SI-3  | 1     | Use cases → payload `x/y` + `buildDartThrownEvent` + `DartThrow` insertion + spec doc + correction null |
| SI-4  | 2     | `HeatmapDartboardWidget` + pure KDE function + tests (core/widgets) |
| SI-5  | 2     | `getDartPositions` + `DartPosition` entity + `dartHeatmapProvider` + contracts (data) |
| SI-6  | 2     | End-of-game integration (player selector in `GameSummarySectionWidget`) |
| SI-7  | 2     | Stats integration (sections in `PlayerStatsPage` tabs, wired to the filters) |

Phase 1 (SI-1→3) unlocks the data; Phase 2 (SI-4→7) visualizes it. SI-4 and SI-5 can
run in parallel.

## Reference files

- `lib/features/auto_scorer/domain/scoring/homography.dart` — `canonicalTransform()`, `centre`/`radius`
- `lib/features/auto_scorer/domain/tracking/tracked_dart.dart` — `TrackedDart.boardPosition`
- `lib/core/providers/board_camera_preview_provider.dart` — cross-feature seam (pattern; the `board_overlay_provider.dart` seam this doc originally cited was removed in #770)
- `lib/features/game/presentation/widgets/dartboard_highlight_widget.dart` — `DartboardHighlightWidget` + `kDartboardClockOrder`
- `lib/features/statistics/presentation/widgets/atc_annotated_dartboard_widget.dart` — overlay-on-board pattern
- `lib/core/widgets/game_summary_section_widget.dart` — end-of-game integration
- `lib/features/statistics/presentation/pages/player_stats_page.dart` — stats integration
- `lib/features/game/domain/usecases/game_use_case_helpers.dart` — `buildDartThrownEvent`
- `lib/core/persistence/drift/database.dart` — `DartThrows` table (`x`/`y` columns already present)
- `docs/GAME-EVENT-SPECIFICATIONS.md` — `DartThrown` payload (to be updated)
