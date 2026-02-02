# Architecture Diagrams

This document provides visual representations of the Darts App architecture based on the current documentation.

## Global Architecture Overview

```mermaid
graph TD
    A[Flutter UI Layer] --> B[Flutter Business Logic Layer]
    B --> C[SQLite Data Layer]
    B --> D[Optional Backend Layer]
    D --> E[Computer Vision]
    E --> F[PyTorch/ONNX Models]
    
    style A fill:#4CAF50,stroke:#388E3C
    style B fill:#2196F3,stroke:#1976D2
    style C fill:#FF9800,stroke:#F57C00
    style D fill:#9C27B0,stroke:#7B1FA2
    style E fill:#607D8B,stroke:#455A64
    style F fill:#795548,stroke:#5D4037
```

## Layered Architecture Diagram

```mermaid
graph TD
    subgraph Presentation Layer
        A1[Game Screens] --> A2[Statistics Dashboards]
        A2 --> A3[History Views]
        A3 --> A4[Settings]
    end
    
    subgraph Business Logic Layer
        B1[Game Engine] --> B2[Statistics Engine]
        B2 --> B3[Data Management]
        B3 --> B4[State Management]
        B4 --> B5[Backend Sync Manager]
    end
    
    subgraph Data Layer
        C1[Database Helper] --> C2[SQLite Database]
        C2 --> C3[Players Table]
        C2 --> C4[Games Table]
        C2 --> C5[Teams Table]
        C2 --> C6[Darts Table]
    end
    
    subgraph Optional Backend Layer
        D1[Backend Service] --> D2[REST API]
        D2 --> D3[Computer Vision]
        D3 --> D4[PyTorch Models]
        D3 --> D5[ONNX Models]
    end
    
    A1 --> B1
    A2 --> B2
    B3 --> C1
    B5 --> D1
    
    style Presentation Layer fill:#E8F5E9,stroke:#C8E6C9
    style Business Logic Layer fill:#E3F2FD,stroke:#BBDEFB
    style Data Layer fill:#FFF3E0,stroke:#FFE0B2
    style Optional Backend Layer fill:#F3E5F5,stroke:#E1BEE7
```

## Component Architecture

```mermaid
classDiagram
    class FlutterUI {
        +GameSelectionScreen
        +GamePlayScreen
        +StatisticsDashboard
        +GameHistoryView
        +SettingsScreen
    }
    
    class GameEngine {
        +processDart()
        +undoLastThrow()
        +determineWinner()
        +serialize()
        +deserialize()
    }
    
    class StatisticsEngine {
        +calculatePlayerStats()
        +calculateGameStats()
        +getPerformanceTrends()
    }
    
    class DatabaseHelper {
        +insertPlayer()
        +getAllPlayers()
        +insertGame()
        +getGameDarts()
    }
    
    class BackendService {
        +autoScoreImage()
        +syncGameData()
        +detectDarts()
    }
    
    class GameProvider {
        +startNewGame()
        +loadGame()
        +processDart()
    }
    
    FlutterUI --> GameProvider
    GameProvider --> GameEngine
    GameProvider --> StatisticsEngine
    GameProvider --> DatabaseHelper
    GameProvider --> BackendService
    DatabaseHelper --> SQLite
    BackendService --> RESTAPI
    
    class SQLite {
        +Players Table
        +Games Table
        +Teams Table
        +Darts Table
    }
    
    class RESTAPI {
        +/auto-score
        +/sync
        +/sessions
    }
```

## Database Schema Diagram

