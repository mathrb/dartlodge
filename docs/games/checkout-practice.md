# Checkout Practice – Game Rules & State Transitions

**Status:** Authoritative (engine + server validation)

---

## 1. Overview

Checkout Practice is a solo drill where the player starts on a checkout **target** and tries to
reach 0 using standard X01 double-out rules, grooving finishing sequences from a full dart input grid.

It is a **multi-success quota drill**, not a single-checkout one. Each successful checkout increments a `practice_successes` counter, and the player re-attempts the checkout repeatedly. The drill completes only when `practice_successes` reaches the configured `target_successes` quota. When `target_successes` is unset (∞), the drill never auto-completes and runs until the player manually ends the session.

### 1.1 Target modes (#636)

Each **run** (one attempt at a target, possibly spanning several visits, ending on a checkout) starts
from a checkout target chosen by `targetMode`:

| Mode | Target per run (`runIndex` = completed checkouts so far) |
|---|---|
| `fixed` | `fixedTarget` every run (default **170** — the classic drill). |
| `random` | a checkoutable value in `[minTarget, maxTarget]`, re-chosen each run. |
| `progressive` | a pyramid: `minTarget + step·runIndex`, **clamped at `maxTarget`** (sits at the top once reached) and snapped to the nearest checkoutable score. |

The target is **deterministic and replay-pure**: `checkoutTargetForRun(mode, …, gameId, runIndex)`
(`lib/core/utils/checkout_target.dart`). Random uses a stable hash of `gameId`+`runIndex` (not
`String.hashCode`) so a replay months later picks the same targets; undo is safe because `runIndex`
(= `practiceSuccesses`) is recomputed. The run's target is stamped as **`from_score`** on the
run-start `TurnStarted` (game-start + each post-checkout TurnStarted) so the engine and all stats
read one agreed value. Legacy games (no `from_score`/`targetMode`) → `fixed` 170.

---

## 2. Setup

| Parameter | Value |
|---|---|
| Players | 1 (solo drill) |
| Darts per turn | Up to 3 (turn ends early on checkout or bust) |
| Starting score | 170 |
| Out rule | Double-out |
| Target successes | Number of checkouts to complete the drill. One of {1, 2, 3, 5, 10, 20} or ∞ (unset → run until "End Drill"). Maps to `GameState.checkout_target_successes`. |
| End condition | `practice_successes` reaches `target_successes` OR player taps "End Drill" (no auto-completion when `target_successes` is ∞) |

There is no "in" strategy — the player is always "in" from the first dart.

---

## 3. State Model

### Per Session

* `score` — current score; starts at 170
* `darts_thrown` — total darts physically thrown across all turns (including busted darts; a bust voids the score, not the throw — see §4)
* `target_successes` — configured checkout quota (int) or `null` for ∞; immutable for the session
* `practice_successes` — running count of successful checkouts; starts at 0, increments on each checkout
* `game_complete` — boolean

### Per Turn

* `turn_active` — boolean
* `turn_start_score` — score at the moment TurnStarted fired (used for bust revert)
* `darts_thrown_in_turn` ∈ {0, 1, 2, 3}

---

## 4. Turn Transitions

### TurnStarted

Precondition: `turn_active == false`

```
if score == 0:                      // previous turn just checked out (multi-success mode)
    score = 170                     // reset to starting score for the next attempt
turn_start_score = score
darts_thrown_in_turn = 0
turn_active = true
```

> Note: after a checkout, `DartThrown` leaves `score == 0` so the checkout can be detected at `TurnEnded` time. The next `TurnStarted` therefore resets both `score` and `turn_start_score` back to the starting score (170) before the next attempt. Without this reset, a bust on the new attempt would revert `score` to 0 and block future checkouts.

### DartThrown

Preconditions: `turn_active == true`, `darts_thrown_in_turn < 3`, `game_complete == false`

```
dart_value = segment_value(dart)    // e.g. T20 = 60, DB = 50, MISS = 0
new_score = score - dart_value
```

**Checkout** — `new_score == 0` AND dart is a double (D1–D20 or DB):

```
score = 0                           // left at 0; reset to 170 on next TurnStarted
practice_successes += 1
darts_thrown += 1
darts_thrown_in_turn = 3            // remaining slots padded; turn is full
→ emit TurnEnded(reason = 'checkout')
```

