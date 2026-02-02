# Backend Integration and Multiplayer Architecture

This document extends the existing architecture with backend integration details and multiplayer functionality, building upon the foundations established in README.md, DATA.md, and ARCHITECTURE.md.

## Overview

This architecture implements a **local-first** approach with **optional backend integration**, supporting both offline play and cloud synchronization. It also introduces **multiplayer functionality** for both local (hotseat) and remote play.

## Backend Integration Architecture

### Core Principles

1. **Local-First**: All functionality works offline by default
2. **Optional Backend**: Backend is configurable and not required
3. **Data Ownership**: Users control their data and can self-host
4. **Seamless Sync**: Automatic synchronization when online

### Backend Service Interface

The Backend Service provides a comprehensive interface for backend integration, supporting authentication, data synchronization, multiplayer functionality, and configuration management. It follows RESTful principles and provides Promise-based asynchronous operations.

**Key Functional Areas**:
- **Authentication**: User registration, login, and session management
- **Data Synchronization**: Bi-directional sync of players, games, and statistics
- **Multiplayer**: Game session creation, joining, and state management
- **Configuration**: Backend status monitoring and connectivity testing

The service is designed to be optional and configurable, allowing applications to work completely offline while providing seamless integration when backend connectivity is available.

### Data Synchronization Strategy

#### Sync Process Flow

The synchronization process follows a robust workflow:

1. **Local Storage**: All changes are first stored in the local database
2. **Queue Management**: Changes are added to the synchronization queue
3. **Connectivity Check**: System checks for network availability
4. **Online Path**: If online, changes are sent to the backend immediately
5. **Offline Path**: If offline, changes are queued for later synchronization
6. **Success Handling**: Successful syncs are marked as completed
7. **Error Handling**: Failed syncs are scheduled for retry with exponential backoff
8. **Network Monitoring**: System monitors network status for connectivity changes
9. **Automatic Retry**: Queued operations are automatically retried when connectivity is restored

This workflow ensures data consistency and reliability regardless of network conditions.

#### Conflict Resolution

- **Timestamp-based**: Last write wins with server timestamp validation
- **Manual Resolution**: For critical conflicts, prompt user intervention
- **Data Preservation**: Never lose local data; create duplicates if necessary

### Account Linking Flow

The account linking process follows a sequential workflow:

1. **Authentication**: User registers or logs in to the backend service
2. **Token Reception**: Application receives authentication token from backend
3. **Player Selection**: User selects which local players to link to their account
4. **Data Synchronization**: Application syncs selected players with backend
5. **Confirmation**: User receives confirmation of successful linking

This flow ensures that local player data can be associated with user accounts while maintaining the option for local-only players who don't require account linking.

## Multiplayer Architecture

### Multiplayer Modes

#### 1. Hotseat Mode (Local)
- **Description**: Players share the same device
- **Implementation**: Turn-based with local state management
- **Data Storage**: Local only (unless players are account-linked)
- **Use Case**: Players in the same physical location

#### 2. Remote Mode (Network)
- **Description**: Players on different devices
- **Implementation**: WebSocket-based real-time synchronization
- **Data Storage**: Local + backend sync for linked players
- **Use Case**: Online play with friends

### Multiplayer Protocol

#### Message Types

The multiplayer protocol uses a discriminated union type for messages, where each message type has a specific structure:

- **Session Management**: `session_created`, `player_joined`, `player_left`
- **Game State**: `game_state`, `dart_thrown`, `turn_completed`
- **Game Completion**: `game_completed`
- **Error Handling**: `error` with code and message

Each message includes a `type` field that identifies its purpose, allowing the receiving client to handle it appropriately. The protocol supports both game state synchronization and real-time event notification.

#### Session Management

The Multiplayer Manager handles WebSocket-based communication and session lifecycle management. It maintains the current game session state and manages player connections.

**Key Responsibilities**:
- Establish and maintain WebSocket connections to the backend
- Create and manage multiplayer game sessions
- Handle player joining and leaving sessions
- Validate and submit player turns
- Maintain current session state and player roster
- Provide client-side validation of game actions

The manager follows a stateful approach, maintaining the current session and player information to provide context for all multiplayer operations.

### Server-Side Validation

#### Validation Rules

1. **Score Validation**: Check against game rules (e.g., maximum 60 for X01)
2. **Turn Validation**: Ensure proper turn order and player sequence
3. **Game State**: Validate transitions between game states
4. **Win Conditions**: Verify game completion criteria

#### Validation Process

The validation process follows a two-stage approach:

1. **Client-Side Validation**: Initial validation of user actions before network transmission
2. **Server-Side Validation**: Comprehensive validation of all game rules and constraints

**Workflow**:
- Client validates basic constraints and rejects invalid actions locally
- Valid actions are sent to server for comprehensive validation
- Server validates against complete game rules and current state
- Invalid actions are rejected with appropriate error messages
- Valid actions are processed and broadcast to all clients
- Game state is updated consistently across all connected clients

