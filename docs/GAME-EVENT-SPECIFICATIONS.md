# Game Event Contract & Domain Invariants

**Document status:** Authoritative
**Scope:** Frontend + Backend + Sync + Multiplayer

---

## 1. Purpose

This document defines the **canonical event model** for all darts games.
All game state, statistics, synchronization, and multiplayer behavior are derived **exclusively** from these events.

> **No game state may be mutated outside of event application.**

---

## 2. Core Principles

1. **Event Sourcing**

   * Events are immutable facts
   * State is always derived

2. **Deterministic Replay**

   * Replaying the same events yields the same state

3. **Single Authority for Ordering**

   * Server assigns global order
   * Clients may speculate but must reconcile

4. **Append-Only**

   * Events are never updated or deleted
   * Corrections are new events

---

## 3. Event Envelope (Mandatory Fields)

Every event MUST include the following fields.

```text
event_id        UUID        Globally unique, idempotency key
game_id         UUID        Game aggregate identifier
event_type      String      Discriminator (e.g. DartThrown)
actor_id        UUID        Player or system actor
occurred_at     Timestamp   Client-observed time (non-authoritative)

local_sequence  Integer     Client-side monotonic sequence
global_sequence Integer?    Server-assigned sequence (null until confirmed)

source          Enum        {client, server, vision}
```

### Ordering Rules

* `global_sequence` is the **only authoritative order**
* `local_sequence` is advisory only
* Events without `global_sequence` are provisional

---

## 4. Canonical Game Events

### 4.1 Game Lifecycle

#### `GameCreated`

```text
ruleset          Enum        {X01, Cricket, ...}
rules_payload    JSON        Game-specific rules
competitors      List<UUID>
```

**Invariant**

* First event in any game
* Exactly one per game

---

#### `GameCompleted`

```text
winner_competitor_id  UUID?
winner_player_id      UUID?       (optional; resolved player for the
                                  winning competitor when known)
completion_type       Enum        {checkout, forfeit, timeout}
```

**Invariant**

* No further gameplay events allowed after this
* `winner_competitor_id` matches the `Game.winner_competitor_id`
  column and mirrors `LegCompleted`'s payload key

**Backwards compatibility:** Events persisted before this rename
used the key `winner_id` instead of `winner_competitor_id`. All
engine readers fall back to `winner_id` when `winner_competitor_id`
is absent, so existing event logs continue to deserialise.

---

#### `CricketTargetsAssigned`

```text
targets    List<Integer>    Exactly 6 distinct numbers drawn uniformly
                            from 1–20. Bull (25) is implicit as a 7th
                            target and never randomised.
```

**Emitted by**

* Cricket games with `target_mode = "random"`, immediately after
  `GameCreated` and before the first `TurnStarted`. The RNG runs
  **once** in `CreateGameUseCase` and is persisted in the payload —
  `engine.apply()` is pure and just reads the list, so replay is
  deterministic by construction (no replay-time RNG).

**Invariants**

* Exactly one per game; never emitted for `target_mode = "fixed"`.
* `targets.length == 6`, no duplicates, all values ∈ 1..20.
* **Game-scoped**: the assigned set persists across all legs (no
  re-roll on leg reset). Mirrors the DARTSLIVE "Random Cricket" /
  Mulligan canonical rules. See
  `docs/plans/2026-05-19-cricket-target-modes-design.md` §3.

---

#### `CrazyTargetsRolled`

```text
competitor_id   UUID            The competitor whose turn just started.
round           Integer         The leg-relative round number (1-indexed).
open_targets    List<Integer>   The 6 active numbers for the new turn:
                                locked numbers preserved, non-locked
                                slots freshly rolled uniformly from 1–20
                                (distinct within the board, excluding
                                locked). Bull (25) is implicit and never
                                appears in this list.
```

**Emitted by**

* Cricket games with `target_mode = "crazy"`, immediately after **every**
  `TurnStarted`. The RNG runs once per turn in the use case emitting the
  TurnStarted; `engine.apply()` is pure and just reads the payload, so
  replay is deterministic by construction.

