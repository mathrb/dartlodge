# Around the Clock – Complete State Transition Tables

**Derived from:** `Around the Clock (Sequential Number Game)`
**Status:** Authoritative (engine + server validation)

---

## 1. State Model (Explicit)

The following state fields are assumed to exist.
These are *derived state*, never directly mutated outside transitions.

### Per Game

* `variant` ∈ {Standard, Reverse, DoublesOnly}
* `legs_to_win`
* `current_leg_index`
* `game_complete`

### Per Leg / Player

* `current_target` — Integer (the number player must hit next)
  * Standard: starts at 1, increments to 20
  * Reverse: starts at 20, decrements to 1
* `completed` — Boolean (player has hit all required numbers)
* `legs_won`

### Per Turn

* `turn_active` (bool)
* `darts_thrown_in_turn` ∈ {0, 1, 2, 3}
* `current_player`

---

## 2. Event Set (Relevant to Around the Clock)

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
| Player completed | DartThrown | —     | Reject |

---

## Table C — Initial Target Setup

Applied during GameCreated / Leg Reset:

| Variant  | Guard | Result              |
| -------- | ----- | ------------------- |
| Standard | —     | `current_target = 1` |
| Reverse  | —     | `current_target = 20` |
| Doubles  | —     | `current_target = 1` |

---

## Table D — Hit Validation (Standard & Reverse)

Let:
* `segment` = the number hit (1–20)
* `multiplier` ∈ {1, 2, 3} (single, double, triple)

### D1 — Standard/Reverse Variant

| State                      | DartThrown | Guard                        | Result              |
| -------------------------- | ---------- | ---------------------------- | ------------------- |
| `segment == current_target` | Any hit    | —                            | Advance target      |
| `segment ≠ current_target`  | Any hit    | —                            | No state change     |

**Notes**

* Any multiplier (single, double, triple) counts as valid hit
* Dart counts as thrown regardless of success

### D2 — Doubles Only Variant

| State                      | DartThrown      | Guard                        | Result              |
| -------------------------- | --------------- | ---------------------------- | ------------------- |
| `segment == current_target` | `multiplier = 2` | —                            | Advance target      |
| `segment == current_target` | `multiplier ≠ 2` | —                            | No state change     |
| `segment ≠ current_target`  | Any hit         | —                            | No state change     |

**Notes**

* ONLY doubles count as valid hits
* Singles and triples on correct number do NOT advance

---

## Table E — Target Advancement

Triggered when hit validation succeeds (Table D).

### E1 — Standard Variant

| State            | Guard | Result                   |
| ---------------- | ----- | ------------------------ |
| `current_target < 20` | —     | `current_target += 1`    |
| `current_target == 20` | —     | `completed = true`       |
| `completed == true` | —     | Proceed to Win Check (F) |

### E2 — Reverse Variant

| State            | Guard | Result                   |
| ---------------- | ----- | ------------------------ |
| `current_target > 1` | —     | `current_target -= 1`    |
| `current_target == 1` | —     | `completed = true`       |
| `completed == true` | —     | Proceed to Win Check (F) |

### E3 — Doubles Only Variant

Same as E1 (Standard progression), but only triggered by double hits.

---

## Table F — Win Condition Evaluation

Evaluated **immediately after each DartThrown** that sets `completed = true`.

| State              | Guard | Result       |
| ------------------ | ----- | ------------ |
| `completed == true` | —     | LegCompleted |

**Notes**

* Win is checked immediately, not at turn end
* Player wins on the dart that completes final target
* Remaining darts in turn are not thrown (turn ends immediately)

---

## Table G — Dart Count Increment

| State       | DartThrown | Guard | Result                      |
| ----------- | ---------- | ----- | --------------------------- |
| Turn active | DartThrown | —     | `darts_thrown_in_turn += 1` |

---

## Table H — Turn End Conditions

| State       | Event      | Guard             | Result    |
| ----------- | ---------- | ----------------- | --------- |
| Turn active | DartThrown | darts_thrown == 3 | TurnEnded |
| Turn active | Completed  | —                 | TurnEnded |

**Notes**

* Turn ends early if player completes on 1st or 2nd dart
* Completion triggers LegCompleted which then triggers TurnEnded

---

## Table I — Turn End