This dual validation approach ensures data integrity while providing responsive user feedback.

## Data Model Extensions

### Account Entity

The Account entity represents user accounts for authentication and authorization. It stores credentials, tokens, and account metadata for users who opt into backend integration features.

**Key Properties**:
- Unique identifier and email address
- Authentication and refresh tokens
- Configurable backend URL
- Account creation and login timestamps

### Player Entity (Extended)

The extended Player entity enhances the core player model with account integration features. It maintains backward compatibility while adding optional account linking capabilities.

**Key Properties**:
- Unique identifier and player name
- Creation and activity timestamps
- Optional account association
- Account linking status indicator
- Optional avatar support

This extended entity supports both local-only players and account-linked players within the same data model.

### Game Session Entity

The Game Session entity represents a multiplayer game session with its current state and participants. It tracks the lifecycle of a multiplayer game from creation to completion.

**Key Properties**:
- Unique session identifier and associated game reference
- Host player information and participant list
- Session lifecycle status (waiting, in_progress, completed, abandoned)
- Timestamps for session lifecycle events
- Current turn player reference

Game sessions enable remote multiplayer functionality by providing a shared context for all connected players.

### Sync Queue Entity

The Sync Operation entity represents individual synchronization operations in the sync queue. It tracks the status and progress of data synchronization between local storage and backend services.

**Key Properties**:
- Unique operation identifier and entity metadata
- Operation type (create, update, delete) and full payload
- Status tracking (pending, processing, completed, failed)
- Timestamps for operation lifecycle events
- Attempt count for retry management

The sync queue ensures reliable data synchronization with automatic retry for failed operations.

## Database Schema Extensions

### Accounts Table

For the extended database schema including accounts and synchronization tables, refer to the core schema in [Data Structure](docs/DATA.md) and understand that these extensions are optional components for advanced backend integration features.

### Database Schema Extensions

The backend integration introduces several optional database extensions:

**Accounts Table**: Stores user account information for authentication and authorization
- Unique account identifiers and email addresses
- Authentication tokens and refresh tokens
- Backend URL configuration
- Account creation and login timestamps

**Players Table (Extended)**: Enhances the core players table with account linking
- Optional account association for players
- Linking status indicators
- Avatar URL support
- Maintains backward compatibility with local-only players

These extensions support advanced features like multiplayer sessions, data synchronization, and user accounts while maintaining compatibility with the core local-first architecture.

### Extended Database Tables

The backend integration requires several additional database tables:

**Sync Queue Table**: Manages pending synchronization operations
- Operation tracking with unique identifiers
- Entity type and operation type classification
- JSON payload storage for operation data
- Status tracking and retry management
- Timestamp and error information

**Game Sessions Table**: Tracks multiplayer game sessions
- Session identification and game association
- Host player and status information
- Lifecycle timestamps (creation, start, completion)
- Current turn player reference
- Proper foreign key relationships

These tables extend the core schema to support advanced synchronization and multiplayer features.

## Implementation Components

### Backend Service Implementation

The Backend Service implementation handles all communication with the backend server, including authentication, data synchronization, and multiplayer session management. It uses the Dio HTTP client for REST API communication and integrates with the local database for data persistence.

**Key Components**:
- **Authentication**: User registration and login with token management
- **Data Synchronization**: Comprehensive sync of all entity types with retry logic
- **Session Management**: Multiplayer game session creation and management
- **Error Handling**: Robust error handling and retry mechanisms
- **Database Integration**: Tight integration with local database operations

The service follows a modular design with separate methods for each functional area, ensuring clean separation of concerns and easy maintenance.

### Multiplayer Game Manager

The Multiplayer Game Manager extends the ChangeNotifier class to provide state management for multiplayer game sessions. It integrates backend services with local database operations and handles WebSocket communication for real-time multiplayer functionality.

**Key Responsibilities**:
- Session lifecycle management (creation, joining, leaving)
- WebSocket connection establishment and management
- Real-time message handling and event processing
- Game state synchronization across clients
- Player management and turn submission
- Client-side validation and error handling
- State change notification for UI updates

The manager follows the provider pattern, making it easy to integrate with Flutter's widget tree for reactive UI updates.

## Security Considerations

### Authentication
- **JWT Tokens**: Secure storage with refresh token rotation
- **Token Expiry**: Short-lived access tokens (15-30 minutes)
- **Secure Storage**: Platform-specific secure storage for tokens

### Data Protection
- **HTTPS**: All communications encrypted
- **Input Validation**: Both client and server-side
- **Rate Limiting**: Prevent abuse of API endpoints

### Multiplayer Security
- **Session Tokens**: Unique tokens for each game session
- **Player Authentication**: Validate player identity
- **Anti-Cheating**: Server-side validation of all actions

## Configuration Management

### Backend Configuration

The Backend Configuration class provides a structured approach to managing backend service settings. It supports serialization/deserialization for persistent storage and provides sensible defaults for easy setup.

