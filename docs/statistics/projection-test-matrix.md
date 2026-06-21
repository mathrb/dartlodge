# Generic Projection Test Matrix

**Status:** Authoritative
**Scope:** All statistics projections (game-agnostic and game-specific)

---

## 1. Purpose

This document defines **what must be true** of any statistics projection implementation.

It is:

* Language-agnostic
* Game-agnostic
* Event-driven
* Replay-centric

> If a projection passes this matrix, it is safe.

---

## 2. Test Dimensions Overview

Every projection must be tested across **five orthogonal dimensions**:

| Dimension           | Why                         |
| ------------------- | --------------------------- |
| Event correctness   | Math & logic                |
| Ordering            | Determinism                 |
| Scope resets        | Lifecycle safety            |
| Replay & correction | Offline + vision            |
| Isolation           | No cross-projection leakage |

---

## 3. Universal Projection Test Categories

### Category A — Construction & Initialization

| Test | Description                                |
| ---- | ------------------------------------------ |
| A1   | Projection initializes with empty state    |
| A2   | Initialization uses only immutable context |
| A3   | No event applied before init               |
| A4   | Snapshot after init is deterministic       |

**Failure indicates:** hidden state, config leakage

---

### Category B — Single Event Application

| Test | Description                                         |
| ---- | --------------------------------------------------- |
| B1   | Applying supported event mutates projection         |
| B2   | Unsupported events are ignored                      |
| B3   | Same event applied twice has no effect (idempotent) |
| B4   | Event with earlier sequence is rejected or ignored  |

**Required invariant:**
`apply(event_id=X)` must be idempotent.

---

### Category C — Event Ordering & Determinism

| Test | Description                                       |
| ---- | ------------------------------------------------- |
| C1   | Events applied in sequence produce same snapshot  |
| C2   | Same events, different replay speed → same result |
| C3   | Parallel replays converge to identical snapshot   |

**Golden rule:**
Event order = `(game_id, local_sequence)`, nothing else.

---

### Category D — Scope Reset Semantics

| Scope | Reset Trigger   | Required Test |
| ----- | --------------- | ------------- |
| Turn  | `TurnStarted`   | D1            |
| Leg   | `LegCompleted`  | D2            |
| Match | `GameCompleted` | D3            |

#### Example Tests

* D1: Turn stats reset on `TurnStarted`, not `TurnEnded`
* D2: Leg stats preserved across turns, reset on leg end
* D3: Match stats persist until game completion

**Forbidden:** manual resets inside projection logic.

---

### Category E — Replay & Correction Safety

| Test | Description                                     |
| ---- | ----------------------------------------------- |
| E1   | Replay from zero yields identical snapshot      |
| E2   | Replay from midpoint yields same final snapshot |
| E3   | `DartCorrected` invalidates future projections  |
| E4   | No delta-patch logic allowed                    |

**Key invariant:**

> Replay ≡ original execution

---

### Category F — Partial Streams & Truncation

| Test | Description                               |
| ---- | ----------------------------------------- |
| F1   | Projection handles incomplete game        |
| F2   | Missing `GameCompleted` handled safely    |
| F3   | Mid-turn truncation yields valid snapshot |

Critical for:

* Offline play
* Crashes
* Live spectators

---

### Category G — Projection Isolation

| Test | Description                                 |
| ---- | ------------------------------------------- |
| G1   | Projection output independent of others     |
| G2   | No shared mutable state                     |
| G3   | Disabling projection does not affect others |

---

### Category H — Performance Boundaries (Design-Level)

| Test | Description                   |
| ---- | ----------------------------- |
| H1   | O(n) replay where n = events  |
| H2   | No nested replay inside apply |
| H3   | Snapshot size bounded         |

No micro-optimizations yet — just guarantees.

---

## 4. Projection Type–Specific Tests

### 4.1 Counter Projections

| Test | Description                          |
| ---- | ------------------------------------ |
| Ctr1 | Counter never decrements             |
| Ctr2 | Reset occurs only on defined scope   |
| Ctr3 | Correction replays counter correctly |

---

### 4.2 Accumulator Projections

| Test | Description                  |
| ---- | ---------------------------- |
| Acc1 | Accumulates correct totals   |
| Acc2 | Bust/invalid events excluded |
| Acc3 | Replay yields same total     |

---

### 4.3 Ratio Projections

| Test | Description                       |
| ---- | --------------------------------- |
| Rat1 | Division by zero safe             |
| Rat2 | Ratio derived, not stored         |
| Rat3 | Numerator/denominator consistency |

---

### 4.4 Extremum Projections

| Test | Description                   |
| ---- | ----------------------------- |
| Ext1 | Initial value neutral         |
| Ext2 | Updates only on improvement   |
| Ext3 | Correction can lower extremum |

---

## 5. Game-Agnostic Projection Compliance Matrix

| Projection   | Must Pass |
| ------------ | --------- |
| Total darts  | A–H       |
| Turn count   | A–H       |
| Avg per dart | A–H + Rat |
| Highest turn | A–H + Ext |

---

## 6. Game-Specific Projection Compliance

Game-specific projections must additionally prove:

| Test | Requirement                      |
| ---- | -------------------------------- |
| GS1  | Rule dependency declared         |
| GS2  | Invalid under other games        |
| GS3  | Rule change invalidates snapshot |

Example:

* X01 checkout % invalid under Cricket
* Cricket MPR: a hit on a number closed by ALL competitors counts 0 marks
  (#638); overflow on a number still open for an opponent, and the dart that
  closes for the last competitor, still count. See `cricket.projections.md` §2.1.

---

## 7. Cross-Game Replay Tests

| Test | Description                      |
| ---- | -------------------------------- |
| XG1  | Mixed games do not pollute stats |
| XG2  | Career stats aggregate correctly |
| XG3  | Deleting one game updates totals |

---

## 8. Failure Classification (Mandatory)

Every test failure must map to exactly one category:

* ❌ Logic error
* ❌ Ordering violation
* ❌ Scope violation
* ❌ Replay violation
* ❌ Isolation breach

No ambiguous failures allowed.

---

## 9. Test Matrix as Contract

This matrix is:

* A **design contract**
* A **future test plan**
* A **review checklist**
* A **regression safety net**

Any projection added later must explicitly declare:

> “I satisfy the Generic Projection Test Matrix.”

---

## 10. What You Now Have (Big Picture)

At this point, your system design includes:

* Deterministic event model
* Formal game state transitions
* Exhaustive X01 rules
* Game-agnostic statistics framework
* **A projection correctness contract**

