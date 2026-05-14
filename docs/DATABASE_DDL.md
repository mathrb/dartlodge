# Database DDL

**Status:** Authoritative
**Scope:** Core local SQLite schema (mobile) — the authoritative source for all CREATE TABLE statements
**Derived from:** [DATA.md](docs/DATA.md), [GAME-EVENT-SPECIFICATIONS.md](docs/GAME-EVENT-SPECIFICATIONS.md), [BACKEND_INTEGRATION.md](docs/BACKEND_INTEGRATION.md)

> **Web target note:** When running as a Flutter Web debug build, these statements are executed against a `drift`-managed SQLite WASM backend with automatic OPFS/IndexedDB fallback. The schema is identical; only the underlying storage engine differs. See [ARCHITECTURE.md](docs/ARCHITECTURE.md) — Decision #3.

---

## Versioning

| Version | Change |
|---------|--------|
| 1       | Complete schema — players, games, competitors, competitor_players, dart_throws, game_events, accounts, sync_queue, game_sessions |

All tables — including backend sync capabilities (`accounts`, `sync_queue`, `game_sessions`) — are created together in version 1. There are no incremental migrations. The `players` table includes `account_id` and `avatar_url` from the initial schema; `account_id = NULL` for local-only players preserves full offline functionality.

> **Inactive scaffolding (as of 2026-04-27):** The `accounts`, `sync_queue`, and `game_sessions` tables and the `players.account_id` / `players.avatar_url` columns are created in v1 but are **not yet wired into application code** — no repository, provider, use case, or UI reads or writes them. They exist so backend-integration work (see `BACKEND_INTEGRATION.md`) can land without a schema migration. Treat them as authoritative shapes for future use, not as descriptions of current behaviour. Sections describing these tables/columns are flagged with **"Inactive"** below.

---

## Enabling Foreign Keys

SQLite does not enforce foreign keys by default. This pragma **must** be executed on every database connection before any other statement:

```sql
PRAGMA foreign_keys = ON;
```

In `sqflite`, set this in `onOpen`:

```dart
await db.execute('PRAGMA foreign_keys = ON;');
```

---

## Version 1 — Complete Schema

### Creation order

`accounts` must be created before `players` because `players.account_id` references `accounts(account_id)`.

### accounts

> **Inactive — backend-integration scaffolding.** Not read or written by any current code path.

```sql
CREATE TABLE accounts (
    account_id     TEXT  NOT NULL PRIMARY KEY,  -- UUID, assigned by backend
    email          TEXT  NOT NULL UNIQUE,
    access_token   TEXT,                        -- Short-lived JWT, NULL when logged out
    refresh_token  TEXT,                        -- Long-lived refresh token
    backend_url    TEXT  NOT NULL,              -- Self-hosted backend base URL
    created_at     TEXT  NOT NULL,              -- ISO 8601
    last_login_at  TEXT                         -- ISO 8601, NULL if never logged in
);
```

**Notes:**
- `account_id = NULL` in the players table means the player is local-only. This preserves full offline functionality.
- A single account may be linked to multiple players (e.g. guest profiles sharing one backend account).

---

### players

```sql
CREATE TABLE players (
    player_id   TEXT  NOT NULL PRIMARY KEY,  -- UUID
    name        TEXT  NOT NULL,
    created_at  TEXT  NOT NULL,              -- ISO 8601
    last_active TEXT  NOT NULL,              -- ISO 8601
    account_id  TEXT  REFERENCES accounts(account_id) ON DELETE SET NULL,
    avatar_url  TEXT                         -- Remote URL or local path, NULL if not set
);
```

**Notes:**
- `account_id` and `avatar_url` are **inactive backend-integration scaffolding**. They exist on every row but are never read or written by current code: the `Player` domain entity (`lib/features/players/domain/entities/player.dart`) does not declare them, and both repository implementations ignore them.
- `account_id = NULL` for local-only players (i.e. all players today). `ON DELETE SET NULL` will allow unlinking an account without losing the player record once the feature ships.
- `avatar_url` is NULL when no avatar has been set; the current avatar widget renders a deterministic colour from `playerId` rather than reading this column.
- Players cannot be hard-deleted while they have rows in `competitor_players` (`ON DELETE RESTRICT` there protects historical data).

