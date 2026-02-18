# AGENTS.md

This file guides any AI coding agent working on this repository. Read it fully before writing, editing, or deleting any code. It is the authoritative behavioural contract for this project.

---

## Project Overview

A local-first, open-source darts scoring app for Android and iOS built with Flutter. Players can track statistics, play multiple game types manually, or optionally connect a self-hosted backend for computer-vision auto-scoring.

**Flutter Web is the development/debug target.** Physical devices are not required during development. Run `flutter run -d chrome` or build and serve with `python3 -m http.server`. All game logic and UI behaves identically to mobile; only native-only features (camera, SQLite) differ — they are stubbed on web.

---

## Repository Layout

```
AGENTS.md                          ← you are here
README.md
darts-game/                        ← plain-English game rules for each variant
docs/
  API_CONTRACT.md                  ← REST API spec (Phase 1 MVP)
  ARCHITECTURE.md                  ← layered architecture overview
  ARCHITECTURE_COMPLETE.md         ← final production architecture (authoritative)
  BACKEND_INTEGRATION.md           ← optional backend + multiplayer
  DATA.md                          ← data model spec (fields, types, rules)
  DATABASE_DDL.md                  ← authoritative CREATE TABLE statements
  GAME-EVENT-SPECIFICATIONS.md     ← canonical event catalogue
  REPOSITORY_INTERFACES.md         ← Dart interface contracts for all 5 repos
  STATE_MANAGEMENT.md              ← Riverpod patterns, providers, anti-patterns
  UI_SCREEN_FLOWS_V3_FINAL.md      ← screen layouts, components, navigation
  games/
    around-the-clock.md            ← state transition tables
    cricket.transitions.md         ← state transition tables
    x01.transitions.md             ← state transition tables
  statistics/
    projection-test-matrix.md      ← test contract for all projections
    statistics.architecture.md     ← projection engine design
    x01.projections.md             ← X01-specific statistics definitions
lib/
  main.dart
  app/
    app.dart
    app_router.dart
  core/
    error/repository_exception.dart
    persistence/                   ← database_provider.dart goes here
    utils/constants.dart
    widgets/
  features/
    game/
      domain/entities/             ← game.dart, competitor.dart, dart_throw.dart, game_event.dart
      domain/repositories/        ← game_repository.dart, dart_throw_repository.dart, game_event_repository.dart
      data/repositories/          ← concrete implementations (sqflite / drift)
      presentation/
    players/
      domain/entities/player.dart
      domain/repositories/player_repository.dart
      data/repositories/
      presentation/
    statistics/
      domain/entities/             ← player_stats.dart, game_stats.dart
      domain/repositories/statistics_repository.dart
      data/repositories/
      presentation/
pubspec.yaml
```

---

## Authoritative Specification Documents

Before implementing anything, check the relevant spec. These documents are the source of truth — never infer behaviour from code that does not yet exist.

| What you are building | Read this first |
|---|---|
| Database schema, table columns, indexes | `docs/DATABASE_DDL.md` |
| Repository method signatures and exceptions | `docs/REPOSITORY_INTERFACES.md` |
| Game event types and payloads | `docs/GAME-EVENT-SPECIFICATIONS.md` |
| X01 scoring rules and transitions | `docs/games/x01.transitions.md` |
| Cricket scoring rules and transitions | `docs/games/cricket.transitions.md` |
| Around the Clock transitions | `docs/games/around-the-clock.md` |
| Statistics definitions and formulas | `docs/statistics/x01.projections.md`, `docs/statistics/statistics.architecture.md` |
| Riverpod providers, state classes, patterns | `docs/STATE_MANAGEMENT.md` |
| Screen layouts, navigation, UI components | `docs/UI_SCREEN_FLOWS_V3_FINAL.md` |
| Data entities, JSON configs, field names | `docs/DATA.md` |
| Backend REST endpoints (optional feature) | `docs/API_CONTRACT.md` |

Game rules in `darts-game/` are plain-English descriptions. The formal transition tables in `docs/games/` are the authoritative source for engine implementation.

---

## Architecture: What You Must Never Violate

These are hard constraints. Breaking them requires explicit human approval.

### 1. Feature-First Clean Architecture