**Key Features**:
- Default backend URL configuration
- Flexible host specification
- Auto-sync toggle functionality
- JSON serialization support
- Immutable default values

The configuration follows a fail-safe approach, using default values when configuration data is missing or invalid.

### Settings Interface

The Settings Service provides persistent storage and retrieval of backend configuration settings. It integrates with the device's shared preferences system to maintain configuration across application sessions.

**Key Responsibilities**:
- Backend configuration persistence and retrieval
- Default configuration management
- Configuration serialization and deserialization
- Platform-specific storage integration

The service ensures that backend settings are preserved between application launches and provides a consistent interface for configuration management.

## Error Handling and Recovery

### Sync Error Handling

The Sync Error Handler provides robust error handling and automatic retry logic for synchronization operations. It implements an exponential backoff strategy to handle transient network issues while preventing infinite retry loops.

**Key Features**:
- Configurable maximum attempt limit
- Exponential backoff with predefined delays
- Automatic retry of failed operations
- Comprehensive error tracking and logging
- Status updates for operation lifecycle

The handler ensures reliable data synchronization by automatically retrying failed operations with increasing delays between attempts.

### Network Monitoring

The Network Monitor provides real-time network connectivity monitoring and notification capabilities. It extends ChangeNotifier to provide reactive updates to the application when network status changes.

**Key Responsibilities**:
- Continuous network connectivity monitoring
- Automatic detection of connectivity changes
- Reactive state management with ChangeNotifier
- Background synchronization triggering
- Platform-specific connectivity API integration

The monitor enables applications to respond appropriately to network changes, such as triggering background synchronization when connectivity is restored.

## Integration with Existing Architecture

### Extending GameProvider

The extended GameProvider integrates backend services and multiplayer functionality into the core game management system. It maintains backward compatibility while adding optional backend integration capabilities.

**Key Enhancements**:
- Optional backend service integration
- Multiplayer session management
- Automatic synchronization of game data
- Unified interface for local and remote games
- Seamless fallback to local functionality

The extended provider follows the same ChangeNotifier pattern as the base implementation, ensuring consistent state management and UI updates regardless of whether backend features are used.

## Deployment Considerations

### Backend Deployment Options

1. **Default Hosted Backend**: `https://api.darts-game.com`
2. **Self-Hosted Options**:
   - Docker container
   - Python (Flask/FastAPI)
   - Node.js (Express/NestJS)
   - Rust (Actix/Warpg)

### Configuration Files

The backend integration supports flexible configuration through YAML configuration files. These files allow customization of backend behavior, database settings, authentication parameters, and multiplayer options.

**Configuration Sections**:
- **Backend**: Host, port, and SSL settings
- **Database**: Database type and connection parameters
- **Authentication**: JWT secrets and token expiration
- **Multiplayer**: Player limits, timeouts, and port settings

Configuration files follow standard YAML syntax and support environment-specific settings for different deployment scenarios.

## Future Enhancements

1. **Real-time Statistics**: Live stats during multiplayer games
2. **Spectator Mode**: Allow others to watch games in progress
3. **Game Replay**: Record and replay multiplayer games
4. **Tournament Support**: Organized multiplayer tournaments
5. **Social Features**: Friends list, game invitations, leaderboards
6. **Cross-Platform Play**: Mobile ↔ Web ↔ Desktop

## Consistency with Existing Documentation

### Alignment with README.md
- ✅ **Local-First**: Maintains offline capability as primary feature
- ✅ **Optional Backend**: Backend remains configurable and optional
- ✅ **Cross-Platform**: Compatible with Flutter mobile implementation
- ✅ **Self-Hosted**: Supports custom backend hosts

### Alignment with DATA.md
- ✅ **Data Structure**: Extends existing player and game models
- ✅ **No Pre-computed Stats**: Maintains raw data approach
- ✅ **UUID Identification**: Uses UUIDs consistently
- ✅ **Team Support**: Compatible with team game structures

### Alignment with ARCHITECTURE.md
- ✅ **Layered Architecture**: Fits within existing layers
- ✅ **SQLite Storage**: Uses same database approach
- ✅ **Game Engine Pattern**: Extends abstract Game class
- ✅ **Statistics Engine**: Compatible with existing computation

## Migration Path

### From Current to New Architecture

1. **Phase 1**: Implement local player linking (no backend)
2. **Phase 2**: Add backend service interface
3. **Phase 3**: Implement data synchronization
4. **Phase 4**: Add hotseat multiplayer
5. **Phase 5**: Implement remote multiplayer
6. **Phase 6**: Add server-side validation

### Backward Compatibility

- All existing local functionality remains unchanged
- Local games continue to work without backend
- Existing data structures are preserved
- New features are opt-in via configuration

## Conclusion

This architecture extends the existing local-first design with optional backend integration and multiplayer capabilities while maintaining full backward compatibility and offline functionality. The implementation follows the established patterns and conventions from the existing documentation, ensuring consistency across the entire codebase.