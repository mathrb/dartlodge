# State Management Architecture

**Status:** Authoritative  
**Scope:** Flutter Frontend State Management  
**Decision:** Riverpod with Clean Architecture Integration

---

## Executive Summary

### Core Decision
**Use Riverpod** as the state management solution for the Flutter darts application.

### Why Riverpod?
- Compile-time safety (catches errors before runtime)
- No BuildContext dependency (access state anywhere)
- Easy to test (simple mocking and isolation)
- Type-safe with full inference
- Mature ecosystem with active maintenance

### Key Architecture Principles
1. **Immutable State**: All state classes use Freezed for immutability
2. **Clean Separation**: UI → Notifiers → UseCases → Repositories (no shortcuts)
3. **AsyncValue Pattern**: All async operations wrapped in AsyncValue for proper loading/error/data handling
4. **Event-Based Communication**: UI dispatches events via notifier methods, never mutates state directly
5. **Auto-Dispose by Default**: Providers clean up automatically unless explicitly marked keepAlive

### Provider Type Quick Reference

| Provider Type | Use For | Example |
|--------------|---------|---------|
| `Provider` | Immutable dependencies (repositories, use cases) | Database, API clients |
| `StateProvider` | Simple values (no business logic) | Selected filter, toggle states |
| `NotifierProvider` | Synchronous state with logic | Game setup wizard |
| `AsyncNotifierProvider` | Async state (database, network) | Active game, player list |
| `StreamProvider` | Real-time data streams | Multiplayer updates, sync status |

### Critical Patterns

**State Structure:**
```dart
@freezed
class GameState with _$GameState {
  const factory GameState({
    required String gameId,
    required bool isComplete,
    // ... all fields
  }) = _GameState;
}
```

**Async Operations:**
```dart
state = await AsyncValue.guard(() async {
  return await someAsyncOperation();
});
```

**UI State Handling:**
```dart
ref.watch(activeGameProvider).when(
  data: (game) => GameView(game: game),
  loading: () => LoadingIndicator(),
  error: (error, stack) => ErrorView(error: error),
);
```

### File Organization
```
lib/features/<feature>/presentation/
├── providers/     # Provider definitions
├── state/         # State classes (Freezed)
├── widgets/       # UI components
└── pages/         # Full screens
```

### Testing Strategy
- Override providers in tests with mocks
- Test notifiers in isolation from UI
- Use ProviderContainer for unit tests
- Use ProviderScope for widget tests

### Anti-Patterns to Avoid
❌ Mutating state directly  
❌ Business logic in UI  
❌ Using `read()` in build methods (use `watch()`)  
❌ Catching exceptions when using AsyncValue.guard  
❌ Creating circular provider dependencies  

### What Developers Need to Know
1. **Every feature has its own providers** (in feature/presentation/providers/)
2. **All state is immutable** (use copyWith to update)
3. **Always handle all three AsyncValue states** (data, loading, error)
4. **Notifier methods are the only way to change state** (no direct mutation)
5. **Dependencies flow down** (UI → Notifiers → UseCases → Repositories)

### Quick Start Checklist
- [ ] Add dependencies: `riverpod`, `flutter_riverpod`, `freezed`, `riverpod_generator`
- [ ] Set up build_runner for code generation
- [ ] Create core providers (database, repositories) in `core/providers/`
- [ ] Create feature-specific providers in each `features/<feature>/presentation/providers/`
- [ ] Use `@riverpod` annotation with code generation
- [ ] Wrap root widget with `ProviderScope`

---

## Detailed Specification

The following sections provide comprehensive examples and patterns for implementing the state management architecture outlined above.

---

## 1. State Management Decision

### 1.1 Selected Solution: **Riverpod**

**Rationale:**
- **Compile-time safety**: Provider lookup errors caught at compile time
- **Testability**: Easy to mock and test in isolation
- **No BuildContext dependency**: Providers accessible anywhere
- **Flexible scoping**: Fine-grained control over state lifecycle
- **Strong typing**: Full type inference support
- **Code generation support**: Reduces boilerplate with `riverpod_generator`
- **Established ecosystem**: Mature, well-documented, actively maintained

