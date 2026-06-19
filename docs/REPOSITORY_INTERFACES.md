# Repository Interface Contracts

**Status:** Authoritative  
**Scope:** Domain-layer repository interfaces — the contracts that separate business logic from storage  
**Derived from:** [DATA.md](docs/DATA.md), [DATABASE_DDL.md](docs/DATABASE_DDL.md), [STATE_MANAGEMENT.md](docs/STATE_MANAGEMENT.md), [statistics_architecture.md](docs/statistics_architecture.md), [GAME-EVENT-SPECIFICATIONS.md](docs/GAME-EVENT-SPECIFICATIONS.md)

---

## Overview

Repository interfaces are defined in the **domain layer** and are completely free of Flutter, SQLite, and HTTP imports. Concrete implementations live in each feature's `data/repositories/` folder and are wired at the dependency injection root (`main.dart`).

```
lib/
├── core/
│   └── persistence/
│       └── database_provider.dart      ← wires concrete impl at startup
├── features/
│   ├── players/
│   │   └── domain/
│   │       └── repositories/
│   │           └── player_repository.dart       ← interface (this doc)
│   │   └── data/
│   │       └── repositories/
│   │           └── player_repository_impl.dart  ← sqflite / drift impl
│   ├── game/
│   │   └── domain/repositories/
│   │       ├── game_repository.dart
│   │       └── game_event_repository.dart
│   │   └── data/repositories/
│   │       ├── game_repository_impl.dart
│   │       └── game_event_repository_impl.dart
│   └── statistics/
│       └── domain/repositories/
│           └── statistics_repository.dart
│       └── data/repositories/
│           └── statistics_repository_impl.dart
```

**Rules that must never be violated:**
- Interfaces import only plain Dart — no `sqflite`, `drift`, `http`, or Flutter
- Implementations never leak into use cases or notifiers
- All methods return `Future<T>` or `Stream<T>`; never raw synchronous results from I/O
- Errors surface as typed exceptions defined alongside the interface (see §6)

---

## Domain Model Types

These types are used across all interfaces. They are defined in the domain layer and shared by interfaces and use cases alike.

```dart
// lib/features/players/domain/entities/player.dart
class Player {
  final String playerId;   // UUID
  final String name;
  final DateTime createdAt;
  final DateTime lastActive;
}

// lib/features/game/domain/entities/game.dart
class Game {
  final String gameId;
  final GameType gameType;       // enum: x01, cricket, aroundTheClock, shanghai, catch40, bobs27, checkoutPractice, countUp
  final GameConfig config;       // sealed class — see DATA.md §7
  final DateTime startTime;
  final DateTime? endTime;
  final String? winnerCompetitorId;
  final bool isComplete;
  final GameStateSnapshot? activeState;  // null when complete
}

// lib/features/game/domain/entities/competitor.dart
class Competitor {
  final String competitorId;
  final String gameId;
  final CompetitorType type;     // enum: solo, team
  final String name;
  final List<CompetitorPlayer> players;
}

class CompetitorPlayer {
  final String playerId;
  final int rotationPosition;
}

// lib/features/game/domain/entities/dart_throw.dart
class DartThrow {
  final String dartId;
  final String gameId;
  final String competitorId;
  final String playerId;
  final int turnNumber;
  final int dartNumber;          // 1, 2, or 3
  final String segment;          // canonical: '20', 'T20', 'D20', 'SB', 'DB', 'MISS'
  final int score;
  final double? x;
  final double? y;
}

// lib/features/game/domain/entities/game_event.dart
class GameEvent {
  final String eventId;
  final String gameId;
  final String eventType;
  final int localSequence;
  final DateTime occurredAt;
  final Map<String, dynamic> payload;
  final bool synced;
  final String actorId;
  final int? globalSequence;
  final EventSource source;
}

// lib/features/statistics/domain/entities/player_stats.dart
class PlayerStats {
  final String playerId;
  final GameType gameType;
  final int totalGames;
  final int gamesWon;
  final double winRate;
  final double threeDartAverage;
  final double? checkoutPercentage;    // null for non-X01 games
  final int? highestCheckout;
  final int highestTurnScore;
  final int totalDartsThrown;
  final double dartsPerLeg;
  final double bustRate;               // 0.0–1.0
}

class GameStats {
  final String gameId;
  final List<CompetitorStats> byCompetitor;
}

class CompetitorStats {
  final String competitorId;
  final String competitorName;
  final List<PlayerTurnStats> byPlayer;
  final double threeDartAverage;
  final int legsWon;
  final int totalDartsThrown;
}

class PlayerTurnStats {
  final String playerId;
  final double threeDartAverage;
  final int dartsThrown;
}
```

