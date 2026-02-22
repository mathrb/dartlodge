# Development Progress Tracking - Gemini CLI Edition

This document tracks the current implementation status of the Darts scoring application. It is based on the specifications in `AGENTS.md`, the `docs/` directory, and the current state of the codebase.

## Overall Status: **Infrastructure Solid, UI/Features In-Progress**

The project has established a strong Clean Architecture foundation with repository interfaces, entity models, and initial database migrations. Core X01 game logic exists but is not yet fully exposed through the UI.

---

## 1. Core Persistence & Infrastructure

### ✅ Done
- **Repository Exceptions**: Complete hierarchy in `lib/core/error/repository_exception.dart`.
- **Database Helper/Migrations**: SQLite initialization with PRAGMA foreign keys and Version 1 & 2 schema in `lib/core/persistence/`.
- **Constants**: Database table and field names centralized in `lib/core/utils/constants.dart`.
- **Riverpod Providers**: Base repository providers established in `lib/core/persistence/database_provider.dart`.

### ❌ Missing
- **Web Support**: `drift` implementation for IndexedDB (required for web target).
- **Reactive Streams**: Repositories currently use `Stream.fromFuture` for `watch*` methods; needs actual reactive triggers.

### ⚠️ Refinement Needed
- **Conditional Imports**: Need to handle platform-specific database implementations (sqflite vs drift).
- **Error Propagation**: Ensure all database errors are correctly mapped to `RepositoryException` subclasses.

---

## 2. Players Feature

### ✅ Done
- **Domain Entities**: `Player` entity with `freezed` and `json_serializable`.
- **Repository Contract**: `PlayerRepository` interface and shared contract tests.
- **SQLite Implementation**: `PlayerRepositoryImpl` with basic CRUD operations.
- **Basic UI**: `players_screen.dart` scaffold.

### ❌ Missing
- **Use Cases**: No dedicated `CreatePlayerUseCase` or `UpdatePlayerUseCase`.
- **UI Implementation**: Missing the actual player creation/editing forms and selection logic for game setup.
- **Reactivity**: `watchAllPlayers` is not yet reactive to database changes.

---

## 3. Game Feature

### ✅ Done
- **Domain Entities**: `Game`, `Competitor`, `DartThrow`, `GameEvent` all implemented with `freezed`.
- **Domain Models**: `GameState`, `GameConfig`, `GameStateSnapshot` implemented.
- **Game Engine**: `StatelessX01Engine` with event-sourcing `apply` and `isValid` logic.
- **Repository Contracts**: `GameRepository`, `DartThrowRepository`, `GameEventRepository` interfaces and contract tests.
- **SQLite Implementation**: Full repository implementations for mobile.
- **Use Cases**: `CreateGameUseCase` and `ProcessDartUseCase` implemented.
- **Active Game Provider**: `ActiveGame` notifier scaffolded.

### ❌ Missing
- **UI/UX**: 
  - No Active Game Board (Scoreboard).
  - No Dart Input Grid (Single/Double/Triple input).
  - No Game Setup/Configuration UI.
  - No Game History/Replay UI.
- **Game Engines**: Cricket, Around the Clock, and Killer engines are missing.
- **State Reconstruction**: `ActiveGame` provider currently returns `null` instead of replaying events to reconstruct state.
- **Undo/Redo**: Logic to delete last dart and revert state via event log.

### ⚠️ Refinement Needed
- **X01 Logic**: Out-strategy validation is currently hardcoded or limited; needs to respect `config_json`.
- **Bust Conditions**: Need exhaustive verification against transition tables.

---

## 4. Statistics Feature

### ✅ Done
- **Domain Entities**: `PlayerStats` and `GameStats` models.
- **Repository Contract**: `StatisticsRepository` interface.

### ❌ Missing
- **Implementation**: `StatisticsRepositoryImpl` is a skeleton with `UnimplementedError` for all methods.
- **Projection Engine**: No logic to replay events and compute statistics as projections.
- **UI**: `statistics_screen.dart` is just a scaffold.

### ⚠️ Refinement Needed
- **Architecture Compliance**: Ensure statistics are NEVER stored, only projected from events.

---

## 5. Development Roadmap & Priorities

### Phase 1: Core Playability (Current Focus)
1. **Active Game UI**: Implement the scoreboard and dart input grid as per `docs/UI_SCREEN_FLOWS_V3_FINAL.md`.
2. **State Reconstruction**: Implement the event-replay logic in `ActiveGame` provider.
3. **Game Selection UI**: Connect the selection screen to `CreateGameUseCase`.
4. **X01 Refinement**: Ensure full compliance with `docs/games/x01.transitions.md`.

### Phase 2: Features & Polish
1. **Statistics Projections**: Implement the basic X01 projections (averages, checkout %).
2. **Player Management**: Complete the CRUD UI for players.
3. **Reactive Repositories**: Replace `Stream.fromFuture` with real SQLite change notifications.
4. **Undo/Redo**: Implement dart deletion and state rollback.

### Phase 3: Expansion
1. **Additional Game Types**: Implement Cricket and Around the Clock engines.
2. **Web Support**: Implement `drift` repositories.
3. **Backend Sync**: Implement the `sync_queue` and API client.

---

## 6. Testing Status

- **Unit Tests**: X01 Engine and ProcessDartUseCase are tested.
- **Contract Tests**: All repository interfaces have shared contract tests.
- **Widget Tests**: **MISSING** - No UI components are currently tested.
- **Integration Tests**: **MISSING**.

---

## Current Blockers / Risks
1. **UI Gap**: Significant development needed to make the app actually "playable".
2. **Stats Engine Complexity**: Replaying events for real-time stats without performance hits requires careful implementation of the projection engine.
3. **Web Divergence**: Maintaining identical behavior between `sqflite` (mobile) and `drift` (web) requires rigorous contract test enforcement.