| State       | Event     | Guard | Result                   |
| ----------- | --------- | ----- | ------------------------ |
| Turn active | TurnEnded | —     | `turn_active = false`    |
| Turn active | TurnEnded | —     | Advance `current_player` |

---

## Table J — Leg Completion

| State        | Event | Guard                   | Result          |
| ------------ | ----- | ----------------------- | --------------- |
| LegCompleted | —     | —                       | `legs_won += 1` |
| LegCompleted | —     | legs_won < legs_to_win  | Reset Leg       |
| LegCompleted | —     | legs_won == legs_to_win | GameCompleted   |

---

## Table K — Leg Reset

Triggered after LegCompleted when match not finished.

| Action         | Variant  | Result                   |
| -------------- | -------- | ------------------------ |
| Reset target   | Standard | `current_target = 1`     |
| Reset target   | Reverse  | `current_target = 20`    |
| Reset target   | Doubles  | `current_target = 1`     |
| Reset complete | All      | `completed = false`      |
| Reset turn     | All      | `turn_active = false`    |
| Advance leg    | All      | `current_leg_index += 1` |

---

## Table L — Game Completion

| State     | Event         | Guard | Result                 |
| --------- | ------------- | ----- | ---------------------- |
| Match won | GameCompleted | —     | `game_complete = true` |

**Invariant**

* No DartThrown accepted after this point

---

## 4. Derived Invariants (Must Always Hold)

* `0 ≤ darts_thrown_in_turn ≤ 3`
* Standard/Doubles: `1 ≤ current_target ≤ 20`
* Reverse: `1 ≤ current_target ≤ 20`
* Only one active turn at a time
* `completed == true` ⟺ final target has been hit
  * Standard/Doubles: `current_target == 20` AND hit
  * Reverse: `current_target == 1` AND hit
* Once `completed == true`, player cannot throw more darts in that leg

---

## 5. Notes on Ambiguities (Explicitly Resolved)

The following interpretations are **required** for determinism:

1. **Hit recognition:** Only the segment number matters; multiplier is ignored (Standard/Reverse)
2. **Doubles Only:** ONLY double multiplier advances target; single/triple on correct number fails
3. **Bull/25:** Does NOT count as any number 1–20; ignored in all variants
4. **Out-of-sequence hits:** Hitting future targets does NOT advance (e.g., hitting 5 when on target 3)
5. **Immediate win:** Game ends on the dart that completes final target, remaining darts not thrown
6. **Turn continuation:** If player completes on 1st/2nd dart, turn ends immediately
7. **Multi-player:** Players continue in rotation even if one completes; game ends when winner determined

---

## 6. Progression Examples (Verification)

### Standard Variant
* Player at `current_target = 5`
* Throws single-5 → `current_target = 6`
* Throws triple-5 → no change (wrong target)
* Throws double-6 → `current_target = 7`

### Reverse Variant
* Player at `current_target = 15`
* Throws double-15 → `current_target = 14`
* Throws single-13 → no change (wrong target)
* Throws single-14 → `current_target = 13`

### Doubles Only Variant
* Player at `current_target = 10`
* Throws single-10 → no change (not a double)
* Throws triple-10 → no change (not a double)
* Throws double-10 → `current_target = 11`
* Player at `current_target = 20`
* Throws double-20 → `completed = true`, LegCompleted

### Completion Scenarios
* Player at target 20 (Standard), 1st dart misses, 2nd dart hits single-20 → immediate win, 3rd dart not thrown
* Player at target 1 (Reverse), throws double-1 on 3rd dart → immediate win

---

## 7. Variant Comparison Table

| Feature              | Standard        | Reverse         | Doubles Only    |
| -------------------- | --------------- | --------------- | --------------- |
| Starting target      | 1               | 20              | 1               |
| Ending target        | 20              | 1               | 20              |
| Direction            | Ascending       | Descending      | Ascending       |
| Hit requirement      | Any multiplier  | Any multiplier  | Doubles only    |
| Progression          | `target += 1`   | `target -= 1`   | `target += 1`   |

---

## 8. What This Enables

From this table you can now:

* Write a pure `AroundTheClockEngine.apply(state, event)`
* Generate exhaustive unit tests for all variants
* Enforce server-side validation
* Handle Standard, Reverse, and Doubles Only with single engine
* Implement early-win logic (game ends mid-turn)
* Track player progression clearly

No rule interpretation remains implicit.