---

### games

```sql
CREATE TABLE games (
    game_id               TEXT     NOT NULL PRIMARY KEY,  -- UUID
    game_type             TEXT     NOT NULL,              -- camelCase Dart enum name (e.g. 'x01', 'cricket', 'aroundTheClock', 'catch40'). Authoritative list: GameType in lib/core/utils/constants.dart
    config_json           TEXT     NOT NULL,              -- JSON: game-type-specific configuration (see DATA.md §7)
    start_time            TEXT     NOT NULL,              -- ISO 8601
    end_time              TEXT,                           -- ISO 8601, NULL while game is active
    winner_competitor_id  TEXT,                           -- UUID, NULL until game is complete
    is_complete           INTEGER  NOT NULL DEFAULT 0,    -- 0 = active, 1 = complete (SQLite boolean)
    game_state_json       TEXT                            -- JSON: resumable runtime state (see DATA.md §8), NULL once complete
);

-- Unique partial index to enforce single active game constraint
CREATE UNIQUE INDEX idx_games_single_active
ON games(is_complete)
WHERE is_complete = 0;
```

**Notes:**
- `config_json` stores the full game configuration object. Schema varies by `game_type`; see `DATA.md §7` for each variant's JSON structure.
- `game_state_json` is only present for active games. It is set to `NULL` on completion. It is never used for statistics queries.
- `is_complete = 1` makes a game read-only. Application logic enforces this; no database trigger is used.
- `winner_competitor_id` is not a foreign key because the referenced `competitors` row is game-scoped and may be queried infrequently. Application logic ensures consistency.
- **Single active game constraint**: The `idx_games_single_active` unique partial index enforces that at most one game can have `is_complete = 0` at any time. This prevents "ghost game" scenarios where multiple incomplete games could accumulate.

---

### competitors

```sql
CREATE TABLE competitors (
    competitor_id  TEXT  NOT NULL PRIMARY KEY,  -- UUID, game-scoped
    game_id        TEXT  NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    type           TEXT  NOT NULL,              -- 'solo' | 'team'
    name           TEXT  NOT NULL
);

CREATE INDEX idx_competitors_game_id ON competitors(game_id);
```

---

### competitor_players

```sql
CREATE TABLE competitor_players (
    competitor_id      TEXT     NOT NULL REFERENCES competitors(competitor_id) ON DELETE CASCADE,
    player_id          TEXT     NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
    rotation_position  INTEGER  NOT NULL,       -- 0-based position within the competitor's turn rotation

    PRIMARY KEY (competitor_id, player_id)
);

CREATE INDEX idx_competitor_players_player_id ON competitor_players(player_id);
```

**Notes:**
- The `PRIMARY KEY (competitor_id, player_id)` composite key enforces that a player appears at most once per competitor.
- Application logic must additionally enforce that a `player_id` does not appear in more than one competitor within the same game (cross-competitor uniqueness per game). This is documented in `DATA.md §5` and checked at game creation time.
- For solo competitors, exactly one row exists with `rotation_position = 0`.

---

### dart_throws

```sql
CREATE TABLE dart_throws (
    dart_id        TEXT     NOT NULL PRIMARY KEY,  -- UUID
    game_id        TEXT     NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    competitor_id  TEXT     NOT NULL REFERENCES competitors(competitor_id) ON DELETE CASCADE,
    player_id      TEXT     NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
    turn_number    INTEGER  NOT NULL,              -- Incremented per competitor turn, 0-based
    dart_number    INTEGER  NOT NULL,              -- 1, 2, or 3 within a turn
    segment        TEXT     NOT NULL,              -- e.g. '20', 'T20', 'D16', 'SB', 'DB', 'MISS'
    score          INTEGER  NOT NULL,              -- Computed score value for this dart
    x              REAL,                           -- Normalized board coordinate, NULL if not captured
    y              REAL                            -- Normalized board coordinate, NULL if not captured
);

CREATE INDEX idx_dart_throws_game_id       ON dart_throws(game_id);
CREATE INDEX idx_dart_throws_player_id     ON dart_throws(player_id);
CREATE INDEX idx_dart_throws_competitor_id ON dart_throws(competitor_id);
CREATE INDEX idx_dart_throws_turn_order    ON dart_throws(game_id, turn_number, dart_number);
```

