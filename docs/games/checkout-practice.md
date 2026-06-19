# 170 Checkout Practice – Game Rules & State Transitions

**Status:** Authoritative (engine + server validation)

---

## 1. Overview

The 170 Checkout Practice game is a solo drill where the player starts at 170 and tries to reach 0 using standard X01 double-out rules. The goal is to practice executing the 170 checkout sequence from a full dart input grid.

It is a **multi-success quota drill**, not a single-checkout one. Each successful checkout increments a `practice_successes` counter, and the player re-attempts the 170 checkout repeatedly. The drill completes only when `practice_successes` reaches the configured `target_successes` quota. When `target_successes` is unset (∞), the drill never auto-completes and runs until the player manually ends the session.

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
* `darts_thrown` — total dart throws recorded across all turns
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
score = turn_start_score            // revert
turn_active = false
→ emit TurnEnded                    // turn ends immediately; remaining darts forfeited
```

> Note: a busted dart does **not** increment `darts_thrown` or `darts_thrown_in_turn`.

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
| Darts thrown | Total dart throws recorded (`darts_thrown`). Only counts darts that were **not** busted. |
| Successes | Running count of completed checkouts (`practice_successes`) — the quota progress toward `target_successes`. |
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
