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
* `game_type` — string. Stored as the camelCase Dart enum name (e.g. `"x01"`, `"cricket"`, `"aroundTheClock"`, `"shanghai"`, `"catch40"`, `"bobs27"`, `"checkoutPractice"`, `"countUp"`). The canonical list lives in the `GameType` enum (`lib/core/utils/constants.dart`).
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

`config_json` is a JSON object whose shape is dispatched by the parent game's `game_type`. The authoritative source is the `GameConfig` sealed union in `lib/features/game/domain/models/game_config.dart`. JSON keys are camelCase (matching the Dart field names).

Every variant supports an optional `startingPlayerId` (UUID, nullable). Only the variant-specific keys are listed below.

### X01 (`game_type = "x01"`)

```json
{
  "startingScore": 301 | 501 | 701 | 901,
  "inStrategy": "straight" | "double" | "master",
  "outStrategy": "straight" | "double" | "master",
  "legsToWin": 1,
  "totalRounds": integer | null,
  "startingPlayerId": "<uuid>" | null,
  "handicaps": {
    "<competitor_id>": integer
  }
}
```

* `handicaps` is a per-competitor signed offset applied to the starting score (e.g. `-50` means that competitor starts at `startingScore - 50`).
* `totalRounds` is a per-leg round cap. When the cap is reached without a winner, the leg is decided by current standing (see `CLAUDE.md` — Per-leg round cap).

### Cricket (`game_type = "cricket"`)

```json
{
  "scoring": "standard" | "cut-throat" | "no-score",
  "targetMode": "fixed" | "random" | "crazy",
  "numbers": ["15", "16", "17", "18", "19", "20", "bull"],
  "legsToWin": 1,
  "totalRounds": integer | null,
  "startingPlayerId": "<uuid>" | null
}
```

* `scoring` is **how points work**; `targetMode` is **which numbers are
  targets**. The two axes are orthogonal — any combination is legal. See
  `docs/plans/2026-05-19-cricket-target-modes-design.md` and
  `docs/games/cricket.transitions.md`.
* **Backward compatibility:** legacy payloads carrying a single `variant`
  string deserialise to `{scoring: <that>, targetMode: "fixed"}` at read
  time. No event migration; historical replay is unaffected.
* Today only `targetMode: "fixed"` ships end-to-end (this PR is the
  foundation refactor); `random` and `crazy` land in PRs #237 / #238.

### Around the Clock (`game_type = "aroundTheClock"`)

```json
{
  "variant": "standard" | "reverse" | "doublesOnly",
  "startingPlayerId": "<uuid>" | null
}
```

### Shanghai (`game_type = "shanghai"`)

```json
{
  "totalRounds": 7,
  "startingPlayerId": "<uuid>" | null
}
```

### Catch 40 (`game_type = "catch40"`)

```json
{
  "totalRounds": 8,
  "roundTargets": [10, 15, 20, 25, 30, 35, 40, 45],
  "startingPlayerId": "<uuid>" | null
}
```

### Bob's 27 (`game_type = "bobs27"`)

```json
{
  "startingPlayerId": "<uuid>" | null
}
```

### Checkout Practice (`game_type = "checkoutPractice"`)

```json
{
  "randomOrder": false,
  "targetSuccesses": integer | null,
  "startingPlayerId": "<uuid>" | null
}
```

---

## 8. Game State (JSON, Runtime Only)

Game state represents the **current, resumable state** of an active game. It is persisted as a JSON blob in `games.game_state_json` and is set to `NULL` once the game completes.

The persisted blob is a `GameStateSnapshot` (`lib/features/game/domain/models/game_state_snapshot.dart`) — a thin envelope around game-specific runtime state.

### GameStateSnapshot envelope

```json
{
  "gameId": "<uuid>",
  "gameType": "<gameType.name>",
  "stateData": { /* freezed GameState — see below */ },
  "timestamp": "2026-04-27T14:30:00.000Z",
  "isComplete": false,
  "winnerId": "<competitor_id>" | null
}
```

### `stateData` — runtime `GameState`

`stateData` is the JSON-serialised `GameState` (`lib/features/game/domain/models/game_state.dart`), which is the single source of truth for what the engine and presentation layer need to resume an active game. The exact field set evolves with the engines; the canonical reference is the freezed class. Stable top-level fields include:

* `gameId`, `gameType` — identifiers.
* `competitors` — array of `CompetitorState` (per-competitor score, dart history, marks, leg progress, practice counters, etc.).
* `currentTurnIndex`, `dartsThrownInTurn`, `turnActive`, `status` — turn cursor and engine status.
* `isComplete`, `winnerCompetitorId` — terminal state.
* `legsToWin`, `currentLegIndex`, `currentRoundInLeg` — leg/round bookkeeping.
* `x01TotalRounds`, `cricketTotalRounds` — per-leg round caps when applicable.
* `inStrategy`, `outStrategy`, `startingScore` — X01 configuration carried into runtime state.
* `cricketScoring`, `cricketTargetMode`, `cricketTargets`, `cricketLockedTargets`, `aroundTheClockVariant`, `shanghaiTotalRounds`, `catch40TargetRemaining`, `catch40DartsOnTarget`, `checkoutTargetSuccesses` — game-type-specific runtime fields. `cricketTargets` carries the 6 active number-slots (Bull implicit); `cricketLockedTargets` is the globally-locked set for Crazy Cricket (empty under `fixed`/`random`).

### Rules

* Only present for active games.
* `game_state_json` is set to `NULL` when the game completes; it is not retained afterwards.
* Never used as a source for historical statistics — those are projections over `game_events`.
* Treated as an opaque blob by the database; serialisation/validation is an application-layer concern.

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

* Sets (legs are first-class — see X01/Cricket configs in §7 and `LegCompleted` events)
* Uneven teams
* Mid-game roster changes
* Post-game edits
* Automatic data deletion
* Encryption or anonymization
* **Remote Multiplayer Data Modeling:** While remote multiplayer is a planned feature, its specific data modeling and synchronization mechanisms are detailed in the backend integration documentation (`docs/BACKEND_INTEGRATION.md`) and are out of scope for this core data specification.