**Alternatives Considered:**
- **Bloc**: More verbose, steeper learning curve, overkill for this app
- **Provider**: Less type-safe, requires BuildContext, predecessor to Riverpod
- **GetX**: Too opinionated, mixes concerns, harder to test

---

## 2. State Architecture Overview

### 2.1 State Layer Hierarchy

```
┌─────────────────────────────────────────┐
│           UI Layer (Widgets)            │
│  - ConsumerWidget / Consumer            │
│  - Watches providers for state          │
│  - Dispatches events via notifiers      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      State Notifiers (Controllers)      │
│  - AsyncNotifierProvider                │
│  - NotifierProvider                     │
│  - StateNotifierProvider                │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│          Use Cases (Domain)             │
│  - ProcessDartUseCase                   │
│  - CreateGameUseCase                    │
│  - LoadGameUseCase                      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      Repositories (Data Layer)          │
│  - GameRepository                       │
│  - PlayerRepository                     │
│  - StatisticsRepository                 │
└─────────────────────────────────────────┘
```

---

## 3. Provider Types and Usage

### 3.1 Provider (Immutable Dependencies)

Used for: Dependencies that don't change (repositories, use cases)

```dart
@riverpod
GameRepository gameRepository(GameRepositoryRef ref) {
  final database = ref.watch(databaseProvider);
  return GameRepositoryImpl(database);
}

@riverpod
ProcessDartUseCase processDartUseCase(ProcessDartUseCaseRef ref) {
  final repository = ref.watch(gameRepositoryProvider);
  return ProcessDartUseCase(repository);
}
```

**When to use:**
- Singletons
- Factory functions
- Computed values from other providers
- Dependencies injection

---

### 3.2 StateProvider (Simple State)

Used for: Simple state that can be modified directly

```dart
final selectedPlayerIdsProvider = StateProvider<List<String>>((ref) => []);

final gameTypeFilterProvider = StateProvider<GameType?>((ref) => null);
```

**When to use:**
- Simple values (strings, numbers, booleans)
- UI state (selected items, filters, toggles)
- No business logic needed

**Not for:**
- Complex state with business logic
- State that requires validation
- State that needs side effects

---

### 3.3 NotifierProvider (Synchronous State with Logic)

Used for: State with synchronous business logic

```dart
@riverpod
class GameSetupNotifier extends _$GameSetupNotifier {
  @override
  GameSetupState build() {
    return GameSetupState.initial();
  }

  void selectGameType(GameType type) {
    state = state.copyWith(gameType: type);
  }

  void addPlayer(Player player) {
    if (state.players.length >= 8) {
      throw MaxPlayersExceededException();
    }
    state = state.copyWith(
      players: [...state.players, player],
    );
  }

  void toggleTeamMode() {
    state = state.copyWith(
      isTeamMode: !state.isTeamMode,
      teams: state.isTeamMode ? [] : null,
    );
  }
}
```

**When to use:**
- Synchronous state mutations
- Business logic that doesn't require async operations
- State that needs validation before mutation

---

### 3.4 AsyncNotifierProvider (Asynchronous State)

Used for: State that requires async operations (database, network)

```dart
@riverpod
class ActiveGame extends _$ActiveGame {
  @override
  Future<GameState?> build() async {
    // Load active game from database
    final repository = ref.read(gameRepositoryProvider);
    return await repository.getActiveGame();
  }

  Future<void> processDart(DartThrow dart) async {
    // Set to loading state
    state = const AsyncValue.loading();
    
    // Process the dart
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(processDartUseCaseProvider);
      final currentGame = await state.value;
      
      if (currentGame == null) {
        throw NoActiveGameException();
      }
      
      final event = DartThrown(
        gameId: currentGame.gameId,
        competitorId: currentGame.currentCompetitorId,
        segment: dart.segment,
        multiplier: dart.multiplier,
        inputMethod: InputMethod.manual,
      );
      
      return await useCase.execute(currentGame, event);
    });
  }

  Future<void> startNewGame(GameConfiguration config) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(createGameUseCaseProvider);
      return await useCase.execute(config);
    });
  }

  Future<void> undoLastDart() async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(undoLastDartUseCaseProvider);
      final currentGame = await state.value;
      
      if (currentGame == null) {
        throw NoActiveGameException();
      }
      
      return await useCase.execute(currentGame);
    });
  }
}
```