---

## 1. PlayerRepository

**File:** `lib/features/players/domain/repositories/player_repository.dart`

Manages the `players` table. All write operations update `last_active` on the affected player.

```dart
abstract interface class PlayerRepository {

  /// Returns all players ordered by [last_active] descending.
  Future<List<Player>> getAllPlayers();

  /// Returns the player with [playerId], or null if not found.
  Future<Player?> getPlayer(String playerId);

  /// Inserts a new player. Throws [DuplicatePlayerException] if [player.playerId]
  /// already exists.
  Future<void> createPlayer(Player player);

  /// Updates [name] and [last_active] for the player with [playerId].
  /// Throws [PlayerNotFoundException] if the player does not exist.
  Future<void> updatePlayerName(String playerId, String name);

  /// Updates [last_active] to now for the player with [playerId].
  /// Throws [PlayerNotFoundException] if the player does not exist.
  Future<void> touchPlayer(String playerId);

  /// Emits the full player list whenever any player row changes.
  /// Used by player selection screens to stay reactive without polling.
  Stream<List<Player>> watchAllPlayers();
}
```

**Exceptions:**
```dart
class PlayerNotFoundException implements Exception {
  final String playerId;
}
class DuplicatePlayerException implements Exception {
  final String playerId;
}
```

---

## 2. GameRepository

**File:** `lib/features/game/domain/repositories/game_repository.dart`

Manages the `games`, `competitors`, and `competitor_players` tables together.
A game and its competitors are always written in a single transaction.

```dart
abstract interface class GameRepository {

  // ── Queries ──────────────────────────────────────────────────────────────

  /// Returns the single active (non-complete) game, or null if none exists.
  Future<Game?> getActiveGame();

  /// Returns the game with [gameId], including its competitors.
  /// Returns null if not found.
  Future<Game?> getGame(String gameId);

  /// Returns all completed games ordered by [end_time] descending.
  /// [limit] and [offset] support pagination.
  Future<List<Game>> getCompletedGames({
    int limit = 20,
    int offset = 0,
    GameType? filterByType,
  });

  /// Returns all competitors for [gameId], each with their player roster.
  Future<List<Competitor>> getCompetitors(String gameId);

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Inserts [game] and all of its [competitors] atomically.
  /// [competitors] must contain at least one entry.
  /// Throws [DuplicateGameException] if [game.gameId] already exists.
  /// Throws [InvalidCompetitorException] if a player appears in more than
  /// one competitor.
  Future<void> createGame(Game game, List<Competitor> competitors);

  /// Overwrites the [game_state_json] column for [gameId].
  /// Throws [GameNotFoundException] if [gameId] does not exist.
  /// Throws [GameAlreadyCompleteException] if the game is already marked complete.
  Future<void> saveGameState(String gameId, GameStateSnapshot state);

  /// Marks the game as complete: sets [is_complete = 1], [end_time],
  /// and [winner_competitor_id]. Clears [game_state_json].
  /// Throws [GameNotFoundException] if [gameId] does not exist.
  /// Throws [GameAlreadyCompleteException] if already complete.
  Future<void> completeGame({
    required String gameId,
    required String? winnerCompetitorId,
    required DateTime endTime,
  });

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Emits the active game (or null) whenever the active game row changes.
  Stream<Game?> watchActiveGame();

  /// Emits the completed games list whenever any game is completed.
  Stream<List<Game>> watchCompletedGames({GameType? filterByType});
}
```

**Exceptions:**
```dart
class GameNotFoundException implements Exception {
  final String gameId;
}
class DuplicateGameException implements Exception {
  final String gameId;
}
class GameAlreadyCompleteException implements Exception {
  final String gameId;
}
class InvalidCompetitorException implements Exception {
  final String reason;
}
```

---

## 3. DartThrowRepository

**File:** `lib/features/game/domain/repositories/dart_throw_repository.dart`

