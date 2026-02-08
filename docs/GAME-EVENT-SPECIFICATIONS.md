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
winner_id        UUID?
completion_type  Enum        {checkout, forfeit, timeout}
```

**Invariant**

* No further gameplay events allowed after this

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
segment          Enum {1–20, bull}
multiplier       Integer {1, 2, 3}
input_method     Enum {manual, vision}
```

**Critical Invariants**

* Max 3 `DartThrown` per `TurnStarted`
* Must occur during active turn
* Segment × multiplier must be valid
* Rejected if game is complete

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