**When to use:**
- Database operations
- Network requests
- File I/O
- Any async business logic

---

### 3.5 StreamProvider (Real-time Data)

Used for: Subscribing to data streams (database changes, event logs)

```dart
@riverpod
Stream<List<GameEvent>> gameEventsStream(
  GameEventsStreamRef ref,
  String gameId,
) {
  final repository = ref.watch(gameRepositoryProvider);
  return repository.watchGameEvents(gameId);
}

@riverpod
Stream<GameStats> liveGameStats(
  LiveGameStatsRef ref,
  String gameId,
) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.watchGameStats(gameId);
}
```

**When to use:**
- Database change streams (SQLite triggers)
- Event log monitoring
- Live statistics updates during local games

**Future: WebSocket Support (Phase 2)**
```dart
// When remote multiplayer is implemented:
@riverpod
Stream<MultiplayerGameState> multiplayerGameStream(
  MultiplayerGameStreamRef ref,
  String sessionId,
) {
  final service = ref.watch(multiplayerServiceProvider);
  return service.watchSession(sessionId); // WebSocket-based
}
```

---

## 4. State Classes and Patterns

### 4.1 Immutable State with Freezed

All state classes must be immutable and use `freezed` for generation:

```dart
@freezed
class GameState with _$GameState {
  const factory GameState({
    required String gameId,
    required GameType type,
    required List<CompetitorState> competitors,
    required int currentTurnIndex,
    required int dartsThrownInTurn,
    required bool isComplete,
    String? winnerCompetitorId,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
}

@freezed
class CompetitorState with _$CompetitorState {
  const factory CompetitorState({
    required String competitorId,
    required String name,
    required CompetitorType type,
    required List<String> playerIds,
    required int currentRotationIndex,
    required dynamic gameSpecificState, // X01State, CricketState, etc.
  }) = _CompetitorState;

  factory CompetitorState.fromJson(Map<String, dynamic> json) =>
      _$CompetitorStateFromJson(json);
}
```

**Benefits:**
- Compile-time immutability
- Generated `copyWith` methods
- Equality and hash code
- JSON serialization
- Pattern matching with `when` and `map`

---

### 4.2 Union Types for State Variants

Use freezed unions for state that can be in multiple modes:

```dart
@freezed
class GameSetupState with _$GameSetupState {
  const factory GameSetupState.selectingType() = _SelectingType;
  
  const factory GameSetupState.configuringGame({
    required GameType type,
    required GameConfiguration config,
  }) = _ConfiguringGame;
  
  const factory GameSetupState.selectingPlayers({
    required GameType type,
    required GameConfiguration config,
    required List<Player> availablePlayers,
    required List<Player> selectedPlayers,
  }) = _SelectingPlayers;
  
  const factory GameSetupState.formingTeams({
    required GameType type,
    required GameConfiguration config,
    required List<Player> players,
    required List<Team> teams,
  }) = _FormingTeams;
  
  const factory GameSetupState.ready({
    required GameType type,
    required GameConfiguration config,
    required List<Competitor> competitors,
  }) = _Ready;
}
```

---

### 4.3 AsyncValue Pattern

Always use `AsyncValue` for async state:

```dart
// In UI
ref.watch(activeGameProvider).when(
  data: (game) => game == null 
    ? const EmptyGameView() 
    : GameBoardView(game: game),
  loading: () => const LoadingIndicator(),
  error: (error, stack) => ErrorView(
    message: error.toString(),
    onRetry: () => ref.invalidate(activeGameProvider),
  ),
);

// In notifier
state = await AsyncValue.guard(() async {
  // Your async operation
  return result;
});
```

**Never:**
- Catch exceptions manually when using `AsyncValue.guard`
- Mix sync and async state in the same provider
- Use `Future` directly in state without `AsyncValue`

