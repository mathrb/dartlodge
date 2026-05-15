# Cricket – Complete State Transition Tables

**Derived from:** `Cricket (Standard & Cut-Throat)`
**Status:** Authoritative (engine + server validation)

---

## 1. State Model (Explicit)

The following state fields are assumed to exist.
These are *derived state*, never directly mutated outside transitions.

### Per Game

* `variant` ∈ {Standard, CutThroat, NoScore}
* `legs_to_win`
* `current_leg_index`
* `game_complete`

### Per Leg / Player

* `hits` — Map of number → hit_count ∈ {0, 1, 2, 3}
  * Numbers: 15, 16, 17, 18, 19, 20, Bull
* `score` — Integer (points accumulated)
* `legs_won`
* `all_closed` — Boolean (derived: all numbers have hits ≥ 3)
* `close_order` — Integer (timestamp/sequence when `all_closed` first became true)

### Per Turn

* `turn_active` (bool)
* `darts_thrown_in_turn` ∈ {0, 1, 2, 3}
* `current_player`

---

## 2. Event Set (Relevant to Cricket)

* `GameCreated`
* `TurnStarted`
* `DartThrown`
* `TurnEnded`
* `LegCompleted`
* `GameCompleted`

---

## 3. Transition Tables

Each table is **orthogonal** and must be applied in order.

---

## Table A — Turn Start

| Current State  | Event       | Guard | Result                     |
| -------------- | ----------- | ----- | -------------------------- |
| No active turn | TurnStarted | —     | `turn_active = true`       |
| No active turn | TurnStarted | —     | `darts_thrown_in_turn = 0` |

**Invalid**

* TurnStarted while `turn_active == true` → reject

---

## Table B — DartThrown (General Acceptance)

| State Predicate  | Event      | Guard | Result |
| ---------------- | ---------- | ----- | ------ |
| Game complete    | DartThrown | —     | Reject |
| Turn inactive    | DartThrown | —     | Reject |
| DartsThrown == 3 | DartThrown | —     | Reject |

---

## Table C — Valid Cricket Numbers

| DartThrown Target | Guard | Result          |
| ----------------- | ----- | --------------- |
| 15–20, Bull       | —     | Proceed to D    |
| Other number      | —     | No state change |

**Notes**

* Dart counts as thrown regardless of target
* Invalid numbers are simply ignored (no error)

---

## Table D — Hit Count Calculation

Let:
* `target` = the number hit (15–20 or Bull)
* `multiplier` ∈ {1, 2, 3} (single, double, triple)
* `current_hits` = `hits[target]` for current player
* `hit_increment` = `multiplier`

**Special case for Bull:**
* Outer bull (25): `multiplier = 1`
* Inner bull (50): `multiplier = 2`

| Current State      | DartThrown | Guard               | Result                                           |
| ------------------ | ---------- | ------------------- | ------------------------------------------------ |
| `current_hits < 3` | Valid hit  | —                   | `new_hits = min(current_hits + hit_increment, 3)` |
| `current_hits < 3` | Valid hit  | —                   | `hits[target] = new_hits`                        |
| `current_hits < 3` | Valid hit  | `new_hits == 3`     | Number just closed, proceed to E                 |
| `current_hits < 3` | Valid hit  | `new_hits < 3`      | Proceed to E (overflow calculation)              |
| `current_hits = 3` | Valid hit  | —                   | Number already closed, proceed to E (scoring)    |

**Notes**

* Hits are capped at 3 per number
* Overflow hits (beyond 3) may score points depending on variant

---

## Table E — Overflow and Scoring Resolution

**Overflow calculation:**
* `overflow = max(0, (current_hits + hit_increment) - 3)`

Apply based on variant:

### E1 — Standard Cricket Scoring

| State                       | Guard          | Result                                    |
| --------------------------- | -------------- | ----------------------------------------- |
| Current player closed       | `overflow > 0` | `score += target × overflow`              |
| Current player closed       | `overflow > 0` | (No other player affected)                |
| Opponent has NOT closed     | `overflow > 0` | (No effect on opponent)                   |
| Opponent has closed         | `overflow > 0` | (No scoring possible)                     |
| **NoScore variant**         | Any            | Skip all scoring (Table E is no-op)       |

### E2 — Cut-Throat Cricket Scoring

| State                       | Guard          | Result                                               |
| --------------------------- | -------------- | ---------------------------------------------------- |
| Current player closed       | `overflow > 0` | Current player gains **0 points**                    |
| For each opponent           | `overflow > 0` | If `opponent.hits[target] < 3`: `opponent.score += target × overflow` |
| All opponents closed        | `overflow > 0` | No points awarded to anyone                          |

