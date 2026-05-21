# Generic Statistics Architecture (Game-Agnostic)

**Status:** Authoritative
**Applies to:** All game types (X01, Cricket, future variants)
**Derived from:** Event-sourced game model

---

## 1. Core Principle

> **Statistics are projections over events, never part of game state.**

This architecture enforces:

* Determinism
* Replayability
* Game independence
* Zero coupling to UI or persistence

---

## 2. Conceptual Model

```
Game Events
   ↓
Projection Engine
   ↓
Statistic Projections (Read Models)
   ↓
UI / API / Exports
```

There is **no reverse dependency**.

---

## 3. Universal Projection Interfaces

These interfaces define the **entire statistics system**.

### 3.1 Projection Lifecycle

```text
Projection
- init(context)
- apply(event)
- reset(scope)
- snapshot()
```

Where:

* `context` = immutable game metadata (ruleset, players)
* `event` = canonical GameEvent
* `scope` = turn / leg / match
* `snapshot` = serializable read model

---

### 3.2 Projection Classification

Every statistic belongs to **exactly one category**:

| Category | Scope      | Example          |
| -------- | ---------- | ---------------- |
| Dart     | Event      | Score per dart   |
| Turn     | Turn       | 3-dart average   |
| Leg      | Leg        | Checkout %       |
| Match    | Game       | Match average    |
| Career   | Cross-game | Lifetime average |

---

## 4. Canonical Statistic Types

### 4.1 Counter

Monotonic increment.

```text
Examples:
- total_darts
- bust_turns
- legs_won
```

---

### 4.2 Accumulator

Tracks totals for later division.

```text
Examples:
- total_scored_points
- total_turn_score
```

---

### 4.3 Ratio

Derived, never stored.

```text
Examples:
- average = points / darts
- checkout_pct = success / attempts
```

---

### 4.4 Extremum

Tracks min/max.

```text
Examples:
- highest_checkout
- highest_turn
```

---

## 5. Projection Engine (Generic)

### 5.1 Responsibilities

The projection engine:

* Receives ordered events
* Routes events to projections
* Handles resets
* Supports replay from any offset

### 5.2 Engine Guarantees

* Events applied exactly once per replay
* Order = `global_sequence`
* Idempotent per event ID
* Stateless between replays

---

## 6. Projection Registration Model

Projections are **declared**, not discovered implicitly.

```text
ProjectionDescriptor
- id
- applies_to_game_types
- input_events
- scope
```

Example:

```text
"three_dart_average"
- applies_to: [X01, Cricket]
- input_events: [DartThrown, TurnEnded]
- scope: Match
```

---

## 7. Game-Specific vs Game-Agnostic Projections

### 7.1 Game-Agnostic (Reusable)

These apply to **all dart games**:

* Total darts thrown
* Darts per turn
* Turn count
* Average per dart
* Match duration
* Highest turn score

They rely only on:

* `DartThrown`
* `TurnStarted`
* `TurnEnded`
* `GameCompleted`

---

### 7.2 Game-Specific (Pluggable)

These depend on rules:

| Game    | Examples                       |
| ------- | ------------------------------ |
| X01     | Checkout %, double-out success |
| Cricket | Marks per turn, closure rate   |

### 7.3 Cricket Career Cohorts (target-mode aware)

Cricket career stats are bucketed by `targetMode` ∈ {`fixed`, `random`,
`crazy`} in addition to the existing `gameType` requirement. Random and
Crazy Cricket use different target sets than Standard Cricket, so
pooling them together would distort closure rates and MPR. Legacy games
(carrying no `targetMode`) fall into the `fixed` cohort. The loader
(`statistics_repository_drift.dart`) accepts a `cricketTargetMode`
parameter (default `fixed`); callers select a specific cohort. See
`docs/plans/2026-05-19-cricket-target-modes-design.md` §6.

**Crazy Cricket — turn-scoped marks caveat (load-bearing).** Under
Crazy Cricket, the active target set rotates every turn and any
non-locked number that leaves the active set has its per-competitor
marks wiped ("discard on rotate", design §4). Cumulative marks can
therefore **decrease** across turns — they are not monotonically
increasing the way they are under Standard or Random Cricket.

Projection consequences:

* Mark / MPR / MPT projections **must** count marks from `DartThrown`
  payloads inside each turn (turn-scoped, additive), never from a
  cross-turn diff of board state. The current cricket projections
  (`CricketMarksPerTurnProjection`, `CricketBestLegMptProjection`,
  `CricketMarkBucketsProjection`, `CricketFirstNineMprProjection`) do
  this correctly: they accumulate marks per dart via
  `cricketMarksFromPayload` and reset per-turn counters on
  `TurnStarted`/`TurnEnded`.
* The shared `CricketTargetsTracker` mixin keeps the active target set
  in sync by consuming `GameCreated` / `CricketTargetsAssigned` /
  `CrazyTargetsRolled` so the per-dart mark-counting helper sees the
  right set in effect at the moment the dart was thrown.

Game-specific projections:

* Must declare required rules
* Must not assume scoring semantics outside rules

---

## 8. Scope Reset Semantics (Critical)

| Scope | Reset Trigger   |
| ----- | --------------- |
| Dart  | Never           |
| Turn  | `TurnStarted`   |
| Leg   | `LegCompleted`  |
| Match | `GameCompleted` |

No projection may reset itself arbitrarily.

---

## 9. Correction & Replay Handling

### 9.1 Correction Rule

When a `DartCorrected` event appears:

1. Identify original event sequence
2. Replay **all projections** from that sequence forward
3. Replace all derived values

No projection may apply “delta correction”.

---

## 10. Projection Storage Model (Optional)

Statistics **may** be:

* Recomputed on demand
* Cached per game
* Materialized in SQL

But:

* Storage is an optimization
* Projection definitions remain pure

---

## 11. Cross-Game Aggregation (Career Stats)

Career stats are simply:

* Projections over **multiple game event streams**

No special architecture required.

---

## 12. Anti-Patterns Explicitly Forbidden

❌ Storing averages
❌ Updating stats inside game engine
❌ UI-driven statistics
❌ Manual corrections
❌ Mixing projections with state validation

---

## 13. Why This Architecture Scales

| Feature           | Supported             |
| ----------------- | --------------------- |
| New game types    | Plug-in projections   |
| Multiplayer       | Event order preserved |
| Offline           | Replay works          |
| Vision correction | Replay works          |
| Tournaments       | Aggregate projections |
| ML analytics      | Clean event streams   |

---

## 14. Mapping to X01 (Sanity Check)

| X01 Stat         | Projection Type     |
| ---------------- | ------------------- |
| 3-dart avg       | Accumulator + Ratio |
| Checkout %       | Counter + Ratio     |
| Highest checkout | Extremum            |
| Darts per leg    | Accumulator         |

No X01 logic leaks into the framework.

---

## 15. What You Have Achieved

At this point, your system has:

* A **formal event contract**
* **Deterministic game logic**
* **Exhaustive X01 transitions**
* **Complete X01 stats**
* A **future-proof statistics framework**

