# Darts App Architecture

This document provides a detailed architectural overview aligned with the existing README.md specification.

## Global Architecture Overview

The Darts App follows a layered architecture with clear separation of concerns. The Flutter UI layer handles user interaction, the business logic layer processes game rules and statistics, the data layer manages local persistence via SQLite, and an optional backend layer provides advanced features like auto-scoring and synchronization.

## Layered Architecture

### 1. Presentation Layer (Flutter UI)
- **Platform**: Android and iOS via Flutter
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

### 3. Data Layer (SQLite)
- **Responsibility**: Local data persistence
- **Implementation**: SQLite via `sqflite` and `path_provider` packages
- **Key Components**:
  - Database schema management
  - Data Access Objects (DAOs)
  - Query builders
  - Data validation
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
- Generate game-specific metrics and performance indicators
- Compute historical trends and progress over time
- Provide data for visualizations and dashboards
- Support various analytical queries for different game types

## Database Schema (SQLite)

For the complete database schema and detailed table structures, refer to the [Data Structure](docs/DATA.md) documentation. This provides the authoritative source for all data models and relationships.

### Key Tables Overview

The database follows a relational design with these core entities:

- **Players**: Stores player information with UUID identification
- **Games**: Tracks game sessions with configuration and state.
- **Competitors**: Represents competing entities (solo players or teams) within a game.
- **Competitor Players**: Links players to specific competitors, defining team composition.

### Design Principles

- **Relational Integrity**: Proper foreign key relationships between tables
- **Data Normalization**: Minimal redundancy with proper table relationships
- **Performance**: Indexes on frequently queried columns
- **Extensibility**: Support for additional game types and features

## Data Access Layer

### Database Helper

The Database Helper provides a singleton interface for SQLite database operations, handling all CRUD operations and ensuring proper database initialization. It follows the repository pattern to abstract database operations from the business logic layer.

Key responsibilities:
- Database initialization and schema management
- Singleton access pattern for database connections
- CRUD operations for all data entities
- Transaction management and error handling
- Data model mapping between Dart objects and database records

The implementation uses the `sqflite` package for SQLite operations and `path_provider` for platform-specific file system access.

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
- **Implementation**: SQLite for local storage, optional REST API sync
- **Benefits**: Works without internet, user privacy, no server costs

### 2. Flutter for Cross-Platform
- **Rationale**: Single codebase for Android and iOS
- **Implementation**: Flutter widgets with platform-specific adaptations
- **Benefits**: Faster development, consistent UI, hot reload

### 3. SQLite for Data Storage
- **Rationale**: Relational data, complex queries for statistics
- **Implementation**: sqflite package with proper schema
- **Benefits**: Better for statistics, long-term maintainability

### 4. Game Engine Pattern
- **Rationale**: Separate game logic from UI
- **Implementation**: Abstract Game class with concrete implementations
- **Benefits**: Easy to add new game types, consistent rules

### 5. Statistics Computation
- **Rationale**: Compute from raw data, not pre-calculated
- **Implementation**: StatisticsEngine with various algorithms
- **Benefits**: Flexible analysis, no data duplication

## Next Steps

1. **Implement Core Game Types**: X01, Cricket, Around the Clock
2. **Develop Database Layer**: Complete SQLite implementation
3. **Build UI Components**: Game boards, score displays, statistics views
4. **Implement Statistics Engine**: Compute various metrics from dart data
5. **Add Optional Backend**: Computer vision integration
6. **Testing**: Unit tests, integration tests, UI tests