Manages the `dart_throws` table. Dart throws are immutable once inserted.

```dart
abstract interface class DartThrowRepository {

  // ── Queries ──────────────────────────────────────────────────────────────

  /// Returns all dart throws for [gameId] ordered by
  /// (turn_number ASC, dart_number ASC).
  Future<List<DartThrow>> getDartsForGame(String gameId);

  /// Returns all dart throws in [gameId] for [competitorId], ordered by
  /// (turn_number ASC, dart_number ASC).
  Future<List<DartThrow>> getDartsForCompetitor(
      String gameId, String competitorId);

  /// Returns all dart throws by [playerId] across all games, ordered by
  /// insertion time descending. Supports pagination.
  Future<List<DartThrow>> getDartsForPlayer(
    String playerId, {
    int limit = 100,
    int offset = 0,
  });

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Inserts a single dart throw.
  /// Throws [DuplicateDartException] if [dart.dartId] already exists.
  /// Throws [GameNotFoundException] if [dart.gameId] does not exist.
  /// Throws [GameAlreadyCompleteException] if the game is already complete.
  Future<void> insertDart(DartThrow dart);

  /// Inserts multiple dart throws in a single transaction.
  /// All-or-nothing: if any insert fails, none are committed.
  Future<void> insertDarts(List<DartThrow> darts);

  /// Deletes the dart throw with [dartId].
  /// Used exclusively by the undo mechanism — only the most recent dart
  /// in an active game may be deleted.
  /// Throws [DartNotFoundException] if [dartId] does not exist.
  /// Throws [GameAlreadyCompleteException] if the game is already complete.
  Future<void> deleteDart(String dartId);
}
```

**Exceptions:**
```dart
class DartNotFoundException implements Exception {
  final String dartId;
}
class DuplicateDartException implements Exception {
  final String dartId;
}
```

---

## 4. GameEventRepository

**File:** `lib/features/game/domain/repositories/game_event_repository.dart`

Manages the `game_events` table. Events are append-only; they are never updated
or deleted after insertion. Duplicate event IDs are silently ignored (idempotency).

```dart
abstract interface class GameEventRepository {

  // ── Queries ──────────────────────────────────────────────────────────────

  /// Returns all events for [gameId] ordered by [local_sequence] ascending.
  Future<List<GameEvent>> getEventsForGame(String gameId);

  /// Returns events for [gameId] with [local_sequence] greater than
  /// [afterSequence], ordered ascending. Used for incremental replay.
  Future<List<GameEvent>> getEventsSince(String gameId, int afterSequence);

  /// Returns all events that have not yet been confirmed by the backend
  /// ([synced = 0]), ordered by (game_id, local_sequence).
  Future<List<GameEvent>> getUnsyncedEvents();

  /// Returns the highest [local_sequence] for [gameId], or -1 if no events
  /// exist. Used to assign the next sequence number before insertion.
  Future<int> getLatestSequence(String gameId);

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Appends a single event. Silently ignores a duplicate [event.eventId].
  /// Throws [GameNotFoundException] if [event.gameId] does not exist.
  /// Throws [GameNotEditableException] if the target game is already complete
  /// (the event log is read-only after `completeGame`).
  /// Throws [SequenceConflictException] if [event.localSequence] is already
  /// taken by a different event ID for the same game.
  Future<void> appendEvent(GameEvent event);

  /// Appends multiple events in a single transaction. All-or-nothing.
  /// All events must share the same [gameId]; otherwise throws
  /// [ValidationException].
  /// Throws [GameNotFoundException] if the target game does not exist, or
  /// [GameNotEditableException] if the target game is already complete.
  /// Throws [SequenceConflictException] on any sequence collision (rolls back).
  Future<void> appendEvents(List<GameEvent> events);

  /// Marks [eventIds] as synced ([synced = 1]) inside a single transaction.
  /// Throws [EventNotFoundException] if any ID does not exist; on failure the
  /// transaction is rolled back so no partial updates land.
  Future<void> markSynced(List<String> eventIds);

  /// Updates the [global_sequence] for specific events after server confirmation,
  /// inside a single transaction. Throws [EventNotFoundException] if any ID
  /// does not exist; on failure the transaction is rolled back so no partial
  /// updates land.
  Future<void> updateGlobalSequences(Map<String, int> eventIdToSequence);

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Emits the full ordered event list for [gameId] whenever a new event
  /// is appended. Used for live game state reconstruction.
  Stream<List<GameEvent>> watchEventsForGame(String gameId);
}
```