> The checkout dart does **not** itself emit `GameCompleted`. Completion is decided later, at `TurnEnded` (see §5), so the event stream is always `DartThrown → TurnEnded(reason='checkout') → GameCompleted` when the drill ends — the projection counts the final attempt and success correctly.

**Bust** — `new_score < 0`, OR `new_score == 1`, OR (`new_score == 0` AND dart is NOT a double):

```
score = turn_start_score            // revert SCORE only
darts_thrown += 1                   // the bust dart was physically thrown — it counts
turn_active = false
→ emit TurnEnded                    // turn ends immediately; remaining darts forfeited
```

> Note: a bust reverts the **score** to `turn_start_score`, but the darts were still physically
> thrown, so they **count** toward `darts_thrown` (the bust-causing dart included). The rule is
> simply: a dart physically thrown counts; a bust voids the score, not the throw. Only the turn's
> *un-thrown* darts (forfeited when the turn ends early) are not counted.
>
> This is consistent with the broader three-dart-average convention (a busted visit's darts are
> darts thrown — see #634, which applies it to the X01 average). Note that #634's *padding* of a
> busted visit up to a full 3-dart visit is an **averaging-denominator** convention and does **not**
> apply here: this is a raw count of darts actually thrown, so a bust on the 1st or 2nd dart counts
> 1 or 2, not 3.

**Normal** — `new_score > 1`:

```
score = new_score
darts_thrown += 1
darts_thrown_in_turn += 1

if darts_thrown_in_turn == 3:
    → emit TurnEnded
```

### TurnEnded

```
turn_active = false
darts_thrown_in_turn = 0
```

---

## 5. End Conditions

Completion is evaluated at `TurnEnded`, after `practice_successes` has been incremented by the checkout dart:

| Condition | Result |
|---|---|
| At `TurnEnded(reason='checkout')` AND `target_successes != null` AND `practice_successes >= target_successes` | `GameCompleted` emitted; player is the winner |
| At `TurnEnded(reason='checkout')` AND `practice_successes < target_successes` | Drill continues; next attempt resets to 170 on `TurnStarted` |
| `target_successes == null` (∞) | Never auto-completes; drill continues regardless of checkout count |
| Player taps "End Drill" | `GameCompleted` emitted; no winner |

---

## 6. Scoring / Statistics

Stats are shown at the end of the drill.

| Metric | Definition |
|---|---|
| Darts thrown | Total darts physically thrown (`darts_thrown`), **including** busted darts (a bust voids the score, not the throw — see §4 and #634). Excludes only the un-thrown darts forfeited when a turn ends early on a checkout or bust. |
| Successes | Running count of completed checkouts (`practice_successes`) — the quota progress toward `target_successes`. |
| Checkout attempt | A **visit in which the player threw at a finishing double** — i.e. the visit's running score reached a single-dart double-out position (an even score 2..40, or 50/DB; see `isOnADoubleFinish`). Pure setup/scoring visits, where the player never got to a double, are **not** attempts (#635). A checkout visit is always an attempt (it finished on a double). So a 170 completed over several visits counts as 1 attempt, not N — it is not diluted by the scoring visits. (This is the same convention X01 checkout % uses — #637.) |
| Success rate | `successes / attempts` (per the attempt definition above), not `successes / visits`. |
| Darts per checkout | `darts_thrown / successes` (#636) — the headline efficiency metric for a varied-target drill. |
| FROM | The target the player checks out from: a single value (`fixed`) or a range — `min–max` (`random`) / `min→max` (`progressive`) (#636). |
| Checkout score | The score at the **start of the finishing turn** (`turn_start_score` when `GameCompleted` fires on a checkout). Indicates the checkout value the player actually executed. |

> Example: player reaches 40 before the final turn, then checks out D20. Checkout score = 40; darts thrown = total across all turns.

Stats are computed as projections from events; never stored pre-calculated.

---

## 7. Invalid States

| Situation | Handling |
|---|---|
| `DartThrown` when `turn_active == false` | Rejected |
| `DartThrown` when `darts_thrown_in_turn == 3` | Rejected |
| `DartThrown` when `game_complete == true` | Rejected |
| `TurnStarted` when `turn_active == true` | Rejected |
| `TurnStarted` when `game_complete == true` | Rejected |