**Notes:**
- `dart_throws` is the primary source for all statistics computation. It is never updated after insertion.
- Dart ordering within a game is defined by `(turn_number, dart_number)` — not by `dart_id` or insertion order.
- `segment` uses the canonical string format: single = `'20'`, double = `'D20'`, triple = `'T20'`, single bull = `'SB'`, double bull = `'DB'`, miss = `'MISS'`.
- `score` is stored as a derived value at throw time to avoid recomputing it during statistics queries.

---

### game_events

Stores the append-only event log used for game state reconstruction, replay, and (optionally) multiplayer sync. See `GAME-EVENT-SPECIFICATIONS.md` for the full event catalogue.

```sql
CREATE TABLE game_events (
    event_id        TEXT     NOT NULL PRIMARY KEY,  -- UUID, globally unique
    game_id         TEXT     NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    event_type      TEXT     NOT NULL,              -- See GAME-EVENT-SPECIFICATIONS.md for the authoritative event catalogue
    local_sequence  INTEGER  NOT NULL,              -- Client-assigned monotonically increasing integer per game (1-based, restarts at 1 per game)
    occurred_at     TEXT     NOT NULL,              -- ISO 8601
    payload_json    TEXT     NOT NULL,              -- JSON: event-type-specific payload (see GAME-EVENT-SPECIFICATIONS.md §4)
    synced          INTEGER  NOT NULL DEFAULT 0,    -- 0 = local only, 1 = confirmed by backend
    actor_id        TEXT     NOT NULL,              -- UUID: player or system actor who caused the event
    global_sequence INTEGER,                        -- Server-assigned sequence (null until synced)
    source          INTEGER  NOT NULL DEFAULT 0,    -- 0=client, 1=server, 2=vision

    UNIQUE (game_id, local_sequence)
);

CREATE INDEX idx_game_events_game_id  ON game_events(game_id);
CREATE INDEX idx_game_events_sequence ON game_events(game_id, local_sequence);
```

**Notes:**
- Events are immutable once inserted. `DartCorrected` does not modify an existing row; it inserts a new event that references the original.
- `local_sequence` is assigned by the client and is unique per game. It is **1-based and restarts at 1 per game** — the first event of every game lands at `local_sequence = 1`. `GameEventRepository.getLatestSequence` returns `0` for a game with no events so callers can compute `getLatestSequence(...) + 1` uniformly. Because `local_sequence` restarts per game, any query that loads events across multiple games MUST sort by `(game_id, local_sequence)` — sorting by `local_sequence` alone interleaves games and corrupts replay/projection state. The backend assigns its own `global_sequence` on sync; this is stored in the `global_sequence` column.
- `synced = 0` rows are candidates for the backend sync queue (see `sync_queue` table).
- `actor_id` identifies the player or system actor who caused the event. For player actions, this is the player UUID. For system events, it's 'system'.
- `source` indicates the origin: 0=client app, 1=server, 2=computer vision system.
- Duplicate `event_id` values must be silently ignored on insert (idempotency), not rejected.

---

### sync_queue

> **Inactive — backend-integration scaffolding.** Not read or written by any current code path.

Manages pending outbound synchronization operations.