**Exceptions:**
```dart
class SequenceConflictException implements Exception {
  final String gameId;
  final int localSequence;
}
class GameNotEditableException implements Exception {
  // Thrown by appendEvent/appendEvents when the target game is already complete.
}
class EventNotFoundException implements Exception {
  // Thrown by markSynced/updateGlobalSequences when any id does not exist;
  // the surrounding transaction is rolled back so no partial updates land.
}
class ValidationException implements Exception {
  // Thrown by appendEvents when events span multiple game ids in one batch.
}
```

---

## 5. StatisticsRepository

**File:** `lib/features/statistics/domain/repositories/statistics_repository.dart`

Statistics are **never stored** — they are always derived from `dart_throws` and
`game_events` on demand, per `statistics_architecture.md`. This repository
encapsulates those queries; it does not own any table.

```dart
abstract interface class StatisticsRepository {

  // ── Per-game ──────────────────────────────────────────────────────────────

  /// Computes and returns statistics for all competitors in [gameId].
  /// Throws [GameNotFoundException] if [gameId] does not exist.
  Future<GameStats> getGameStats(String gameId);

  /// Emits updated [GameStats] whenever a new dart throw is inserted for
  /// [gameId]. Used for live statistics during an active game.
  Stream<GameStats> watchGameStats(String gameId);

  // ── Per-player (career) ───────────────────────────────────────────────────

  /// Returns aggregated career statistics for [playerId] across completed
  /// games of [gameType].
  ///
  /// [gameType] is required: PPR-shaped fields (`threeDartAverage`,
  /// `bustRate`, score buckets) are X01-specific by definition, and cricket
  /// metrics (`marksPerTurn`, mark buckets) only apply to cricket.
  ///
  /// [from] and [to] are inclusive date-range filters applied to [start_time].
  /// Throws [PlayerNotFoundException] if [playerId] does not exist.
  Future<PlayerStats> getPlayerStats(
    String playerId, {
    required GameType gameType,
    DateTime? from,
    DateTime? to,
  });

  /// Returns statistics for [playerId] scoped to a single completed [gameId].
  /// Throws [GameNotFoundException] if [gameId] does not exist.
  /// Throws [PlayerNotFoundException] if [playerId] did not participate.
  Future<PlayerStats> getPlayerStatsForGame(String playerId, String gameId);

  /// Emits updated career [PlayerStats] whenever a game involving [playerId]
  /// is completed. Used to keep the statistics dashboard current.
  /// [gameType] is required for the same reasons as [getPlayerStats].
  Stream<PlayerStats> watchPlayerStats(String playerId,
      {required GameType gameType});

  // ── Heatmap ───────────────────────────────────────────────────────────────

  /// Returns the located dart positions thrown by [playerId] (for the impact
  /// heatmap), read directly from `dart_throws` — raw facts, not a computed
  /// stat. Only darts with non-NULL x/y from completed games are returned;
  /// optionally narrowed by [gameId], [gameType], and a [from]/[to] date
  /// window on the game's start time. Throws [PlayerNotFoundException] if
  /// [playerId] does not exist.
  Future<List<DartPosition>> getDartPositions({
    String? gameId,
    required String playerId,
    GameType? gameType,
    DateTime? from,
    DateTime? to,
  });

  // ── Leaderboard ───────────────────────────────────────────────────────────

  /// Returns all players ranked by [PlayerStats.threeDartAverage] descending
  /// for [gameType]. Excludes players with fewer than [minGames] games.
  Future<List<PlayerStats>> getLeaderboard({
    required GameType gameType,
    int minGames = 1,
    int limit = 50,
  });
}
```

---

## 6. AchievementRepository

**File:** `lib/features/achievements/domain/repositories/achievement_repository.dart`
**Drift impl:** `lib/core/persistence/drift/repositories/achievement_repository_drift.dart`
**Added:** #521/#522 (alongside the `unlocked_achievements` table, schema v2).

