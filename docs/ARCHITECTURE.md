# Darts App Architecture

This document provides a detailed architectural overview aligned with the existing README.md specification.

## Global Architecture Overview

The Darts App follows a layered architecture with clear separation of concerns. The Flutter UI layer handles user interaction, the business logic layer processes game rules and statistics, the data layer manages local persistence via SQLite (through `drift` on every platform), and an optional backend layer provides advanced features like auto-scoring and synchronization.

> See [`ARCHITECTURE_COMPLETE.md`](ARCHITECTURE_COMPLETE.md) for the canonical, in-depth architecture reference. This document is an overview.

## Layered Architecture

### 1. Presentation Layer (Flutter UI)
- **Platform**: Android and iOS (production targets); Web (development/debug target)
- **Responsibility**: User interface and interaction
- **Key Components**:
  - Game selection screens
  - Game play interfaces
  - Statistics dashboards
  - Game history views
  - Settings and configuration

### 2. Business Logic Layer (Flutter)
- **Responsibility**: Core application logic and game processing
- **Key Components**:
  - Game Engine (X01, Cricket, etc.)
  - Statistics Engine
  - Data Management
  - Backend Sync Manager (optional)
  - Game State Management

### 3. Data Layer (drift / SQLite)
- **Responsibility**: Local data persistence
- **Implementation**: [`drift`](https://pub.dev/packages/drift) on every platform. Mobile/desktop uses `NativeDatabase.createInBackground`; web uses the synchronous `WasmDatabase` constructor — `sqlite3.wasm` loaded on the main thread, persistence via `IndexedDbFileSystem`. The `WasmDatabase.open()` worker-based approach is explicitly avoided because it hangs in Firefox / Edge during development (see comment in `lib/core/persistence/drift/database_factory_web.dart`). Platform selection happens once in the drift factory (`lib/core/persistence/drift/database_factory_{native,web}.dart`); everywhere else only sees the repository interfaces. See [`DATABASE_DDL.md`](DATABASE_DDL.md) for the canonical schema.
- **Key Components**:
  - Drift table classes (`lib/core/persistence/drift/database.dart`) — single source of truth for schema
  - Generated Data Access Objects via `drift_dev` / `build_runner`
  - Type-safe query builders (drift's Dart DSL plus raw SQL where needed)
  - Foreign keys enforced at runtime (`PRAGMA foreign_keys = ON` in `MigrationStrategy.beforeOpen`)
  - Backup/restore functionality

### 4. Optional Backend Layer
- **Responsibility**: Auto-scoring and sync (self-hosted)
- **Implementation**: REST API with computer vision
- **Options**: Python (Flask) or Rust
- **Key Components**:
  - REST API endpoints
  - Computer vision processing
  - Model inference (PyTorch/ONNX)
  - Data synchronization

## Flutter-Specific Architecture

### Key Flutter Components

#### Game Engine

The Game Engine follows an abstract base class pattern with concrete implementations for each game type (X01, Cricket, etc.). Each game implementation handles its specific rules, scoring logic, and win conditions while providing a consistent interface for the application to interact with games uniformly.

Key responsibilities:
- Process dart throws according to game-specific rules
- Manage game state and player turns
- Validate game-specific conditions (busts, checkouts, etc.)
- Determine winners based on game completion criteria
- Provide serialization/deserialization for game state persistence

#### Statistics Engine

The Statistics Engine is responsible for computing various metrics and analytics from raw game data. It follows a compute-on-demand pattern rather than storing pre-calculated statistics, ensuring data consistency and flexibility.

Key responsibilities:
- Calculate player statistics (averages, high scores, win rates, etc.)

## Database Schema

For the complete database schema and detailed table structures, refer to the [Data Structure](docs/DATA.md) documentation. This provides the authoritative source for all data models and relationships.

### Key Tables Overview

The database follows a relational design with these core entities:
- **Players**: Stores player information with UUID identification
- **Games**: Tracks game sessions with configuration and state
- **Competitors**: Represents competing entities (solo players or teams) within a game
- **Competitor Players**: Links players to specific competitors, defining team composition

### Design Principles
- **Relational Integrity**: Proper foreign key relationships between tables
- **Data Normalization**: Minimal redundancy with proper table relationships
- **Performance**: Indexes on frequently queried columns
- **Extensibility**: Support for additional game types and features

## Data Access Layer

### Database Helper

The Database Helper provides a singleton interface for all database operations, handling all CRUD operations and ensuring proper database initialization. It follows the repository pattern to abstract database operations from the business logic layer. The same `drift` engine is used on every platform; only the underlying `QueryExecutor` differs (`NativeDatabase.createInBackground` on mobile/desktop, `WasmDatabase` over IndexedDB on web), wired in the drift factory.

Key responsibilities:
- Database initialization and schema management
- Singleton access pattern for database connections
- CRUD operations for all data entities
- Transaction management and error handling
- Data model mapping between Dart objects and database records

The domain layer defines repository interfaces that are platform-agnostic. Concrete implementations are wired at the dependency injection root, ensuring all game logic and statistics code remains identical across platforms regardless of the underlying storage engine.

## Backend Integration (Optional)

For detailed information about backend integration, including multiplayer functionality and authentication systems, refer to the [Backend Integration](docs/BACKEND_INTEGRATION.md) documentation.

### Backend Service

The Backend Service provides optional integration with self-hosted backend servers for advanced features. It handles communication with REST APIs and manages data synchronization between local storage and remote servers.

Key responsibilities:
- REST API communication for data synchronization
- Image upload for computer vision auto-scoring
- Error handling and retry logic
- Network connectivity management

## State Management

### Game State Management

The Game State Management system follows the Provider pattern with ChangeNotifier to manage application state reactively. It maintains the current game state, handles game lifecycle events, and provides a consistent interface for UI components.

**Key Responsibilities**:
- Current game state management and persistence
- Game lifecycle operations (creation, loading, completion)
- Dart processing and turn management
- Game state serialization and deserialization
- Database integration for state persistence
- Statistics updates on game completion
- Reactive state notifications for UI updates

The state management system ensures consistent game state across the application and provides a single source of truth for all game-related data.

## Key Architectural Decisions

### 1. Local-First with Optional Backend
- **Rationale**: Offline capability is essential for darts apps
- **Implementation**: SQLite (via `drift`) for local storage, optional REST API sync
- **Benefits**: Works without internet, user privacy, no server costs

### 2. Flutter for Cross-Platform
- **Rationale**: Single codebase for Android and iOS, with web support for development iteration
- **Implementation**: Flutter widgets with platform-specific adaptations; Flutter Web used as a debug target in headless environments
- **Benefits**: Faster development, consistent UI, hot reload, no physical device required during early development

### 3. Repository Abstraction with a Single Drift Engine
- **Rationale**: Flutter targets web in addition to mobile/desktop; the data layer must abstract over different `QueryExecutor` implementations while keeping a single schema and a single ORM
- **Implementation**: Repository interfaces defined in the domain layer; a single `drift` schema (see `lib/core/persistence/drift/database.dart`) used by all platforms. Conditional `QueryExecutor` wiring lives in the drift factory: `NativeDatabase.createInBackground` for mobile/desktop, `WasmDatabase` over IndexedDB for web. Repository implementations and business logic are platform-agnostic.
- **Benefits**: Game logic and UI remain identical across platforms; one schema, one set of migrations, one set of repository implementations; storage executor is swappable without touching business logic
- **Web limitations**: The web build is a development/debug target only. Features requiring native APIs (camera for computer vision, native file system) are not available on web and should be stubbed or disabled when running in a browser

### 4. SQLite (via drift) for Data Storage
- **Rationale**: Relational data and complex queries for statistics; a single ORM-backed schema across mobile, desktop, and web
- **Implementation**: `drift` package with the schema in `lib/core/persistence/drift/database.dart`. Build artefacts come from `build_runner` (`dart run build_runner build --delete-conflicting-outputs`)
- **Benefits**: Type-safe queries, watchable streams via `select(...).watch()`, identical behaviour across platforms, long-term maintainability

### 5. Game Engine Pattern
- **Rationale**: Separate game logic from UI
- **Implementation**: Abstract Game class with concrete implementations
- **Benefits**: Easy to add new game types, consistent rules

### 6. Statistics Computation
- **Rationale**: Compute from raw data, not pre-calculated
- **Implementation**: StatisticsEngine with various algorithms
- **Benefits**: Flexible analysis, no data duplication

## Next Steps

1. **Implement Core Game Types**: X01, Cricket, Around the Clock
2. **Develop Database Layer**: Complete drift implementation with repository abstraction for web compatibility
3. **Build UI Components**: Game boards, score displays, statistics views
4. **Implement Statistics Engine**: Compute various metrics from dart data
5. **Add Optional Backend**: Computer vision integration
6. **Testing**: Unit tests, integration tests, UI tests

## Appendix: Historical — Web Database Migration

> This section is **historical context only**. It documents how the web data layer
> arrived at its current state. For the canonical architecture, see
> [`ARCHITECTURE_COMPLETE.md`](ARCHITECTURE_COMPLETE.md); for the canonical schema,
> see [`DATABASE_DDL.md`](DATABASE_DDL.md). The mobile-side migration off `sqflite`
> onto a single drift engine on every platform is tracked in PRs #122–#124
> (issue #112).

### From IndexedDB to SQLite WASM (web)

The project migrated from the deprecated `WebDatabase` (IndexedDB-only) to the
`WasmDatabase` approach:

**Improvements delivered:**
- Cross-platform consistency: the same SQLite engine (via `drift`) on web and native platforms
- Automatic storage selection on web: OPFS (preferred) → IndexedDB → Memory fallback
- Better performance than the IndexedDB adapter overhead
- Simplified architecture: no manual web-worker configuration in app code

**Implementation outcome:**
- Web factory uses `package:drift/wasm.dart` with `WasmDatabase.open()`
- Identical schema and behaviour across platforms
- Requires `sqlite3.wasm` and `drift_worker.dart.js` assets to be served (see the web one-time asset setup in `CLAUDE.md`)
- All repository implementations wrap engine errors in `DriftWrappedException`
