# Cricket — Formal Statistics Projections

**Derived from:** Game Events + Cricket engine rules
**Status:** Authoritative
**Scope:** Player, Leg, Match

---

## 1. Purpose

Defines how cricket statistics (marks, MPR/MPT, mark buckets, hit rate) are
projected from `game_events`. Like all DartLodge statistics, these are **pure
projections** — never stored, rebuilt by replay, correction-safe.

> **No statistic is stored as a fact. Only events are facts.**

---

## 2. Marks & MPR / MPT

A **mark** is a hit on a valid cricket target (the active number set — 15–20 +
Bull for fixed/standard; the assigned set for Random/Crazy). T20 = 3 marks,
D20 = 2, S20 = 1; Bull: DB = 2, SB = 1. **MPT / MPR** = total marks ÷ total
turns (rounds).

Marks are counted **per dart, additively, from `DartThrown` payloads within each
turn** — never from a cross-turn diff of board state. This is load-bearing for
Crazy Cricket, where the active set rotates every turn and non-locked numbers
have their marks wiped on rotation (cumulative marks are non-monotonic). See
`statistics.architecture.md` §7.3.

### 2.1 Dead-number rule (#638)

A cricket number is **dead** once it is **closed by every competitor** (each has
≥3 marks on it, the thrower included). A hit on a dead number generates **0
marks** — it only yields points (standard / cut-throat) or nothing (no-score),
matching the standard / electronic-machine MPR convention. This is uniform
across all scoring variants (MPR is marks regardless of scoring).

Still counted as marks:

* Marks toward closing a number (until the thrower reaches 3).
* **Overflow** on a number still open for at least one competitor (e.g. a T20
  thrown after you've closed 20 while an opponent hasn't).
* The dart that closes the number for the **last** remaining competitor — it was
  live at throw time (dead-ness is evaluated **before** the dart is applied).

**Implementation.** Closure is reconstructed **forward** within the same replay
pass by `CricketClosureTracker`
(`lib/features/statistics/domain/engines/cricket/cricket_closure_tracker.dart`):
it accumulates per-competitor marks (keyed on `competitor_id`, the engine's
closing unit), locks a number permanently once any competitor reaches 3, and —
on `CrazyTargetsRolled` — wipes every non-locked, non-Bull number's marks,
mirroring `StatelessCricketEngine._applyCrazyTargetsRolled`. No cross-turn board
diff is taken, so §7.3 holds and Crazy Cricket discard-on-rotate stays correct.

The competitor **roster** (needed for "closed by all") is captured from the
`GameCreated` payload's `competitors` list. Event slices that carry no
`GameCreated` (a per-leg slice after leg 1, via `ComputeLegStatsUseCase`) seed
the roster explicitly. When the roster is unknown the tracker **never
suppresses** (safe fallback to the pre-#638 over-count).

All cricket mark projections apply this rule consistently:
`CricketMarksPerTurnProjection`, `CricketBestLegMptProjection`,
`CricketMarkBucketsProjection`, `CricketFirstNineMprProjection`, and the inline
per-leg tracker in `PlayerStatsAssembler.legHistoryFromEvents`.

### 2.2 Hit rate is unaffected

`CricketHitRateProjection` measures darts that physically hit a target, not
marks. A dart still **hits** a dead number, so hit rate intentionally does NOT
apply the dead-number rule.

---

## 3. Reset rules

| Scope       | Reset on      | Effect on closure tracking          |
| ----------- | ------------- | ----------------------------------- |
| Turn        | TurnStarted   | per-turn mark accumulator           |
| Leg         | LegCompleted  | closure board (marks + locks) reset |
| Match/Game  | GameCompleted | next `GameCreated` re-seeds roster  |

The board resets each leg, so a number dead in leg 1 is live again in leg 2.
