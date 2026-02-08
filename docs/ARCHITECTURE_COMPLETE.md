# Final Darts Application Architecture

This document defines the **final, production-ready architecture** for the darts application, addressing scalability, multiplayer correctness, offline-first guarantees, and long-term maintainability. It aligns Clean Architecture, event-based domain modeling, and real-time synchronization without architectural conflicts.

---

## Architectural Goals

* **Offline-first, event-driven**
* **Single source of truth for game rules**
* **Deterministic multiplayer synchronization**
* **Scalable Flutter state management**
* **Strict separation of concerns**
* **Future-proof for tournaments, analytics, and ML**

---

## 1. Flutter Frontend Structure

### Architectural Decision

The application uses **Feature-First Clean Architecture**.
Layer-based folders at the root level are removed to avoid dependency violations.

### Final Flutter Structure

```
lib/
├── core/                         # Cross-cutting, framework-agnostic
│   ├── error/
│   ├── network/
│   ├── persistence/
│   ├── utils/
│   └── config/
│
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── players/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── game/
│   │   ├── domain/
│   │   │   ├── engine/
│   │   │   ├── entities/
│   │   │   ├── events/
│   │   │   ├── rules/
│   │   │   └── usecases/
│   │   │
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   ├── datasources/
│   │   │   └── mappers/
│   │   │
│   │   └── presentation/
│   │       ├── state/
│   │       ├── widgets/
│   │       └── pages/
│   │
│   ├── statistics/
│   ├── sync/
│   └── settings/
│
└── main.dart
```

### Key Rules

* No feature imports another feature directly
* `core/` contains **no domain logic**
* Domain layers never import Flutter, SQLite, or HTTP

---

## 2. Game Engine Design (Engine + State + Events)

### Core Principle

**Games are event streams, not mutable objects.**

---

## Domain Model Overview

### Immutable Game State

```dart
class GameState {
  final String gameId;
  final GameType type;
  final List<CompetitorState> competitors;
  final int currentTurnIndex;
  final int dartsThrownInTurn;
  final bool isComplete;

  const GameState({...});
}
```

* Fully immutable
* Serializable
* Deterministically derived from events

---

### Game Events (Append-Only)

```dart
abstract class GameEvent {
  final String gameId;
  final DateTime occurredAt;
  final int sequence;

  const GameEvent();
}

class DartThrown extends GameEvent {
  final String competitorId;
  final int segment;     // e.g. 20, 19, bull
  final int multiplier; // 1, 2, 3
}
```

Other examples:

* `TurnEnded`
* `GameCompleted`
* `PlayerJoined`

---

### Game Engine (Pure Logic)

```dart
abstract class GameEngine {
  GameState apply(GameState state, GameEvent event);
  bool isValid(GameState state, GameEvent event);
}
```

Concrete implementations:

* `X01Engine`
* `CricketEngine`

The engine:

* Has **no persistence**
* Has **no serialization**
* Is fully deterministic and testable

---

### Game Rules (Explicit & Shareable)

```dart
class X01Rules {
  final int startingScore;
  final bool doubleOut;
}
```

Rules are:

* Explicit inputs
* Passed into engine constructors
* Shared with backend (conceptually identical)

---

## 3. Persistence Model (Frontend)

### SQLite Tables (Event-Based)

```
games
- id
- type
- rules_json

game_events
- id
- game_id
- sequence
- event_type
- payload_json
- created_at

sync_queue
- event_id
- status
- retry_count
```

### Key Rule

`game_state` is **derived**, never authoritative.

---

## 4. Backend Architecture (Event-First)

### Backend Structure

```
backend/
├── app/
│   ├── api/
│   ├── domain/
│   │   ├── engines/
│   │   ├── rules/
│   │   └── validators/
│   ├── services/
│   └── persistence/
```

* Backend replays events to validate state
* Backend engines mirror frontend engines
* Backend is authoritative for multiplayer ordering

---

## 5. Safe Sync Protocol (Darts-Specific)

### Why Darts Is Ideal for Event Sync

* Throws are immutable
* Order matters
* Conflicts are rare and resolvable

---

## Sync Model

### Client Responsibilities

1. Record every action as a `GameEvent`
2. Assign **local sequence numbers**
3. Push events in order
4. Never overwrite remote state

### Server Responsibilities

1. Validate event legality
2. Assign **global sequence numbers**
3. Persist events atomically
4. Broadcast confirmed events

---

## Sync Flow

### Offline

* Events stored locally
* UI updated optimistically
* Sync queue grows

### Online Reconciliation

1. Client sends unacknowledged events
2. Server validates and accepts/rejects
3. Server responds with authoritative event stream
4. Client replays events to rebuild state

### Conflict Handling

* Duplicate events → ignored (idempotency key)
* Invalid events → rejected with reason
* Out-of-order → reordered by server sequence

**No timestamps used for conflict resolution.**

---

## 6. Multiplayer Model

### Authority Model

* **Server-authoritative**
* Client is optimistic only

### Transport Rules

* REST: submit commands
* WebSocket: broadcast events + state snapshots

### Recovery

* Client reconnects
* Requests event stream from last known sequence
* Replays deterministically

---

## 7. Vision Integration (Decoupled)

### Vision Service Responsibilities

* Detect dart positions only
* Output `(x, y)` coordinates

### Board Mapping

* `BoardModel` converts coordinates → segments

### Game Engine

* Converts segments → score based on rules

This enables:

* Manual correction
* Multiple game types
* Board calibration

---

## 8. State Management (Flutter)

### Recommended

* Riverpod / Bloc / StateNotifier

### Pattern

* UI subscribes to `GameState`
* Events dispatched explicitly
* No mutable UI-driven state

---

## 9. Security Model

### Authentication

* JWT = user identity
* Refresh tokens = session continuity

### Multiplayer Authorization

* Game-scoped capability token
* JWT + capability required

### Validation

* All events validated server-side
* Sequence enforcement prevents replay attacks

---

## 10. Benefits of This Architecture

* ✅ No data loss during sync
* ✅ Deterministic replay & debugging
* ✅ Identical logic frontend/backend
* ✅ Scales to tournaments & analytics
* ✅ Multiplayer-safe by construction
* ✅ Vision errors are recoverable

