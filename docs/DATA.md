# 🎯 Darts Game Data Specification

This document defines the data model for storing darts games, players, competitors (solo or team), and dart throws, optimized for **relational storage (SQLite)** and **statistical analysis**.

---

## 1. Core Concepts

### Player

A human participant.
Players **throw darts** but do not necessarily compete alone.

### Competitor

An entity that competes in a game and can win or lose.
A competitor is either:

* a **solo player**, or
* a **team of players**

Competitors are **game-scoped**.

### Game

A single match of a given darts game type (x01, cricket, etc.).
Games are **immutable once finished**.

### Dart Throw

A single dart thrown by a player and credited to a competitor.

---

## 2. Player

### Player Fields

* `player_id` — UUID (string)
* `name` — string
* `created_at` — ISO 8601 timestamp
* `last_active` — ISO 8601 timestamp

---

## 3. Game

### Game Fields

* `game_id` — UUID (string)
* `game_type` — string
  (`"x01"`, `"cricket"`, `"around-the-clock"`, `"killer"`, etc.)
* `start_time` — ISO 8601 timestamp
* `end_time` — ISO 8601 timestamp (nullable)
* `winner_competitor_id` — UUID (nullable)
* `immutable` — boolean (always `true` after completion)

### Game Rules

* A game owns its competitors.
* Players cannot change competitors during a game.
* Finished games are read-only; immutability is enforced by application logic.

---

## 4. Competitor

Competitors represent the competing entities in a game.

### Competitor Fields

* `competitor_id` — UUID (game-scoped)
* `game_id` — UUID
* `type` — `"solo"` | `"team"`
* `name` — string

### Competitor Rules

* All competitors in a game must have the same team size.
* A player may belong to **exactly one competitor per game**.
* Turn order alternates **between competitors**, not players.

---

## 5. Competitor Players (Team Composition & Rotation)

Defines which players belong to a competitor and their rotation order.

### Competitor Player Fields

* `competitor_id` — UUID
* `player_id` — UUID
* `rotation_position` — integer (0-based or 1-based, consistent per game)

### Rules

* Rotation order is fixed for the duration of the game.
* For solo competitors, exactly one player exists with rotation position 0.
* No uneven team sizes are allowed.

---

## 6. Dart Throw

A dart throw is the fundamental event used for scoring and statistics.

### Dart Throw Fields

* `dart_id` — UUID
* `game_id` — UUID
* `competitor_id` — UUID (who the dart scores for)
* `player_id` — UUID (who physically threw the dart)
* `turn_number` — integer (incremented per competitor turn)
* `dart_number` — integer (`1`, `2`, or `3`)
* `segment` — string
  (`"20"`, `"T20"`, `"D16"`, `"SB"`, `"DB"`, etc.)
* `score` — integer
* `x` — float (nullable)
* `y` — float (nullable)

### Rules

* Every dart is always attributed to **both** a player and a competitor.
* Dart order is defined by `(turn_number, dart_number)`.
* Darts are immutable once recorded.

---

## 7. Game Configuration (JSON)

```json
{
  "starting_score": 301 | 501 | 701 | 901,
  "max_rounds": integer | null,
  "in_strategy": "straight" | "double" | "master",
  "out_strategy": "straight" | "double" | "master",
  "handicaps": {
    "<competitor_id>": integer
  }
}
```

---

### Cricket Configuration

```json
{
  "variant": "standard" | "cut-throat" | "no-score",
  "numbers_in_play": [15, 16, 17, 18, 19, 20, "bull"]
}
```

---

### Around the Clock Configuration

```json
{
  "direction": "ascending" | "descending" | "random",
  "target_numbers": [1, 2, ..., 20],
  "required_hits": 1 | 2 | 3
}
```

---

### Killer Configuration

```json
{
  "starting_lives": integer,
  "number_assignment": "random" | "manual" | "sequential",
  "hit_requirement": "single" | "double" | "triple"
}
```

---

## 8. Game State (JSON, Runtime Only)

Game state represents the **current, resumable state** of an active game.

### Game State Fields

* `game_id` — UUID
* `current_competitor_id` — UUID
* `current_player_id` — UUID
* `current_turn` — integer
* `rotation_index` — object mapping competitor IDs to current rotation position
* `state_json` — object (game-specific runtime state)

### Rules

* Only present for active games.
* Discarded or archived once the game ends.
* Not used for historical statistics.

---

## 9. Data Storage Guidelines

### Relational (SQLite Tables)

Use relational tables for:

* players
* games
* competitors
* competitor_players
* dart_throws

### JSON Fields (TEXT columns)

Use JSON only for:

* game configuration
* active game state

---

## 10. Data Integrity Rules

* All foreign keys must be enforced.
* Games are immutable after completion.
* Players cannot appear in multiple competitors within a game.
* All dart throws must reference valid players and competitors.

---

## 11. Non-Goals (Explicitly Out of Scope)

* Legs / sets
* Uneven teams
* Mid-game roster changes
* Post-game edits
* Automatic data deletion
* Encryption or anonymization
* **Remote Multiplayer Data Modeling:** While remote multiplayer is a planned feature, its specific data modeling and synchronization mechanisms are detailed in the backend integration documentation (`docs/BACKEND_INTEGRATION.md`) and are out of scope for this core data specification.