---

## 5. Provider Organization

### 5.1 File Structure

```
lib/
├── features/
│   ├── game/
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   ├── active_game_provider.dart
│   │   │   │   ├── game_setup_provider.dart
│   │   │   │   └── dart_input_provider.dart
│   │   │   ├── state/
│   │   │   │   ├── game_state.dart
│   │   │   │   ├── game_setup_state.dart
│   │   │   │   └── dart_input_state.dart
│   │   │   └── pages/
│   │   │       └── game_page.dart
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       ├── process_dart_usecase.dart
│   │   │       └── create_game_usecase.dart
│   │   └── data/
│   │       └── repositories/
│   │           └── game_repository_impl.dart
│   └── players/
│       ├── presentation/
│       │   ├── providers/
│       │   │   └── players_provider.dart
│       │   └── pages/
│       │       └── players_page.dart
│       └── domain/
│           └── usecases/
│               └── get_players_usecase.dart
└── core/
    └── providers/
        ├── database_provider.dart
        └── shared_preferences_provider.dart
```

---

### 5.2 Provider Naming Conventions

```dart
// Providers that expose data
@riverpod
Future<List<Player>> players(PlayersRef ref) async { }

// Providers that manage state
@riverpod
class ActiveGame extends _$ActiveGame { }

// Providers for dependencies
@riverpod
GameRepository gameRepository(GameRepositoryRef ref) { }

// State providers (simple values)
final selectedGameTypeProvider = StateProvider<GameType?>((ref) => null);
```

**Naming rules:**
- NotifierProviders: PascalCase class name
- Function providers: camelCase function name
- StateProviders: descriptive camelCase with `Provider` suffix
- Stream providers: descriptive name with `Stream` suffix

---

## 6. State Lifecycle Management

### 6.1 Provider Auto-Dispose

Use `.autoDispose` for providers that should clean up when no longer watched:

```dart
@riverpod
class DartInput extends _$DartInput {
  @override
  DartInputState build() {
    // This provider will be disposed when no widget watches it
    return DartInputState.initial();
  }
}

// Explicitly keep alive for certain providers
@Riverpod(keepAlive: true)
class UserPreferences extends _$UserPreferences {
  @override
  Future<Preferences> build() async {
    // This provider persists for app lifetime
    final prefs = await SharedPreferences.getInstance();
    return Preferences.fromPrefs(prefs);
  }
}
```

**Auto-dispose by default for:**
- UI-specific state
- Temporary data
- Screen-scoped state

**Keep alive for:**
- User authentication
- App-wide settings
- Cached data that's expensive to reload

---

### 6.2 Provider Dependencies

Declare dependencies explicitly:

```dart
@riverpod
class ActiveGame extends _$ActiveGame {
  @override
  Future<GameState?> build() async {
    // Watch other providers
    final repository = ref.watch(gameRepositoryProvider);
    final userId = ref.watch(currentUserIdProvider);
    
    // Listen to changes
    ref.listen(syncStatusProvider, (previous, next) {
      if (next == SyncStatus.synced) {
        // Refresh game state after sync
        ref.invalidateSelf();
      }
    });
    
    return await repository.getActiveGame(userId);
  }
}
```

---

### 6.3 Invalidation and Refresh

```dart
// Invalidate a single provider
ref.invalidate(activeGameProvider);

// Invalidate self (from within provider)
ref.invalidateSelf();

// Refresh (invalidate and immediately rebuild)
ref.refresh(playersProvider);

// Invalidate all providers with a family parameter
ref.invalidate(gameStatsProvider);
```

---

## 7. Event Dispatch Patterns

### 7.1 UI to State Communication

UI dispatches events through notifier methods:

```dart
// In UI
final gameNotifier = ref.read(activeGameProvider.notifier);

ElevatedButton(
  onPressed: () async {
    final dart = DartThrow(
      segment: selectedSegment,
      multiplier: selectedMultiplier,
    );
    
    try {
      await gameNotifier.processDart(dart);
    } catch (e) {
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
  child: const Text('Confirm Dart'),
);
```

