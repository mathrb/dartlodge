# Count-Up – Complete State Transition Tables

**Derived from:** `Count-Up (Reverse X01, Highest Score Wins)`
**Status:** Authoritative (engine + server validation)

---

## 1. Overview

Count-up is a multi-player score-accumulation game. Each competitor throws
3 darts per turn; the value of every dart (segment × multiplier) is added
to that competitor's running score. There is no bust, no in/out strategy,
and no upper bound — every dart contributes. The game runs for a fixed
number of full rounds; once the last competitor of the last round finishes
their turn, the highest score wins.

It is structurally a "reverse X01": instead of subtracting toward zero,
players add upward, with the round cap (rather than a checkout) as the
end trigger.

---

## 2. Setup

| Parameter        | Value                                                    |
| ---------------- | -------------------------------------------------------- |
| Players          | ≥ 1 (multi-player; solo allowed)                         |
| Darts per turn   | Exactly 3 (turn never ends early — no bust, no win mid-turn) |
| `total_rounds`   | ∈ {8, 12, 16, 20}, default 8                             |
| Per-player `handicap` | ∈ {0, 50, 100, 150, 200}, default 0 (each competitor chosen independently at setup) |
| Legs             | 1 (always single-leg)                                    |
| End condition    | Last competitor of round `total_rounds` finishes their turn |

Handicap is stored on the config as `handicaps: Map<String, int>` keyed by
**competitorId** — identical pattern to X01's per-player handicap (see
`X01GameConfig.handicaps`). Players omitted from the map are treated as
handicap = 0.

---

## 3. State Model (Explicit)

The following state fields are *derived state*, never directly mutated
outside transitions.

### Per Game

* `total_rounds` — int (from config, immutable)
* `current_round` — int, 1-indexed; starts at 1, increments after the last
  competitor of a round finishes their turn
* `current_turn_index` — int, 0-based index into `competitors` for whose
  turn it is
* `game_complete` — bool

### Per Competitor

* `score` — int; initialised to that competitor's handicap (or 0)
* `handicap` — int (immutable for the duration of the game)

### Per Turn

* `turn_active` — bool
* `turn_start_score` — int (score at moment `TurnStarted` fired; not used
  for revert — there is no bust — but kept for stats parity with X01)
* `darts_thrown_in_turn` ∈ {0, 1, 2, 3}
* `current_player` — competitorId of the active thrower

---

## 4. Event Set (Relevant to Count-Up)

* `GameCreated`
* `TurnStarted`
* `DartThrown`
* `TurnEnded`
* `LegCompleted`
* `GameCompleted`

`LegCompleted` is emitted (immediately followed by `GameCompleted`) at game
end so per-leg stats projections flush cleanly. Count-up has no
intermediate leg boundaries.

---

## 5. Transition Tables

Each table is **orthogonal** and must be applied in order.

---

## Table A — Game Start (Score Initialisation)

Applied during `GameCreated` for each competitor:

| State         | Guard                              | Result                            |
| ------------- | ---------------------------------- | --------------------------------- |
| New game      | competitor in `config.handicaps`   | `score = handicaps[competitorId]` |
| New game      | competitor not in `config.handicaps` | `score = 0`                     |
| New game      | —                                  | `current_round = 1`               |
| New game      | —                                  | `current_turn_index = 0`          |

---

## Table B — Turn Start

| Current State  | Event       | Guard | Result                     |
| -------------- | ----------- | ----- | -------------------------- |
| No active turn | TurnStarted | —     | `turn_active = true`       |
| No active turn | TurnStarted | —     | `darts_thrown_in_turn = 0` |
| No active turn | TurnStarted | —     | `turn_start_score = score` |

**Invalid**

* `TurnStarted` while `turn_active == true` → reject
* `TurnStarted` while `game_complete == true` → reject

---

## Table C — DartThrown (General Acceptance)

| State Predicate            | Event      | Guard | Result |
| -------------------------- | ---------- | ----- | ------ |
| Game complete              | DartThrown | —     | Reject |
| Turn inactive              | DartThrown | —     | Reject |
| `darts_thrown_in_turn == 3` | DartThrown | —     | Reject |

There is no in-strategy table — every player is "in" from dart 1.

---

## Table D — Scoring