```sql
CREATE TABLE sync_queue (
    operation_id   TEXT     NOT NULL PRIMARY KEY,  -- UUID
    entity_type    TEXT     NOT NULL,              -- 'game' | 'player' | 'dart_throw' | 'game_event'
    entity_id      TEXT     NOT NULL,              -- UUID of the entity to sync
    operation_type TEXT     NOT NULL,              -- 'create' | 'update' | 'delete'
    payload_json   TEXT     NOT NULL,              -- Full serialized entity payload
    status         TEXT     NOT NULL DEFAULT 'pending',  -- 'pending' | 'processing' | 'completed' | 'failed'
    attempt_count  INTEGER  NOT NULL DEFAULT 0,
    created_at     TEXT     NOT NULL,              -- ISO 8601
    last_attempt   TEXT,                           -- ISO 8601, NULL if not yet attempted
    error_message  TEXT                            -- Last error detail, NULL if no error
);

CREATE INDEX idx_sync_queue_status ON sync_queue(status);
```

---

### game_sessions

> **Inactive — backend-integration scaffolding.** Not read or written by any current code path.

Tracks remote multiplayer sessions.

```sql
CREATE TABLE game_sessions (
    session_id      TEXT  NOT NULL PRIMARY KEY,  -- UUID, assigned by backend
    game_id         TEXT  NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    host_player_id  TEXT  NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
    status          TEXT  NOT NULL,              -- 'waiting' | 'in_progress' | 'completed' | 'abandoned'
    created_at      TEXT  NOT NULL,              -- ISO 8601
    started_at      TEXT,                        -- ISO 8601, NULL until session begins
    completed_at    TEXT,                        -- ISO 8601, NULL until session ends
    current_turn_player_id TEXT REFERENCES players(player_id) ON DELETE SET NULL
);

CREATE INDEX idx_game_sessions_game_id ON game_sessions(game_id);
```

---

## Full Migration Script

```sql
-- ============================================================
-- Version 1 — Complete Schema
-- ============================================================

PRAGMA foreign_keys = ON;

-- accounts must be created first: players.account_id references it
CREATE TABLE accounts (
    account_id     TEXT  NOT NULL PRIMARY KEY,
    email          TEXT  NOT NULL UNIQUE,
    access_token   TEXT,
    refresh_token  TEXT,
    backend_url    TEXT  NOT NULL,
    created_at     TEXT  NOT NULL,
    last_login_at  TEXT
);

CREATE TABLE players (
    player_id   TEXT  NOT NULL PRIMARY KEY,
    name        TEXT  NOT NULL,
    created_at  TEXT  NOT NULL,
    last_active TEXT  NOT NULL,
    account_id  TEXT  REFERENCES accounts(account_id) ON DELETE SET NULL,
    avatar_url  TEXT
);

CREATE TABLE games (
    game_id               TEXT     NOT NULL PRIMARY KEY,
    game_type             TEXT     NOT NULL,
    config_json           TEXT     NOT NULL,
    start_time            TEXT     NOT NULL,
    end_time              TEXT,
    winner_competitor_id  TEXT,
    is_complete           INTEGER  NOT NULL DEFAULT 0,
    game_state_json       TEXT
);

CREATE UNIQUE INDEX idx_games_single_active
ON games(is_complete)
WHERE is_complete = 0;

CREATE TABLE competitors (
    competitor_id  TEXT  NOT NULL PRIMARY KEY,
    game_id        TEXT  NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    type           TEXT  NOT NULL,
    name           TEXT  NOT NULL
);

CREATE INDEX idx_competitors_game_id ON competitors(game_id);

CREATE TABLE competitor_players (
    competitor_id     TEXT     NOT NULL REFERENCES competitors(competitor_id) ON DELETE CASCADE,
    player_id         TEXT     NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
    rotation_position INTEGER  NOT NULL,
    PRIMARY KEY (competitor_id, player_id)
);

CREATE INDEX idx_competitor_players_player_id ON competitor_players(player_id);

CREATE TABLE dart_throws (
    dart_id        TEXT     NOT NULL PRIMARY KEY,
    game_id        TEXT     NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    competitor_id  TEXT     NOT NULL REFERENCES competitors(competitor_id) ON DELETE CASCADE,
    player_id      TEXT     NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
    turn_number    INTEGER  NOT NULL,
    dart_number    INTEGER  NOT NULL,
    segment        TEXT     NOT NULL,
    score          INTEGER  NOT NULL,
    x              REAL,
    y              REAL
);

CREATE INDEX idx_dart_throws_game_id       ON dart_throws(game_id);
CREATE INDEX idx_dart_throws_player_id     ON dart_throws(player_id);
CREATE INDEX idx_dart_throws_competitor_id ON dart_throws(competitor_id);
CREATE INDEX idx_dart_throws_turn_order    ON dart_throws(game_id, turn_number, dart_number);

CREATE TABLE game_events (
    event_id        TEXT     NOT NULL PRIMARY KEY,
    game_id         TEXT     NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    event_type      TEXT     NOT NULL,
    local_sequence  INTEGER  NOT NULL,
    occurred_at     TEXT     NOT NULL,
    payload_json    TEXT     NOT NULL,
    synced          INTEGER  NOT NULL DEFAULT 0,
    actor_id        TEXT     NOT NULL,
    global_sequence INTEGER,
    source          INTEGER  NOT NULL DEFAULT 0,
    UNIQUE (game_id, local_sequence)
);

CREATE INDEX idx_game_events_game_id  ON game_events(game_id);
CREATE INDEX idx_game_events_sequence ON game_events(game_id, local_sequence);

CREATE TABLE sync_queue (
    operation_id   TEXT     NOT NULL PRIMARY KEY,
    entity_type    TEXT     NOT NULL,
    entity_id      TEXT     NOT NULL,
    operation_type TEXT     NOT NULL,
    payload_json   TEXT     NOT NULL,
    status         TEXT     NOT NULL DEFAULT 'pending',
    attempt_count  INTEGER  NOT NULL DEFAULT 0,
    created_at     TEXT     NOT NULL,
    last_attempt   TEXT,
    error_message  TEXT
);

CREATE INDEX idx_sync_queue_status ON sync_queue(status);

CREATE TABLE game_sessions (
    session_id             TEXT  NOT NULL PRIMARY KEY,
    game_id                TEXT  NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    host_player_id         TEXT  NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
    status                 TEXT  NOT NULL,
    created_at             TEXT  NOT NULL,
    started_at             TEXT,
    completed_at           TEXT,
    current_turn_player_id TEXT  REFERENCES players(player_id) ON DELETE SET NULL
);

CREATE INDEX idx_game_sessions_game_id ON game_sessions(game_id);
```