**Never:**
- Mutate state directly from UI
- Access repositories from UI
- Put business logic in UI code

---

### 7.2 Optimistic UI Updates

For better UX, show optimistic updates:

```dart
@riverpod
class ActiveGame extends _$ActiveGame {
  @override
  Future<GameState?> build() async {
    final repository = ref.read(gameRepositoryProvider);
    return await repository.getActiveGame();
  }

  Future<void> processDart(DartThrow dart) async {
    final currentGame = state.value;
    if (currentGame == null) return;

    // Optimistic update
    final optimisticState = _applyDartOptimistically(currentGame, dart);
    state = AsyncValue.data(optimisticState);

    // Actual processing
    try {
      final useCase = ref.read(processDartUseCaseProvider);
      final newState = await useCase.execute(currentGame, dart);
      state = AsyncValue.data(newState);
    } catch (e, stack) {
      // Revert on error
      state = AsyncValue.data(currentGame);
      state = AsyncValue.error(e, stack);
    }
  }

  GameState _applyDartOptimistically(GameState game, DartThrow dart) {
    // Apply dart without database/validation
    // This is just for UI responsiveness
    return game.copyWith(
      dartsThrownInTurn: game.dartsThrownInTurn + 1,
      // ... other optimistic changes
    );
  }
}
```

---

### 7.3 Event Queue for Offline

Queue events when offline:

```dart
@riverpod
class GameEventQueue extends _$GameEventQueue {
  @override
  List<GameEvent> build() {
    return [];
  }

  void enqueue(GameEvent event) {
    state = [...state, event];
    _trySync();
  }

  Future<void> _trySync() async {
    if (!ref.read(isOnlineProvider)) return;
    
    final syncService = ref.read(syncServiceProvider);
    final eventsToSync = state;
    
    for (final event in eventsToSync) {
      try {
        await syncService.syncEvent(event);
        state = state.where((e) => e.eventId != event.eventId).toList();
      } catch (e) {
        // Will retry later
        break;
      }
    }
  }
}
```

---

## 8. Testing Patterns

### 8.1 Provider Testing

```dart
void main() {
  test('ActiveGame processes dart correctly', () async {
    // Create a container with overrides
    final container = ProviderContainer(
      overrides: [
        gameRepositoryProvider.overrideWithValue(mockRepository),
        processDartUseCaseProvider.overrideWithValue(mockUseCase),
      ],
    );

    // Wait for initial state
    await container.read(activeGameProvider.future);

    // Dispatch event
    final notifier = container.read(activeGameProvider.notifier);
    await notifier.processDart(testDart);

    // Verify state
    final state = container.read(activeGameProvider);
    expect(state.hasValue, true);
    expect(state.value?.dartsThrownInTurn, 1);

    container.dispose();
  });
}
```

---

### 8.2 Widget Testing with Providers

```dart
testWidgets('GameBoard displays current score', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeGameProvider.overrideWith(() => MockActiveGameNotifier()),
      ],
      child: const MaterialApp(
        home: GameBoardPage(),
      ),
    ),
  );

  await tester.pumpAndSettle();

  expect(find.text('501'), findsOneWidget);
  expect(find.text('Player 1'), findsOneWidget);
});
```

---

## 9. Common Patterns

### 9.1 Loading States

```dart
// Always handle all AsyncValue states
ref.watch(activeGameProvider).when(
  data: (game) => GameView(game: game),
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => ErrorView(error: error),
);

// Or use map for partial handling
final game = ref.watch(activeGameProvider).value;
if (game == null) {
  return const LoadingView();
}
return GameView(game: game);
```

---

### 9.2 Conditional UI

```dart
// Use state to drive UI
final setupState = ref.watch(gameSetupProvider);

return setupState.map(
  selectingType: (_) => GameTypeSelector(),
  configuringGame: (state) => GameConfigForm(config: state.config),
  selectingPlayers: (state) => PlayerSelector(
    available: state.availablePlayers,
    selected: state.selectedPlayers,
  ),
  formingTeams: (state) => TeamFormation(teams: state.teams),
  ready: (state) => StartGameButton(competitors: state.competitors),
);
```