Persists which achievements a player has unlocked. An achievement is identified by
its catalogue slug (e.g. `'first_180'`); the *presence* of a record means
"unlocked" — there is no progress or notification state. Reads expose only the
set of unlocked ids (all the watcher / UI need). Stores a *fact*, not an
aggregate, so the "statistics are never stored" rule does not apply.

```dart
abstract interface class AchievementRepository {
  /// The set of achievement ids unlocked by [playerId] (empty if none).
  Future<Set<String>> getUnlocked(String playerId);

  /// Reactive variant of [getUnlocked] — re-emits when the set changes.
  Stream<Set<String>> watchUnlocked(String playerId);

  /// Record that [playerId] unlocked [id] at [at], optionally crediting the
  /// [gameId] that earned it. Idempotent: re-recording the same
  /// `(playerId, id)` is a no-op (the first unlock is kept). Failures →
  /// [RepositoryException] (an unknown player/game FK violation surfaces as
  /// [DatabaseException]).
  Future<void> recordUnlock(String playerId, String id, DateTime at,
      {String? gameId});
}
```

---

## 7. Exception Hierarchy

All repository exceptions extend a common base, making catch blocks predictable:

```dart
// lib/core/error/repository_exception.dart

sealed class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);
}

// ── Player ────────────────────────────────────────────────────────────────
final class PlayerNotFoundException extends RepositoryException {
  final String playerId;
  const PlayerNotFoundException(this.playerId)
      : super('Player not found: $playerId');
}

final class DuplicatePlayerException extends RepositoryException {
  final String playerId;
  const DuplicatePlayerException(this.playerId)
      : super('Player already exists: $playerId');
}

// ── Game ──────────────────────────────────────────────────────────────────
final class GameNotFoundException extends RepositoryException {
  final String gameId;
  const GameNotFoundException(this.gameId)
      : super('Game not found: $gameId');
}

final class DuplicateGameException extends RepositoryException {
  final String gameId;
  const DuplicateGameException(this.gameId)
      : super('Game already exists: $gameId');
}

final class GameAlreadyCompleteException extends RepositoryException {
  final String gameId;
  const GameAlreadyCompleteException(this.gameId)
      : super('Game is already complete: $gameId');
}

final class MultipleActiveGamesException extends RepositoryException {
  const MultipleActiveGamesException()
      : super('Multiple active games detected - only one game can be active at a time');
}

final class ActiveGameAlreadyExistsException extends RepositoryException {
  const ActiveGameAlreadyExistsException()
      : super('An active game already exists - only one game can be active at a time');
}

final class InvalidCompetitorException extends RepositoryException {
  const InvalidCompetitorException(super.reason);
}

// ── Dart throw ────────────────────────────────────────────────────────────
final class DartNotFoundException extends RepositoryException {
  final String dartId;
  const DartNotFoundException(this.dartId)
      : super('Dart throw not found: $dartId');
}

final class DuplicateDartException extends RepositoryException {
  final String dartId;
  const DuplicateDartException(this.dartId)
      : super('Dart throw already exists: $dartId');
}

// ── Event ─────────────────────────────────────────────────────────────────
final class SequenceConflictException extends RepositoryException {
  final String gameId;
  final int localSequence;
  const SequenceConflictException(this.gameId, this.localSequence)
      : super('Sequence $localSequence already taken in game $gameId');
}

final class GameNotEditableException extends RepositoryException {
  final String gameId;
  const GameNotEditableException(this.gameId)
      : super('Game is complete and not editable: $gameId');
}

final class EventNotFoundException extends RepositoryException {
  final String eventId;
  const EventNotFoundException(this.eventId)
      : super('Event not found: $eventId');
}

// ── Player ────────────────────────────────────────────────────────────────
final class PlayerHasGameHistoryException extends RepositoryException {
  const PlayerHasGameHistoryException(super.reason);
}

// ── Validation ────────────────────────────────────────────────────────────
final class ValidationException extends RepositoryException {
  const ValidationException(super.message);
}
```

---

## 8. Riverpod Provider Wiring

These providers live in `core/persistence/` and are the single place where
concrete implementations are selected per platform.