```
lib/features/<feature>/
  domain/       ← pure Dart only — NO Flutter, NO sqflite, NO http
  data/         ← implements domain interfaces; contains sqflite/drift code
  presentation/ ← Flutter widgets and Riverpod providers
```

- Domain layers must have zero imports of `package:flutter`, `package:sqflite`, `package:drift`, or `package:dio`.
- No feature may import another feature directly. Cross-feature communication goes through `core/` providers or shared domain entities only.
- `core/` contains no domain logic — only infrastructure (database wiring, error types, shared utilities).

### 2. Dependency Direction

```
UI (widgets/pages)
  → Riverpod Notifiers
    → Use Cases (domain)
      → Repository Interfaces (domain)
        ← Repository Implementations (data)
```

Never shortcut this chain. No widget reads a repository directly.

### 3. Games Are Event Streams

Every change to game state must be expressed as a `GameEvent` and appended to `game_events` before any derived state is mutated. See `docs/GAME-EVENT-SPECIFICATIONS.md`.

> **If it changes the game, it must be an event. No exceptions.**

### 4. Statistics Are Projections — Never Stored

Statistics are computed by replaying `game_events`. Never write code that stores a computed average, checkout percentage, or win rate in the database. `StatisticsRepository` is a query facade over raw `dart_throws` and `game_events` — it owns no table.

### 5. Immutable State

All state classes use `freezed`. Never mutate state in place. Always use `copyWith`.

---

## Technology Decisions (Do Not Re-litigate)

| Concern | Decision |
|---|---|
| State management | Riverpod with code generation (`@riverpod`, `riverpod_generator`) |
| Immutable state | `freezed` |
| Mobile storage | `sqflite` + `path_provider` |
| Web storage | `drift` with IndexedDB (web debug target only) |
| HTTP client (backend, optional) | `dio` |
| Secure token storage | `flutter_secure_storage` |
| Code generation runner | `build_runner` |
| UUID generation | `uuid` package |

Platform selection (sqflite vs drift) happens once at `lib/core/persistence/database_provider.dart`. Everywhere else sees only the repository interface.

---

## Folder and File Conventions

### Adding a new use case

```
lib/features/<feature>/domain/usecases/<name>_use_case.dart
```

Use cases take repository interfaces as constructor parameters. They contain business logic. They do not touch Flutter or sqflite.

### Adding a Riverpod provider

```
lib/features/<feature>/presentation/providers/<name>_provider.dart
```

Use `@riverpod` annotation. All providers with I/O use `AsyncNotifierProvider`. Repository providers are `keepAlive: true` and live in `lib/core/persistence/database_provider.dart`.

### Adding a state class

```
lib/features/<feature>/presentation/state/<name>_state.dart
```

Always `@freezed`. Always includes a `factory <ClassName>.initial()` constructor.

### Adding a new screen

```
lib/features/<feature>/presentation/pages/<name>_page.dart    ← full screens
lib/features/<feature>/presentation/widgets/<name>_widget.dart ← components
```

Screens are `ConsumerWidget` or `ConsumerStatefulWidget`. Pure UI widgets with no providers are `StatelessWidget`.

### Adding a repository implementation

```
lib/features/<feature>/data/repositories/<name>_repository_impl.dart
```

Must implement the interface in `domain/repositories/`. Must pass the shared contract test suite in `test/contracts/`.

---

## Database Rules

The schema is defined in `docs/DATABASE_DDL.md`. Do not invent columns or tables. If a new column is needed, add a new schema version and update the DDL doc.

**Critical rules:**

- `PRAGMA foreign_keys = ON` must be set in `onOpen` on every connection. Without this, SQLite silently ignores all foreign key constraints.
- All UUIDs are stored as `TEXT` in `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` format.
- All timestamps are stored as `TEXT` in ISO 8601 format (`2024-01-15T14:30:00.000Z`).
- Booleans are `INTEGER`: `0 = false`, `1 = true`. Map them with `== 1` in Dart.
- `config_json`, `game_state_json`, and `payload_json` are opaque `TEXT` blobs — do not parse or validate them inside SQL queries.
- `ON DELETE CASCADE` applies to game-owned rows (competitors, dart_throws, game_events). `ON DELETE RESTRICT` applies to players — never silently delete historical data.
- Completed games are read-only. Enforce this in application logic before any write, not via triggers.
- Schema migrations are applied incrementally in `onUpgrade`. Version 1 is the core schema. Version 2 is optional backend tables, applied only when a backend is configured.