```mermaid
classDiagram
    class Players {
        TEXT player_id PK
        TEXT name
        TEXT created_at
        TEXT last_active
    }
    
    class Games {
        TEXT game_id PK
        TEXT game_type
        TEXT game_config
        TEXT start_time
        TEXT end_time
        TEXT winner
        INTEGER is_completed
        TEXT game_state
    }
    
    class Teams {
        TEXT team_id PK
        TEXT team_name
        TEXT game_id FK
    }
    
    class Darts {
        INTEGER dart_id PK
        TEXT game_id FK
        TEXT player_id FK
        INTEGER turn_number
        INTEGER dart_number
        INTEGER score
        TEXT segment
        REAL x
        REAL y
    }
    
    class GameParticipants {
        TEXT game_id FK
        TEXT participant_id FK
        TEXT participant_type
    }
    
    Games "1" -- "0..*" Teams : contains
    Games "1" -- "0..*" Darts : records
    Players "1" -- "0..*" Darts : throws
    Games "1" -- "1..*" GameParticipants : includes
    Players "1" -- "0..*" GameParticipants : participates
    Teams "1" -- "1..*" GameParticipants : participates
    
    note for Players "Core player information"
    note for Games "Game sessions and metadata"
    note for Darts "Individual dart throws"
    note for GameParticipants "Flexible participant model"
```

## Backend Integration Architecture

```mermaid
graph TD
    subgraph Mobile App
        A[Flutter App] --> B[GameProvider]
        B --> C[BackendService]
        C --> D[SyncQueue]
    end
    
    subgraph Backend Server
        E[REST API] --> F[Auth Service]
        E --> G[Sync Service]
        E --> H[Multiplayer Service]
        H --> I[WebSocket Server]
        G --> J[Conflict Resolution]
    end
    
    subgraph Database
        K[SQLite Local] --> L[Backend Database]
    end
    
    C -->|HTTP/HTTPS| E
    I -->|WebSocket| B
    D -->|Sync Operations| L
    L -->|Sync Response| D
    
    style Mobile App fill:#E8F5E9,stroke:#C8E6C9
    style Backend Server fill:#E3F2FD,stroke:#BBDEFB
    style Database fill:#FFF3E0,stroke:#FFE0B2
```

## Multiplayer Architecture

```mermaid
graph TD
    subgraph Client A
        A1[Player 1] --> A2[Multiplayer Manager]
        A2 --> A3[WebSocket Connection]
    end
    
    subgraph Client B
        B1[Player 2] --> B2[Multiplayer Manager]
        B2 --> B3[WebSocket Connection]
    end
    
    subgraph Backend
        C1[WebSocket Server] --> C2[Session Manager]
        C2 --> C3[Game State Manager]
        C3 --> C4[Validation Engine]
    end
    
    A3 -->|Messages| C1
    B3 -->|Messages| C1
    C1 -->|Broadcast| A3
    C1 -->|Broadcast| B3
    C2 -->|State Updates| C3
    C4 -->|Validation| C3
    
    style Client A fill:#F8BBD0,stroke:#F06292
    style Client B fill:#B2EBF2,stroke:#4DD0E1
    style Backend fill:#C5CAE9,stroke:#7986CB
```

## Data Synchronization Flow

```mermaid
flowchart TD
    A[Local Data Change] --> B[Store in SQLite]
    B --> C[Add to Sync Queue]
    C --> D{Network Available?}
    
    D -->|Yes| E[Send to Backend]
    D -->|No| F[Queue for Later]
    
    E --> G{Sync Successful?}
    G -->|Yes| H[Mark as Synced]
    G -->|No| I[Increment Retry Count]
    
    I --> J{Max Retries Reached?}
    J -->|Yes| K[Mark as Failed]
    J -->|No| L[Calculate Retry Delay]
    
    L --> M[Wait Delay Period]
    M --> D
    
    F --> N[Monitor Network]
    N -->|Online| D
    
    style A fill:#4CAF50
    style B fill:#4CAF50
    style C fill:#4CAF50
    style D fill:#FFC107
    style E fill:#2196F3
    style F fill:#FF9800
    style G fill:#2196F3
    style H fill:#4CAF50
    style I fill:#FF5722
    style J fill:#FF5722
    style K fill:#F44336
    style L fill:#FF9800
    style M fill:#FF9800
    style N fill:#607D8B
```

## Game Engine Class Diagram