---

### 9.3 Derived State

```dart
// Derive state from other providers
@riverpod
bool canStartGame(CanStartGameRef ref) {
  final setupState = ref.watch(gameSetupProvider);
  
  return setupState.maybeMap(
    ready: (_) => true,
    orElse: () => false,
  );
}

@riverpod
String currentPlayerName(CurrentPlayerNameRef ref) {
  final game = ref.watch(activeGameProvider).value;
  if (game == null) return '';
  
  final currentCompetitor = game.competitors[game.currentTurnIndex];
  final currentPlayerIndex = currentCompetitor.currentRotationIndex;
  final playerId = currentCompetitor.playerIds[currentPlayerIndex];
  
  final player = ref.watch(playerProvider(playerId)).value;
  return player?.name ?? '';
}
```

---

### 9.4 Side Effects

```dart
@riverpod
class ActiveGame extends _$ActiveGame {
  @override
  Future<GameState?> build() async {
    // Listen for game completion
    ref.listen(activeGameProvider, (previous, next) {
      next.whenData((game) {
        if (game != null && game.isComplete && !previous.value?.isComplete) {
          // Game just completed - trigger side effects
          _onGameCompleted(game);
        }
      });
    });
    
    return await _loadGame();
  }
  
  void _onGameCompleted(GameState game) {
    // Save statistics
    ref.read(statisticsServiceProvider).computeAndSave(game);
    
    // Clear active game
    ref.invalidateSelf();
    
    // Navigate to results
    // (via a callback or navigation service)
  }
}
```

---

## 10. Anti-Patterns to Avoid

### ❌ Don't: Mutate State Directly

```dart
// WRONG
state.value.competitors[0].score = 481;

// CORRECT
state = AsyncValue.data(
  state.value.copyWith(
    competitors: state.value.competitors.map((c) =>
      c.competitorId == targetId
        ? c.copyWith(score: 481)
        : c
    ).toList(),
  ),
);
```

---

### ❌ Don't: Read Providers in Build Methods

```dart
// WRONG
@override
Widget build(BuildContext context) {
  final notifier = ref.read(activeGameProvider.notifier);
  // ...
}

// CORRECT - use watch for state, read for methods
@override
Widget build(BuildContext context) {
  final game = ref.watch(activeGameProvider);
  
  return ElevatedButton(
    onPressed: () {
      // Read notifier only when dispatching
      ref.read(activeGameProvider.notifier).processDart(dart);
    },
  );
}
```

---

### ❌ Don't: Perform Side Effects in Provider Build

```dart
// WRONG
@override
GameState build() {
  // Side effects in build!
  ref.read(analyticsProvider).logEvent('game_started');
  return GameState.initial();
}

// CORRECT - use future or listener
@override
Future<GameState> build() async {
  ref.listen(activeGameProvider, (prev, next) {
    if (next.hasValue) {
      ref.read(analyticsProvider).logEvent('game_loaded');
    }
  });
  
  return await _loadGame();
}
```

---

### ❌ Don't: Create Circular Dependencies

```dart
// WRONG
@riverpod
int valueA(ValueARef ref) {
  return ref.watch(valueBProvider) + 1;
}

@riverpod
int valueB(ValueBRef ref) {
  return ref.watch(valueAProvider) + 1; // Circular!
}

// CORRECT - extract shared dependency
@riverpod
int baseValue(BaseValueRef ref) {
  return 10;
}

@riverpod
int valueA(ValueARef ref) {
  return ref.watch(baseValueProvider) + 1;
}

@riverpod
int valueB(ValueBRef ref) {
  return ref.watch(baseValueProvider) + 2;
}
```

---

## 11. Key State Providers for This App

### 11.1 Core Game State

```dart
@riverpod
class ActiveGame extends _$ActiveGame {
  // Current active game (if any)
}

@riverpod
class GameHistory extends _$GameHistory {
  // List of completed games
}

@riverpod
class GameSetup extends _$GameSetup {
  // Game configuration wizard
}
```

---