---

## Repository Interface Rules

All five interfaces are defined in `docs/REPOSITORY_INTERFACES.md`. Method signatures, parameter names, return types, and exception types are fixed.

**Exception hierarchy:** All repository exceptions extend `RepositoryException` (defined in `lib/core/error/repository_exception.dart`). Never throw raw `Exception` or `Error` from repository implementations.

**Contract tests:** Every concrete implementation (sqflite and drift variants) must pass the shared contract test functions in `test/contracts/`. Do not skip or comment out tests to make CI pass.

**Idempotency:** `GameEventRepository.appendEvent()` silently ignores duplicate `event_id` values. `DartThrowRepository.insertDart()` throws `DuplicateDartException` on duplicate `dart_id`. These behaviours are not symmetrical by design.

---

## State Management Rules

Follow `docs/STATE_MANAGEMENT.md` exactly. Key rules repeated here:

- Use `AsyncValue.guard()` for all async operations in notifiers. Never catch exceptions manually around database or network calls inside a guard block.
- Use `ref.watch()` inside `build()` methods. Use `ref.read()` only in event handlers and notifier methods.
- All repository providers are `keepAlive: true`. Game and UI providers are auto-dispose by default.
- Handle all three `AsyncValue` states in every widget that watches an async provider: `data`, `loading`, `error`. Never call `.value!` or `.requireValue` in user-facing UI without a loading/error fallback.
- Never put business logic in widgets. Widgets call notifier methods; notifiers call use cases; use cases call repositories.

---

## Game Engine Rules

Each game type has a pure engine class implementing:

```dart
abstract class GameEngine {
  GameState apply(GameState state, GameEvent event);
  bool isValid(GameState state, GameEvent event);
}
```

Engines have no persistence, no serialization, no side effects. They are pure functions over state and events and are fully testable without a database or Flutter runtime.

Implement transition logic strictly from the state transition tables in `docs/games/`. Every ambiguity in those tables has an explicit resolution section — read it. If a case is not covered, raise it before implementing; do not guess.

**Critical X01 rules (from `docs/games/x01.transitions.md`):**
- Bust always immediately ends the turn. It never waits for the third dart.
- Bull (50) counts as a double for both in-strategy and out-strategy validation.
- A failed In dart (when in-strategy not yet satisfied) still consumes a dart — it does not score but it is thrown.
- Out validation occurs before the dart count increment is considered terminal.
- Score may never go below zero; a dart that would take score negative is a bust.

**Critical Cricket rules (from `docs/games/cricket.transitions.md`):**
- Inner bull (50) counts as 2 hits. Outer bull (25) counts as 1 hit. Scoring value for overflow is always 25 per mark regardless.
- Numbers 1–14 and non-bull 21–24 count as thrown but have no game effect — they are ignored, not rejected.
- In cut-throat, surplus marks score against opponents who have not yet closed the number.
- A player wins only when all numbers are closed AND that player has the lowest score (standard) or highest score (cut-throat).

---

## Statistics Rules

Follow `docs/statistics/statistics.architecture.md` and `docs/statistics/projection-test-matrix.md`.

- Statistics are projections over the event log. They are recomputed from events, never stored as pre-calculated values.
- Every projection belongs to exactly one scope: Dart, Turn, Leg, Match, or Career. Scope resets are triggered only by canonical events: Turn resets on `TurnStarted`, Leg resets on `LegCompleted`, Match resets on `GameCompleted`.
- `DartCorrected` events require full replay of all projections from the correction point forward. No delta patching is allowed.
- Ratio projections (averages, percentages) are always derived from stored counters or accumulators. They are never stored independently.
- Every new projection must declare: which game types it applies to, which events it consumes, and its scope. This follows the `ProjectionDescriptor` model in the statistics architecture doc.
- Every projection must pass all applicable categories (A–H) from `docs/statistics/projection-test-matrix.md`.

**Forbidden:**
- Storing averages or ratios in any database table
- Updating stats inside the game engine
- Building statistics from UI state or provider state
- Resetting projection scope at arbitrary points outside the defined triggers

---

## Development Priority Order

Build in this sequence. Do not skip ahead.