```mermaid
classDiagram
    class Game {
        <<abstract>>
        +gameType: String
        +config: GameConfiguration
        +players: List~Player~
        +currentPlayer: Player?
        +currentState: GameState
        +processDart(DartThrow)
        +undoLastThrow()
        +redoLastThrow()
        +determineWinner()
        +serialize()
        +deserialize(Map~String, dynamic~)
    }
    
    class X01Game {
        -startingScore: int
        -inStrategy: InStrategy
        -outStrategy: OutStrategy
        -playerHandicaps: Map~String, int~
        +processDart(DartThrow)
        -checkBust(int)
        -validateCheckout(DartThrow)
    }
    
    class CricketGame {
        -variant: CricketVariant
        -numbersInPlay: Set~int~
        -closedNumbers: Map~String, Set~int~~
        +processDart(DartThrow)
        -closeNumber(String, int)
    }
    
    Game <|-- X01Game
    Game <|-- CricketGame
    
    class GameFactory {
        +createGame(GameConfiguration, List~Player~) Game
        +deserializeGame(Map~String, dynamic~) Game
    }
    
    note for Game "Abstract base class for all game types"
    note for X01Game "301/501/701 variants with specific rules"
    note for CricketGame "Standard/cut-throat/no-score variants"
    note for GameFactory "Factory for creating game instances"
```

## State Management Architecture

```mermaid
stateDiagram-v2
    [*] --> GameProvider
    
    GameProvider --> GameCreation: startNewGame()
    GameProvider --> GameLoading: loadGame()
    
    state GameCreation {
        [*] --> Initializing
        Initializing --> CreatingGame: GameFactory.createGame()
        CreatingGame --> SavingToDB: db.insertGame()
        SavingToDB --> NotifyingUI
        NotifyingUI --> [*]
    }
    
    state GameLoading {
        [*] --> LoadingFromDB
        LoadingFromDB --> Deserializing: GameFactory.deserializeGame()
        Deserializing --> NotifyingUI
        NotifyingUI --> [*]
    }
    
    GameProvider --> DartProcessing: processDart()
    
    state DartProcessing {
        [*] --> AddingToTurn
        AddingToTurn --> Processing: game.processDart()
        Processing --> SavingToDB: db.insertDart()
        SavingToDB --> CheckingTurnComplete
        
        CheckingTurnComplete --> EndingTurn: turn complete
        CheckingTurnComplete --> Continuing: turn incomplete
        
        EndingTurn --> CheckingGameComplete
        CheckingGameComplete --> CompletingGame: winner found
        CheckingGameComplete --> StartingNewTurn: no winner
        
        CompletingGame --> UpdatingStats: statsEngine.update()
        UpdatingStats --> NotifyingUI
        
        StartingNewTurn --> NotifyingUI
        Continuing --> NotifyingUI
        
        NotifyingUI --> [*]
    }
    
    GameProvider --> [*]
```

## Deployment Architecture

```mermaid
graph TD
    subgraph Mobile Devices
        A[Android App] --> B[Flutter Framework]
        C[iOS App] --> B
        B --> D[SQLite Database]
    end
    
    subgraph Backend Options
        E[Self-Hosted Python] --> F[Flask/FastAPI]
        G[Self-Hosted Node.js] --> H[Express/NestJS]
        I[Self-Hosted Rust] --> J[Actix/Warpg]
    end
    
    subgraph Cloud Services
        K[Default Backend] --> L[api.darts-game.com]
    end
    
    B -->|Optional| F
    B -->|Optional| H
    B -->|Optional| J
    B -->|Optional| L
    
    F --> M[Computer Vision]
    H --> M
    J --> M
    L --> M
    
    M --> N[PyTorch Models]
    M --> O[ONNX Models]
    
    style Mobile Devices fill:#E8F5E9,stroke:#C8E6C9
    style Backend Options fill:#FFF3E0,stroke:#FFE0B2
    style Cloud Services fill:#E3F2FD,stroke:#BBDEFB
```

## Security Architecture