```dart
// lib/core/persistence/database_provider.dart

@Riverpod(keepAlive: true)
Future<AppDatabase> appDatabase(AppDatabaseRef ref) async {
  // AppDatabase is an abstract interface.
  // The concrete class is chosen at compile time via conditional imports
  // or a build-time flag.
  return await AppDatabaseFactory.create();
}

@Riverpod(keepAlive: true)
PlayerRepository playerRepository(PlayerRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return PlayerRepositoryImpl(db);  // sqflite on mobile, drift on web
}

@Riverpod(keepAlive: true)
GameRepository gameRepository(GameRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return GameRepositoryImpl(db);
}

@Riverpod(keepAlive: true)
DartThrowRepository dartThrowRepository(DartThrowRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return DartThrowRepositoryImpl(db);
}

@Riverpod(keepAlive: true)
GameEventRepository gameEventRepository(GameEventRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return GameEventRepositoryImpl(db);
}

@Riverpod(keepAlive: true)
StatisticsRepository statisticsRepository(StatisticsRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return StatisticsRepositoryImpl(db);
}

@Riverpod(keepAlive: true)
AchievementRepository achievementRepository(AchievementRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return AchievementRepositoryImpl(db);
}
```

All repositories are `keepAlive: true` — they are singletons for the
lifetime of the app and must never be auto-disposed.

---

## 9. Use Case → Repository Mapping

| Use Case | Repository/ies Used |
|---|---|
| `CreateGameUseCase` | `GameRepository`, `GameEventRepository` |
| `LoadGameUseCase` | `GameRepository`, `GameEventRepository` |
| `ProcessDartUseCase` | `DartThrowRepository`, `GameEventRepository`, `GameRepository` |
| `UndoLastDartUseCase` | `DartThrowRepository`, `GameEventRepository` |
| `CompleteGameUseCase` | `GameRepository`, `GameEventRepository`, `StatisticsRepository` |
| `GetPlayersUseCase` | `PlayerRepository` |
| `CreatePlayerUseCase` | `PlayerRepository` |
| `GetPlayerStatsUseCase` | `StatisticsRepository` |
| `GetGameHistoryUseCase` | `GameRepository` |
| `SyncEventsUseCase` | `GameEventRepository` |

---

## 10. Testing Contracts

Every concrete repository implementation must pass the same suite of interface
contract tests. This ensures the sqflite and drift implementations behave
identically.

```dart
// test/features/players/domain/player_repository_contract_test.dart

void runPlayerRepositoryContractTests(PlayerRepository Function() factory) {
  late PlayerRepository repo;

  setUp(() => repo = factory());

  test('getAllPlayers returns empty list when no players exist', () async {
    expect(await repo.getAllPlayers(), isEmpty);
  });

  test('createPlayer and getPlayer round-trip', () async {
    final player = Player(
      playerId: 'p1',
      name: 'Alice',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
    await repo.createPlayer(player);
    final retrieved = await repo.getPlayer('p1');
    expect(retrieved?.name, 'Alice');
  });

  test('createPlayer throws DuplicatePlayerException on duplicate id', () async {
    final player = Player(playerId: 'p1', name: 'Alice', ...);
    await repo.createPlayer(player);
    expect(
      () => repo.createPlayer(player.copyWith(name: 'Bob')),
      throwsA(isA<DuplicatePlayerException>()),
    );
  });

  test('getPlayer returns null for unknown id', () async {
    expect(await repo.getPlayer('unknown'), isNull);
  });

  test('updatePlayerName throws PlayerNotFoundException for unknown id', () async {
    expect(
      () => repo.updatePlayerName('unknown', 'Alice'),
      throwsA(isA<PlayerNotFoundException>()),
    );
  });

  test('watchAllPlayers emits updated list after createPlayer', () async {
    final stream = repo.watchAllPlayers();
    await repo.createPlayer(testPlayer);
    expect(
      stream,
      emitsInOrder([isEmpty, hasLength(1)]),
    );
  });
}

// Concrete test files simply call the shared suite:

// test/features/players/data/sqflite_player_repository_test.dart
void main() {
  runPlayerRepositoryContractTests(
    () => PlayerRepositoryImpl(inMemorySqfliteDatabase()),
  );
}

// test/features/players/data/drift_player_repository_test.dart
void main() {
  runPlayerRepositoryContractTests(
    () => PlayerRepositoryImpl(inMemoryDriftDatabase()),
  );
}
```

The same pattern applies to all five repositories. Shared contract test
functions live in `test/contracts/`.