Let:
* `throw_value = segment × multiplier`
  * `MISS` ⇒ `throw_value = 0`
  * Single `n` (1–20) ⇒ `throw_value = n`
  * Double `n` (1–20) ⇒ `throw_value = 2 × n`
  * Triple `n` (1–20) ⇒ `throw_value = 3 × n`
  * Single bull (`SB`) ⇒ `throw_value = 25`
  * Double bull (`DB`) ⇒ `throw_value = 50`

| State        | DartThrown | Guard | Result                       |
| ------------ | ---------- | ----- | ---------------------------- |
| Turn active  | DartThrown | —     | `score += throw_value`       |

**Notes**

* No upper bound on `score`.
* No bust possible — `throw_value ≥ 0` always; revert never happens.
* `score` is monotonically non-decreasing for the duration of the game.

---

## Table E — Dart Count Increment

| State       | DartThrown | Guard | Result                      |
| ----------- | ---------- | ----- | --------------------------- |
| Turn active | DartThrown | —     | `darts_thrown_in_turn += 1` |

---

## Table F — Turn End Conditions

| State       | Event      | Guard                       | Result    |
| ----------- | ---------- | --------------------------- | --------- |
| Turn active | DartThrown | `darts_thrown_in_turn == 3` | TurnEnded |

The only trigger for `TurnEnded` is throwing all 3 darts. There is no
early end — no bust, no mid-turn win.

---

## Table G — Turn End

| State       | Event     | Guard | Result                                                 |
| ----------- | --------- | ----- | ------------------------------------------------------ |
| Turn active | TurnEnded | —     | `turn_active = false`                                  |
| Turn active | TurnEnded | —     | `darts_thrown_in_turn = 0`                             |
| Turn active | TurnEnded | —     | Proceed to **Table H** (game-end detection) before advancing player |

---

## Table H — Game-End Detection

Evaluated **immediately after `TurnEnded`** fires, **before** advancing
`current_turn_index`:

```
last_competitor = (current_turn_index == competitors.length - 1)
last_round      = (current_round == total_rounds)
game_should_end = last_competitor && last_round
```

| State          | Guard               | Result                                                                |
| -------------- | ------------------- | --------------------------------------------------------------------- |
| Post-TurnEnded | `game_should_end`   | Proceed to **Table J** — emit `LegCompleted` then `GameCompleted`     |
| Post-TurnEnded | `last_competitor && !last_round` | `current_round += 1`, `current_turn_index = 0`, emit next `TurnStarted` |
| Post-TurnEnded | `!last_competitor`  | `current_turn_index += 1`, emit next `TurnStarted`                    |

---

## Table J — Game Completion & Winner Selection

Emitted when Table H determines `game_should_end`.

Let `top_score = max(score for each competitor)` and
`leaders = { competitorId | score == top_score }`.

| Competitor count    | Predicate                | Outcome                                                  |
| ------------------- | ------------------------ | -------------------------------------------------------- |
| 1 (solo)            | —                        | `GameCompleted(winner = competitor)`                     |
| ≥ 2, `len(leaders) == 1` | clear top score     | `GameCompleted(winner = leaders[0])`                     |
| ≥ 2, `len(leaders) ≥ 2`  | tie at top score    | `GameCompleted(winner = null)` — recorded as a tie       |

| State        | Event         | Guard | Result                          |
| ------------ | ------------- | ----- | ------------------------------- |
| Game ending  | LegCompleted  | —     | `legs_won` not tracked (single leg) |
| Game ending  | GameCompleted | —     | `game_complete = true`          |

**Invariant**

* No `DartThrown` accepted after `GameCompleted`.
* No round-cap dialog or UI prompt — winner (or tie) is determined purely
  by score comparison; the only ambiguity (tie) is resolved as "no winner".

---

## 6. Derived Invariants (Must Always Hold)

* `0 ≤ darts_thrown_in_turn ≤ 3`
* `score ≥ handicap` for each competitor at all times (scores only go up)
* `1 ≤ current_round ≤ total_rounds`
* `0 ≤ current_turn_index < competitors.length`
* Only one active turn at a time
* The total number of `DartThrown` events emitted at game completion
  equals `competitors.length × total_rounds × 3`
* `game_complete == true` ⟺ `current_round == total_rounds` AND the
  competitor at `current_turn_index == competitors.length - 1` has thrown
  all 3 darts of their turn

---