```mermaid
graph TD
    subgraph Client Security
        A[Secure Storage] --> B[JWT Tokens]
        A --> C[Refresh Tokens]
        D[HTTPS] --> E[All Communications]
        F[Input Validation] --> G[Client-Side]
    end
    
    subgraph Server Security
        H[JWT Validation] --> I[Authentication Middleware]
        J[Rate Limiting] --> K[API Endpoints]
        L[Input Validation] --> M[Server-Side]
        N[Session Tokens] --> O[Game Sessions]
    end
    
    subgraph Multiplayer Security
        P[Player Authentication] --> Q[Identity Verification]
        R[Anti-Cheating] --> S[Server-Side Validation]
        T[Data Encryption] --> U[WebSocket Messages]
    end
    
    B -->|Sent to| I
    C -->|Sent to| I
    G -->|Complements| M
    I -->|Protects| K
    O -->|Secures| Q
    S -->|Validates| R
    
    style Client Security fill:#F8BBD0,stroke:#F06292
    style Server Security fill:#B2EBF2,stroke:#4DD0E1
    style Multiplayer Security fill:#C5CAE9,stroke:#7986CB
```

## Key Architectural Decisions Visualized

```mermaid
graph LR
    subgraph Decision 1: Local-First
        A[Offline Capability] --> B[SQLite Storage]
        B --> C[Optional Sync]
        style A fill:#4CAF50
        style B fill:#4CAF50
        style C fill:#4CAF50
    end
    
    subgraph Decision 2: Cross-Platform
        D[Single Codebase] --> E[Flutter]
        E --> F[Android & iOS]
        style D fill:#2196F3
        style E fill:#2196F3
        style F fill:#2196F3
    end
    
    subgraph Decision 3: Game Engine Pattern
        G[Abstract Game Class] --> H[X01 Implementation]
        G --> I[Cricket Implementation]
        style G fill:#FF9800
        style H fill:#FF9800
        style I fill:#FF9800
    end
    
    subgraph Decision 4: Statistics Computation
        J[Raw Data Storage] --> K[On-Demand Calculation]
        K --> L[Flexible Analysis]
        style J fill:#9C27B0
        style K fill:#9C27B0
        style L fill:#9C27B0
    end
    
    subgraph Decision 5: Optional Backend
        M[Works Without Backend] --> N[Enhanced With Backend]
        N --> O[Multiplayer & Sync]
        style M fill:#607D8B
        style N fill:#607D8B
        style O fill:#607D8B
    end
```

## Component Relationships

```mermaid
flowchart LR
    subgraph UI Components
        A[Game Screens] --> B[Statistics Views]
        B --> C[History Views]
    end
    
    subgraph Business Components
        D[Game Engine] --> E[Statistics Engine]
        E --> F[State Management]
    end
    
    subgraph Data Components
        G[Database Helper] --> H[SQLite]
        H --> I[Players Table]
        H --> J[Games Table]
    end
    
    subgraph Backend Components
        K[Backend Service] --> L[REST API]
        L --> M[Computer Vision]
    end
    
    A --> D
    B --> E
    C --> G
    D --> G
    E --> G
    F --> D
    F --> K
    K --> G
    
    style UI Components fill:#E8F5E9,stroke:#C8E6C9
    style Business Components fill:#E3F2FD,stroke:#BBDEFB
    style Data Components fill:#FFF3E0,stroke:#FFE0B2
    style Backend Components fill:#F3E5F5,stroke:#E1BEE7
```

## Architecture Summary

These diagrams provide a comprehensive visual representation of the Darts App architecture:

- **Global Overview**: High-level architecture layers
- **Layered Architecture**: Detailed component breakdown
- **Component Architecture**: Class relationships and dependencies
- **Database Schema**: Entity-relationship diagram
- **Backend Integration**: Server-client communication
- **Multiplayer**: Real-time game sessions
- **Data Synchronization**: Offline-first sync workflow
- **Game Engine**: Class hierarchy and inheritance
- **State Management**: Complex state transitions
- **Deployment**: Various hosting options
- **Security**: Comprehensive security measures
- **Key Decisions**: Visualized architectural choices
- **Component Relationships**: System-wide dependencies

The diagrams use consistent color coding:
- **Green**: UI/Presentation layer
- **Blue**: Business logic layer  
- **Orange**: Data layer
- **Purple**: Backend services
- **Grey**: Infrastructure/Deployment
- **Pink/Red**: Security components