**Notes**

* Standard: Points go to the player who threw
* Cut-Throat: Points go to opponents who haven't closed
* NoScore: No scoring ever occurs

---

## Table F — All Closed Detection

After each DartThrown that modifies hits:

| State                              | Guard | Result                                |
| ---------------------------------- | ----- | ------------------------------------- |
| `all_closed == false`              | —     | Check: `hits[n] ≥ 3` for all n        |
| All numbers ≥ 3                    | —     | `all_closed = true`                   |
| All numbers ≥ 3                    | —     | `close_order = current_sequence_num`  |
| `all_closed == true` (already set) | —     | No change                             |

---

## Table G — Win Condition Evaluation

Evaluated **after each DartThrown** (may trigger LegCompleted immediately).

### G1 — Standard Cricket Win

| State                  | Guard                               | Result       |
| ---------------------- | ----------------------------------- | ------------ |
| `all_closed == true`   | `score ≥ all opponents' scores`     | LegCompleted |
| `all_closed == true`   | `score < any opponent's score`      | Continue     |
| `all_closed == false`  | —                                   | Continue     |

**Tie-breaking (Standard):**

If multiple all-closed competitors satisfy `score ≥ all opponents'
scores` (only reachable when their scores are equal — two players
both at the rotation's highest score):

* Winner = player with earliest `close_order`

Mirrors Cut-Throat (G2), NoScore (G3), and Table N. Without this rule
the implementation falls back to rotation order, which is arbitrary.

### G2 — Cut-Throat Cricket Win

| State                  | Guard                               | Result                           |
| ---------------------- | ----------------------------------- | -------------------------------- |
| `all_closed == true`   | `score ≤ all opponents' scores`     | LegCompleted                     |
| `all_closed == true`   | `score == 0`                        | LegCompleted (immediate victory) |
| `all_closed == true`   | `score > any opponent's score`      | Continue                         |
| `all_closed == false`  | —                                   | Continue                         |

**Tie-breaking (Cut-Throat only):**

If multiple players have same lowest score and all closed:
* Winner = player with earliest `close_order`

### G3 — NoScore Cricket Win

| State                  | Guard | Result       |
| ---------------------- | ----- | ------------ |
| `all_closed == true`   | —     | LegCompleted |
| `all_closed == false`  | —     | Continue     |

---

## Table H — Dart Count Increment

| State       | DartThrown | Guard | Result                      |
| ----------- | ---------- | ----- | --------------------------- |
| Turn active | DartThrown | —     | `darts_thrown_in_turn += 1` |

---

## Table I — Turn End Conditions

| State       | Event      | Guard             | Result    |
| ----------- | ---------- | ----------------- | --------- |
| Turn active | DartThrown | darts_thrown == 3 | TurnEnded |

**Note:** Cricket has no "bust" concept; turn always ends after 3 darts.

---

## Table J — Turn End

| State       | Event     | Guard | Result                   |
| ----------- | --------- | ----- | ------------------------ |
| Turn active | TurnEnded | —     | `turn_active = false`    |
| Turn active | TurnEnded | —     | Advance `current_player` |

---

## Table K — Leg Completion

| State        | Event | Guard                   | Result          |
| ------------ | ----- | ----------------------- | --------------- |
| LegCompleted | —     | —                       | `legs_won += 1` |
| LegCompleted | —     | legs_won < legs_to_win  | Reset Leg       |
| LegCompleted | —     | legs_won == legs_to_win | GameCompleted   |

---

## Table L — Leg Reset

Triggered after LegCompleted when match not finished.

| Action         | Result                             |
| -------------- | ---------------------------------- |
| Reset hits     | `hits[n] = 0` for all n            |
| Reset scores   | `score = 0`                        |
| Reset closed   | `all_closed = false`               |
| Reset order    | `close_order = null`               |
| Reset turn     | `turn_active = false`              |
| Advance leg    | `current_leg_index += 1`           |

---

## Table M — Game Completion

| State     | Event         | Guard | Result                 |
| --------- | ------------- | ----- | ---------------------- |
| Match won | GameCompleted | —     | `game_complete = true` |

**Invariant**

* No DartThrown accepted after this point

---

## Table N — Round Cap Termination (optional)

Fires **only** when `cricket_total_rounds` (per-leg cap) is set. Evaluated
on `TurnEnded` when the turn that just ended belonged to the last competitor
of the round. A natural win via Table G during the capped round still closes
the leg normally (Table G fires inside `DartThrown`, before the `TurnEnded`
that would trigger this table).

**Trigger condition**

```
cap_reached = cricket_total_rounds != null
           && current_round_in_leg >= cricket_total_rounds
           && current_turn_index == competitors.length - 1   // last competitor
```

**Winner selection by variant (no existing Table G winner on the board)**

Winner is chosen by the primary metric below; when the top two competitors
share the metric, tie-break prefers the **earliest `close_order`** (a player
who closed all numbers first). If both metric and `close_order` tie, the
outcome is ambiguous and the UI must prompt.

| Variant    | Primary metric                         | Higher wins? |
| ---------- | -------------------------------------- | ------------ |
| standard   | `score`                                | yes          |
| cut-throat | `score`                                | no (lowest)  |
| no-score   | `Σ hits[n]` over all cricket numbers   | yes          |

Solo play (one competitor) terminates silently with `winner_competitor_id = null`.

**Outcomes**

| Situation                                          | LegOutcome signal  | State change                                                                       |
| -------------------------------------------------- | ------------------ | ---------------------------------------------------------------------------------- |
| Solo or auto-winner with `legs_won ≥ legs_to_win`  | `gameCompleted`    | `is_complete = true`; emit `LegCompleted` + `GameCompleted`                        |
| Auto-winner, more legs remaining                   | `legCompleted`     | Increment winner `legs_won`, apply **Table L** reset, emit `LegCompleted`          |
| Multi-player with no auto-winner                   | `roundCapReached`  | Persist only `TurnEnded`; notifier sets `pendingCapSelection = true` for UI prompt |

**UI ambiguity resolution**

After `roundCapReached`, the user picks a winner from the cap-selection
dialog. The notifier's `selectCapWinner(competitorId)` emits a synthetic
`LegCompleted` event through the engine's standard path (Table K), so
`legs_won` increments and Table L / Table M handle the subsequent
transition uniformly.

**Invariants**

* The cap never fires during a `DartThrown` — only on `TurnEnded`.
* A natural win via Table G on the last dart of the capped round completes
  the leg before any `TurnEnded` is emitted.
* When `LegOutcome.roundCapReached` is returned, no `LegCompleted` or
  `GameCompleted` event has yet been persisted.

---

## 4. Derived Invariants (Must Always Hold)

* `0 ≤ darts_thrown_in_turn ≤ 3`
* `0 ≤ hits[n] ≤ 3` for all numbers n
* `score ≥ 0`
* Only one active turn at a time
* `all_closed == true` ⟺ `∀n: hits[n] ≥ 3`
* `close_order` is immutable once set
* LegCompleted can only trigger via Table G (win conditions)

---

## 5. Notes on Ambiguities (Explicitly Resolved)

The following interpretations are **required** for determinism:

1. **Overflow scoring** only occurs when a number is already closed (hits = 3)
2. **Bull scoring:**
   * Outer bull (25): counts as 1 hit, scores `25 × overflow`
   * Inner bull (50): counts as 2 hits, scores `25 × overflow` (NOT 50)
   * This matches standard cricket scoring: bull value is always 25 per hit
3. **Cut-throat tie-breaking:** If multiple players finish with same lowest score, earliest `close_order` wins
4. **Win evaluation timing:** Checked immediately after each dart, not just at end of turn
5. **NoScore variant:** All scoring logic (Table E) is skipped; only hit tracking matters
6. **Invalid numbers:** Darts that hit 1–14, 21–25 (except bull) count as thrown but have no effect

---

## 6. Scoring Examples (Verification)

### Standard Cricket
* Player A closes 20 (hits = 3)
* Player A throws triple-20 → `overflow = 3`, `score += 20 × 3 = 60`
* Player B (20 not closed) → no effect

### Cut-Throat Cricket
* Player A closes 20 (hits = 3)
* Player A throws triple-20 → `overflow = 3`
  * Player A: `score += 0`
  * Player B (20 not closed): `score += 20 × 3 = 60`
  * Player C (20 closed): `score += 0`

### Closing Progress
* Player hits double-20 while at 1 hit → `new_hits = min(1 + 2, 3) = 3`
* Player hits triple-20 while at 2 hits → `new_hits = min(2 + 3, 3) = 3`, `overflow = 2`

---

## 7. What This Enables

From this table you can now:

* Write a pure `CricketEngine.apply(state, event)`
* Generate exhaustive unit tests for all variants
* Enforce server-side validation
* Handle Standard, Cut-Throat, and NoScore variants with single engine
* Reconcile vision corrections safely

No rule interpretation remains implicit.
