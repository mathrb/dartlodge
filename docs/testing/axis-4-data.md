# Axis 4 — Data / persistence — detailed test plan

> **Status: pass 1 (exploratory charters per topic).** Scripted cases = pass 2 (deferred).
> Parent: `docs/plans/2026-06-19-1.0-verification-plan.md` §6. Execution mechanics + template:
> see `axis-1-correctness.md` §2–§3. Guiding principle: **compute the expected value by hand
> from the events, compare with the UI** (stats are projections, never stored).

---

## 1. Purpose & oracles

Verify that what is computed and stored is **exact and durable**. Stats = projections replayed
from `game_events`; history/achievements/heatmap faithfully reflect the games.

- Oracles: `docs/statistics/{x01.projections,statistics.architecture,projection-test-matrix}.md`
  (realigned #585), `docs/DATABASE_DDL.md`, `docs/DATA.md`, `docs/GAME-EVENT-SPECIFICATIONS.md`,
  `docs/REPOSITORY_INTERFACES.md` (#586) + `PlayerStatsAssembler` / `ProjectionRunner`.
- Rail: almost all `[web]` (drift/IndexedDB ≈ native); `[device]` for the sqlite3 minSdk23 runtime.

---

## 2. Topics

### 2.1 Statistics = projections
**Exploratory charter** — *Missions*
1. **X01 3-dart average via the `turn_score` delta (#318).** Game with a bust visit and/or an unmet Double-In: compute `avg = (Σ turn_score / darts) × 3` (x01.projections §5.2); the bust visit contributes **0** to the numerator but +1 per dart to the denominator; a legacy event without `turn_score` falls back to the per-dart sum.
2. **Checkout % — definition of an attempt.** Attempt = `TurnStarted.starting_score ≤ 170` AND "in" (§6.4). Probe 170 (counts) / 171 (doesn't); **requires `TurnStarted`** (otherwise 0 → null).
3. **Highest checkout & 100/140/180 buckets.** Mutually exclusive buckets (an exact 180 doesn't also appear in 140+/100+); bust visits excluded.
4. **Cricket MPR/MPT + exact-N vs ≥-N overload.** A 7-mark visit: per-game/leg → exact-7 (`*Exact` keys); career (`getPlayerStats`) → ≥5/≥6/≥7 (`*MarkTurns` keys). Identify the call path before judging.
5. **First nine (X01 PPR / cricket MPR).** Requires `TurnStarted` + ≥3-turn guard (short leg excluded from the denominator, #290); `null` rendered cleanly (not "0.0").
6. **Two-level snapshot & scope.** `snapshot[descriptor.id][field]` (architecture §5.3); career `fromEvents` / per-game `gameStatsFromEvents` / per-leg `legCompetitorStatsFromEvents` consistent.

**Heuristics** — every displayed value reproducible by replaying by hand (otherwise = stored = defect; only exception: heatmap §2.5); the denominator lies more often than the numerator (recount separately); `null` ≠ `0.0` on screen; corrections = full replay; strategy as lowercase literals `'straight'/'double'/'master'`.

### 2.2 Reset scope & event order
**Exploratory charter** — *Missions*
1. **Exact reset boundaries.** Turn on `TurnStarted` (NOT TurnEnded), Leg on `LegCompleted`, Match on `GameCompleted`; nothing else. Runner: Turn reset **before** `apply`, Leg/Match **after** — a reset on the wrong edge corrupts the snapshot of the boundary dart.
2. **No turn→turn leak.** Turn N (180) then an empty turn: snapshot N+1 without residue; a non-`DartThrown` event between turns doesn't reset the Turn prematurely.
3. **Multi-game `(game_id, local_sequence)` sort.** `local_sequence` restarts at 1 per game → overlapping ranges; check that `getPlayerStats`/`achievementMetricsForPlayer`/`getPlayerLegHistory` sort by both, and that `ProjectionRunner` re-imposes the sort.
4. **No cross-game/leg pollution.** Multi-leg match + multiple games: Match counters don't overflow, Leg doesn't survive `LegCompleted` (test-matrix XG1/XG2).
5. **Per-game `replayFrom` cutoff.** Filtered by `localSequence >= fromSequencePerGame[gameId]`; a single global cutoff wrongly drops co-loaded events.

**Heuristics** — reset on the wrong edge = includes/excludes the boundary dart; `orderBy(localSequence)` alone on a multi-game path = bug (single game OK); idempotence: full run ≡ `replayFrom(0)`; event-only events (LegCompleted/bust-via-TurnEnded) trigger resets with no dart — a DartThrown-only fixture misses them.

### 2.3 History
**Exploratory charter** — *Missions*
1. **List & order.** Only `is_complete=1` + non-null `end_time`, sorted by `end_time` DESC; abandoned/in-progress games never present.
2. **Pagination (`loadNextPage`/offset, `_pageSize=20`).** Sizes 20/21/40/41/large N: no duplicates, no gaps, partial last page not omitted; correct `hasMore`; rapid parallel calls guarded (`_loadingNextPage`).
3. **Filters & surviving `invalidateSelf`.** Type + date range (inclusive on `end_time`), pushed down to the database; `_filter*` survive the rebuild; filter + pagination combined; `clearFilters`.
4. **Detail = correct leg breakdown.** `legStats` (events sorted by `localSequence`) = winner/darts/stats per row (PPR/checkout/180s X01; MPR/first-9/marks Cricket).
5. **Cross-check by hand.** Rebuild per-leg stats from the raw events for 1 X01 game + 1 Cricket game, compare with the detail AND with `getGameStats` (tricky cases: bust, unvalidated Double-In, buckets, overflow).
6. **Read-only & summary card.** Opening the detail emits/alters no event; winner sorted first, score `a–b`, **lowercase** variant label in history.

**Heuristics** — sizes exactly on multiples of `_pageSize`; set of accumulated IDs == `getCompletedGames(∞)`; independent oracle (recount, don't trust `computeLegStats`); null fields → `'—'`; zero mutation on read.

### 2.4 Achievements (data/persistence)
**Exploratory charter** — *Missions*
1. **Unlocked at the right moment (NineDarter).** Only on a 501 finished in 9 genuine darts (not 10+, not 301/701, not busted/unfinished); `hasNineDarter` via `x01.nineDarter`.
2. **Counter thresholds (Games501, total180s, highestCheckout, totalWins).** Exact `value >= threshold`: test N-1 / N / N+1; `big_fish` (explicit 170); binary ones with no threshold (first occurrence).
3. **Persistence + idempotence.** Row in `unlocked_achievements` (PK `player_id+achievement_id`); `recordUnlock` idempotent (PK conflict swallowed, first `unlocked_at`/`game_id` kept); no second toast/duplicate on replay/reload.
4. **Reactive detection & surviving reload.** Watcher (keepAlive) detects on a *newly* completed game, participating players only; `earned.difference(already)`; no backfill (initial `_processed` snapshot).
5. **FK behaviour on deletion.** Delete the game → `game_id` NULL (trophy kept); delete the player → CASCADE; nonexistent FK → `DatabaseException` (NOT swallowed like the PK conflict).
6. **Persisted facts, not GameEvents.** No `AchievementUnlocked` event; no progress/notification column.

**Heuristics** — exact threshold boundaries; false positives (wrong game/player, before completion); distinguish "already unlocked" (no-op) from "write failure" (must surface); multi-player (1 game credits several, each on their own cross-type history); v1→v2 migration (`unlocked_achievements`) covered by `migration_test`.

### 2.5 Heatmap (data/persistence)
**Exploratory charter** — *Missions*
1. **Dual persistence when auto-scored.** `submitDart(seg, x:, y:)` → `DartThrown` payload (flat `x`/`y` keys, added `if != null`) → `dart_throws.x/.y` columns; same pair in the event AND the row.
2. **Null by construction (manual + corrected).** Non-auto paths pass `x:null,y:null` → keys omitted → NULL; never a manual dart with non-null x/y.
3. **`getDartPositions` contract (projection bypass).** Reads `dart_throws` directly (never the assembler), 3 predicates: `playerId`, `x/y NOT NULL`, `games.is_complete=1`; real segment kept (not normalized to MISS).
4. **A correction that removes a position.** Preserves the invariant: no "ghost" position from a cancelled detection.
5. **`dartHeatmapProvider` aggregation / time filter.** Post-game (`gameId`) vs all-time per `gameType` (`from/to=null`); the stats view **deliberately ignores** the `TimeRangeSelector` (maintainer decision) — not applying it = a UI decision, not a repo limitation.

**Heuristics** — canonical frame (origin=centre, r=1.0 at the double, 20 at the top; no pixels/camera frame); flat `x`/`y` keys; omission ≠ sentinel (0,0 = legitimate bull, never NaN); manual/auto asymmetry intended; x/y nullable `REAL` since v1 (no #571 migration); facts, not projections.

### 2.6 Persistence & replay
**Exploratory charter** — *Missions*
1. **Exact restoration on reload.** Reloading mid-game rebuilds the exact state by replay (score, active player, round, darts of the turn, cricket targets, locked targets, in/out, currentTarget); no input lost/duplicated; tricky resume points (after a TurnStarted with no dart, unacknowledged bust, leg switch).
2. **Determinism vs RNG.** Identical replay even with RNG (`CrazyTargetsRolled`, random): value frozen at emission, pure `apply()`, never re-rolled.
3. **Multi-game `(game_id, local_sequence)` order.** Overlapping ranges (`UNIQUE (game_id, local_sequence)`); every cross-game query sorts by both, never by `local_sequence` alone.
4. **Replay-aware `DartCorrected` supersession.** `original_event_id` collected + originals skipped by `PlayerStatsAssembler` AND `UndoLastDartUseCase`; traps: correction then undo across a turn change, multiple corrections, last dart of a leg.
5. **Finished games read-only (app logic, not a trigger).** `is_complete=1` → `appendEvent(s)` rejects inside the transaction (anti-TOCTOU, re-reads `gameRow.isComplete`); no path (undo/auto-advance/late correction) gets around it.
6. **IndexedDB & FK integrity.** Data survives a real reload (WASM/IndexedDB); `CASCADE` (games→children), `RESTRICT` (player with history can't be deleted), `SET NULL` (`current_turn_player_id`, `unlocked_achievements.game_id`).

**Heuristics** — test reload at the start/middle/end of a turn/leg/game; oracle = recounted by hand (not the in-memory state before reload); count replayed darts vs persisted `dart_throws`; idempotence (replaying twice = same state); read-only lock under a race (append concurrent with `completeGame`); real browser reload (not a provider rebuild) to exercise IndexedDB.

---

## 3. Output

- Data findings → log `docs/testing/findings-2026-06.md` (plan §8 format).
- Scripted cases (pass 2): games with known values, emulated 9-darter, reload, heatmap with known positions — _[to derive after the first exploratory pass]_.