1. `pubspec.yaml` — add and pin all dependencies listed in the Technology Decisions table
2. `lib/core/error/repository_exception.dart` — complete the exception hierarchy (sealed class, all subclasses)
3. `lib/core/persistence/database_provider.dart` — database init, `PRAGMA foreign_keys = ON` in `onOpen`, schema v1 DDL in `onCreate`, incremental migration in `onUpgrade`
4. `lib/features/players/` — entity, interface (scaffold exists), sqflite implementation, contract tests, basic list screen
5. `lib/features/game/` — entities (scaffolds exist), interfaces (scaffolds exist), sqflite implementations, X01 engine with full transition tables, contract tests
6. `lib/features/statistics/` — entities (scaffolds exist), interface (scaffold exists), projection engine, X01 projections
7. UI screens — game selection, active X01 game board, statistics dashboard
8. Additional game types — Cricket, Around the Clock (engines only; UI reuses the same board structure)
9. `lib/features/auth/` and backend sync — only when a backend is actually being wired up. Do not build this before the core game loop is complete.

---

## Running the Project

```bash
# Install dependencies
flutter pub get

# Generate code after any @freezed or @riverpod change
dart run build_runner build --delete-conflicting-outputs

# Run on web (primary development target)
flutter run -d chrome

# Headless alternative — build and serve
flutter build web
cd build/web && python3 -m http.server 8080

# Run all tests
flutter test

# Run a specific test file
flutter test test/features/players/data/player_repository_impl_test.dart
```

Always regenerate after any change to a `@freezed` class or `@riverpod` provider before running or testing.

---

## Testing Requirements

- Every repository implementation has a contract test file that calls the shared suite function from `test/contracts/`. Both sqflite and drift implementations must pass the same suite.
- Every game engine has unit tests covering all transition table rows, all bust conditions, all win conditions, and every case in the "Explicitly Resolved Ambiguities" sections of the transition docs.
- Every statistics projection has unit tests covering categories A–H from `docs/statistics/projection-test-matrix.md`. Game-specific projections additionally cover GS1–GS3.
- Use `ProviderContainer` with `overrides` for unit-testing notifiers. Never instantiate notifiers directly.
- Use `ProviderScope` with `overrides` for widget tests.

---

## Segment Format Convention

Dart segments use a canonical string format throughout the entire codebase. Never deviate.

| Hit | String |
|---|---|
| Single 20 | `'20'` |
| Double 20 | `'D20'` |
| Triple 20 | `'T20'` |
| Single bull | `'SB'` |
| Double bull | `'DB'` |
| Miss | `'MISS'` |

This format is used in `dart_throws.segment`, in `DartThrown` event payloads, and in all engine logic. Do not use numeric codes, embedded multiplier prefixes, or any other format.

---

## When Uncertain

1. **Check the spec docs first.** Most questions are answered in `docs/`. Do not guess behaviour.
2. **Check the game rules.** Plain-English in `darts-game/`. Formal transitions in `docs/games/`.
3. **Do not invent architecture.** If a pattern is not described in `docs/STATE_MANAGEMENT.md` or `docs/ARCHITECTURE_COMPLETE.md`, raise it before implementing.
4. **Do not add packages** without first checking whether the existing stack already covers the need.
5. **Do not change interface signatures** in `docs/REPOSITORY_INTERFACES.md` unilaterally. These are shared contracts across multiple layers and implementations.
6. **Raise ambiguities explicitly.** If the transition tables do not cover a case, say so. Do not pick a behaviour silently.

---

## Things You Must Not Do

- Store statistics (averages, ratios, percentages) as pre-calculated values in the database
- Import `sqflite`, `drift`, `flutter`, or `dio` in any `domain/` layer file
- Import one feature's code from another feature's folder
- Call `ref.read()` inside a widget's `build()` method
- Catch exceptions inside `AsyncValue.guard()` — let it propagate to the `error` state
- Use `!` (null-bang) on `AsyncValue.value` in user-facing UI without loading and error handling
- Mutate `GameState` in place — always `copyWith`
- Skip or comment out contract tests to make CI pass
- Build the `auth/` feature before the core game loop (players → game → statistics) is working end-to-end
- Add database triggers — immutability of completed games is enforced by application logic only
- Use timestamps for conflict resolution in the event log — only `local_sequence` and `global_sequence` ordering matters