**Invariants**

* `open_targets.length == 6`, no duplicates, all values ∈ 1..20.
* All currently-locked numbers are present in `open_targets`
  (they don't get re-randomised once locked — design §4).
* **Leg-scoped**: leg reset clears `cricketLockedTargets`; the next
  `CrazyTargetsRolled` therefore rolls all 6 slots fresh.
* Engine effect: replaces `state.cricketTargets` with `open_targets`
  and **discards** marks on any number that was active last turn but
  is not in the new set and not locked ("discard on rotate"). Marks
  on locked numbers and on numbers that stay active are preserved.
  See `docs/plans/2026-05-19-cricket-target-modes-design.md` §4.

---

### 4.2 Turn Control

#### `TurnStarted`

```text
competitor_id    UUID
turn_index       Integer
```

**Invariant**

* Only one active turn at a time

---

#### `TurnEnded`

```text
competitor_id    UUID
reason           Enum {normal, bust, disconnect}
```

---

### 4.3 Dart Throws (Core Event)

#### `DartThrown`

```text
competitor_id    UUID
segment          Enum {0, 1–20, bull}
                 0 = miss (dart did not hit a scoring segment)
multiplier       Integer {1, 2, 3}
input_method     Enum {manual, camera}   # 'camera' = on-device auto-scorer (#377)
```

**Critical Invariants**

* Max 3 `DartThrown` per `TurnStarted`
* Must occur during active turn
* Segment × multiplier must be valid
* Rejected if game is complete

> A miss (`segment = 0, multiplier = 1`) is a valid throw. It scores zero, does not trigger in-strategy resolution, and does not cause a bust. The dart counts toward `darts_thrown_in_turn`.

---

### 4.4 Vision Corrections (Optional but Supported)

#### `DartCorrected`

```text
original_event_id  UUID
corrected_segment  Enum
corrected_multiplier Integer
```

**Invariant**

* Must reference an existing `DartThrown`
* Original event is not removed
* Engine must recompute state from correction forward

---

### 4.5 Multiplayer / System Events

#### `PlayerJoined`

```text
competitor_id UUID
```

#### `PlayerDisconnected`

```text
competitor_id UUID
```

---

## 5. Game State Invariants (Global)

These invariants must hold **after every event application**.

### 5.1 Structural Invariants

* Exactly one active turn at any time
* Game must start with `GameCreated`
* `global_sequence` strictly increases
* Events are applied in `global_sequence` order only

---

### 5.2 X01-Specific Invariants

* Score may never go below zero
* Bust resets score to turn start
* Checkout rules (double-out, etc.) enforced
* No throws after checkout

---

### 5.3 Cricket-Specific Invariants

* A number must be closed before scoring surplus
* Game completes only when all numbers closed AND leading
* Invalid hits are ignored, not rejected

---

## 6. Event Validation Responsibility

| Layer    | Responsibility                     |
| -------- | ---------------------------------- |
| Client   | Prevent obvious invalid events     |
| Server   | Enforce all invariants             |
| Engine   | Pure validation & state transition |
| Database | Enforce ordering & idempotency     |

---

## 7. Idempotency & Duplication Rules

* `event_id` is globally unique
* Duplicate `event_id` → ignored
* Conflicting payload for same `event_id` → error
* Clients may resend events safely

---

## 8. Replay & Recovery Rules

* State reconstruction is done by replaying all events
* Partial replay allowed from last known `global_sequence`
* Vision corrections require replay from correction point

---

## 9. What Is Explicitly Not an Event

* UI actions
* Animations
* Button presses
* Derived statistics
* Cached game state

These are **projections**, not facts.

---

## 10. Consequences of This Model

### Advantages

* Offline-safe
* Multiplayer-safe
* Audit-friendly
* Debuggable
* Vision-error tolerant

### Trade-offs

* Slightly more complex mental model
* Requires discipline (no “quick state hacks”)

---

## 11. Non-Negotiable Rule

> **If it changes the game, it must be an event.**

No exceptions.