---

## Design Decisions

**UUIDs stored as TEXT.** SQLite has no native UUID type. All UUIDs are stored as TEXT in standard hyphenated format (`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`). This avoids any byte-order ambiguity and makes rows readable during debugging.

**Timestamps stored as TEXT.** ISO 8601 strings (`2024-01-15T14:30:00.000Z`) sort lexicographically and are timezone-unambiguous. SQLite date functions work correctly with this format.

**Booleans stored as INTEGER.** SQLite has no boolean type. `0 = false`, `1 = true` throughout. Dart code maps these via `== 1` checks.

**JSON stored as TEXT.** `config_json`, `game_state_json`, and `payload_json` are opaque blobs from SQLite's perspective. Application code is responsible for serialization and validation. This is intentional — the schema does not couple to game-type-specific structure.

**`ON DELETE CASCADE` on game-owned tables.** Deleting a game row (if ever needed for cleanup) removes its competitors, competitor_players, dart_throws, and game_events automatically.

**`ON DELETE RESTRICT` on players.** Players cannot be deleted while they have recorded dart throws or are members of competitors. This protects historical statistics.

**Single version schema.** All tables including backend sync capabilities are created in version 1. This simplifies the initial setup and ensures all functionality is available from the start, while maintaining full offline capability through nullable foreign keys (e.g., `account_id = NULL` for local-only players).

**`accounts` created before `players`.** Because `players.account_id` references `accounts(account_id)`, `accounts` must be created first in `onCreate`. This is the only ordering constraint in the schema.

**No triggers.** Immutability of completed games and cross-game player uniqueness per competitor are enforced by application logic only, not database triggers. This keeps the schema portable and testable.