## 7. Notes on Ambiguities (Explicitly Resolved)

The following interpretations are **required** for determinism:

1. **No early termination.** Even when the leader's score is
   mathematically unreachable by any other competitor, the game plays to
   the end. Every competitor throws exactly `total_rounds × 3` darts.
2. **Tie handling.** Two or more competitors tied at the top score at
   game end → `winner = null` (recorded tie). No sudden-death round, no
   tiebreaker, no UI prompt.
3. **Turn always lasts 3 darts.** A miss does not skip a dart. The turn
   ends only when `darts_thrown_in_turn == 3`. Players who somehow
   forfeit darts (UI cancellation, etc.) are out of scope for this spec.
4. **Bull values.** Single bull (`SB`) scores 25, double bull (`DB`)
   scores 50. Same as X01.
5. **Miss.** A miss (`segment = MISS`) increments `darts_thrown_in_turn`
   (Table E) and feeds Table F (turn-end check), but contributes
   `throw_value = 0` to the score (Table D).
6. **Handicap is a starting score, not a target.** Handicap raises a
   competitor's initial score; it does not subtract from anyone else.
7. **Round semantics.** A "round" is one full rotation where every
   competitor throws — same definition as elsewhere in this codebase.
   `total_rounds` counts rounds, not per-competitor turns.

---

## 8. Scoring Examples (Verification)

### Example A — solo, total_rounds = 8, handicap = 0

* 8 rounds × 3 darts = 24 darts. After all 24, `GameCompleted` fires with
  the solo player as winner regardless of their score.

### Example B — two players, total_rounds = 8, handicaps {A: 100, B: 0}

* Initial scores: A = 100, B = 0.
* After 8 full rounds (48 darts total), compare scores. Highest wins; tie
  → no winner.

### Example C — three players, tied at game end

* Final scores: A = 312, B = 312, C = 287.
* `leaders = {A, B}`, `len(leaders) == 2` → `GameCompleted(winner = null)`.

### Example D — turn-by-turn (2 players, total_rounds = 2, no handicap)

| Round | Player | Darts                | Round score | Cumulative |
| ----- | ------ | -------------------- | ----------- | ---------- |
| 1     | A      | T20, T20, S20        | 140         | 140        |
| 1     | B      | T19, S19, MISS       | 76          | 76         |
| 2     | A      | DB, S20, MISS        | 70          | 210        |
| 2     | B      | T20, T20, T20        | 180         | 256        |

After B's 3rd dart of round 2: Table H fires (`last_competitor && last_round`);
Table J: `leaders = {B}`, `GameCompleted(winner = B)`.

---

## 9. Statistics

Statistics follow the X01 shape, **minus checkout-related metrics** (no
checkout exists in this game). Stats are computed as projections from the
event stream — never stored pre-calculated.

### Per-game / per-player / career snapshot keys

| Key                          | Meaning                                                  |
| ---------------------------- | -------------------------------------------------------- |
| `count_up.average`           | PPR — points per 3-dart turn (total points ÷ turns × 3)  |
| `count_up.firstNineAverage`  | First-nine PPR — points scored in turns 1–3 of the leg   |
| `count_up.highScoreBuckets`  | Map `{ '100': n, '140': n, '180': n }` counting turns scoring ≥100 / ≥140 / =180 |

### Excluded (do not compute, do not display)

* Checkout average / checkout %
* Highest checkout
* Per-dart average

### Scope rules

Same conventions as X01:
* Turn-scope projections reset on `TurnStarted`.
* Leg-scope projections reset on `LegCompleted`.
* Match-scope projections reset on `GameCompleted`.
* First-nine projections require `TurnStarted` events (do not derive
  first-nine from `DartThrown` alone).

The end-of-game summary screen reuses the X01 layout with the
checkout-suggestion section removed.

---

## 10. What This Enables

From this spec you can now:

* Write a pure `CountUpEngine.apply(state, event)` with no rule ambiguity.
* Generate exhaustive unit tests covering 1, 2, and ≥3 player games,
  ties, and handicap initialisation.
* Enforce server-side validation (no bust, no early termination, exact
  dart count).
* Drive the in-game UI from `current_round / total_rounds` and per-player
  running totals.
* Compute statistics via the existing X01 projection plumbing minus the
  checkout pipeline.

No rule interpretation remains implicit.