### 11.2 Player Management

```dart
@riverpod
Future<List<Player>> players(PlayersRef ref) async {
  // All players
}

@riverpod
Future<Player> player(PlayerRef ref, String playerId) async {
  // Single player by ID
}
```

---

### 11.3 Statistics

```dart
@riverpod
Future<PlayerStats> playerStats(
  PlayerStatsRef ref,
  String playerId,
) async {
  // Statistics for a player
}

@riverpod
Stream<GameStats> liveGameStats(
  LiveGameStatsRef ref,
  String gameId,
) {
  // Real-time statistics during game
}
```

---

### 11.4 Sync and Authentication

```dart
@riverpod
class SyncStatus extends _$SyncStatus {
  // Current sync state (REST API based)
}

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  // User authentication state
}
```

**Future Feature (Phase 2):**
```dart
// Note: Real-time multiplayer is a planned future feature
// These providers will be implemented when WebSocket support is added

@riverpod
class MultiplayerSession extends _$MultiplayerSession {
  // Active multiplayer session (WebSocket-based)
}

@riverpod
Stream<MultiplayerGameState> multiplayerGameStream(
  MultiplayerGameStreamRef ref,
  String sessionId,
) {
  // Real-time game state updates via WebSocket
}
```

---

### 11.5 UI State

```dart
final selectedSegmentProvider = StateProvider<int>((ref) => 20);

final selectedMultiplierProvider = StateProvider<int>((ref) => 1);

final showStatsOverlayProvider = StateProvider<bool>((ref) => false);

@riverpod
class DartInput extends _$DartInput {
  // Dart input state machine
}
```

---

## 12. Migration and Evolution

### 12.1 Adding New Features

When adding features:
1. Create feature-specific providers in feature folder
2. Use existing core providers as dependencies
3. Never create circular dependencies
4. Add tests for new providers
5. Document provider relationships

---

### 12.2 Refactoring Providers

When refactoring:
1. Use `.overrideWith()` in tests to ensure compatibility
2. Deprecate old providers before removing
3. Update all consumers before removing providers
4. Keep provider interfaces stable

---

## 13. Performance Considerations

### 13.1 Selective Rebuilds

```dart
// Only rebuild when specific field changes
final currentScore = ref.watch(
  activeGameProvider.select((state) => 
    state.value?.competitors[0].score
  ),
);

// This widget won't rebuild if other game state changes
```

---

### 13.2 Provider Families

```dart
@riverpod
Future<Player> player(PlayerRef ref, String playerId) async {
  // Each playerId gets its own provider instance
  final repository = ref.watch(playerRepositoryProvider);
  return await repository.getPlayer(playerId);
}

// Usage
final player1 = ref.watch(playerProvider('player-1'));
final player2 = ref.watch(playerProvider('player-2'));
```

---

### 13.3 Caching

```dart
@Riverpod(keepAlive: true)
class PlayersCache extends _$PlayersCache {
  final _cache = <String, Player>{};

  @override
  Future<Map<String, Player>> build() async {
    final repository = ref.watch(playerRepositoryProvider);
    final players = await repository.getAllPlayers();
    
    for (final player in players) {
      _cache[player.playerId] = player;
    }
    
    return Map.unmodifiable(_cache);
  }

  Player? getPlayer(String id) => _cache[id];
}
```

---

## 14. Summary

**State Management Stack:**
- **Riverpod** for state management
- **Freezed** for immutable state classes
- **Riverpod Generator** for code generation
- **AsyncValue** for async state
- **StreamProvider** for real-time data

**Key Principles:**
1. Immutable state with freezed
2. Clear provider hierarchy
3. No business logic in UI
4. Use AsyncValue for all async operations
5. Auto-dispose by default
6. Test with provider overrides
7. Derive state when possible
8. Handle all AsyncValue states

**Next Steps:**
1. Set up dependencies (riverpod, freezed, build_runner)
2. Create core providers (database, repositories)
3. Implement feature-specific providers
4. Add tests for critical providers
5. Document provider relationships

This architecture provides a solid foundation for the entire application while remaining flexible for future enhancements
