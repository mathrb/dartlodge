// Drift Database Implementation
// IndexedDB-based database for web using drift

import 'package:drift/drift.dart';

part 'database.g.dart';

// Data classes for all tables.
//
// Foreign keys here mirror the canonical schema in `database_migrations.dart`
// (sqflite). `winner_competitor_id` on `games` is intentionally NOT a FK —
// competitors are game-scoped and consistency is enforced by application logic.
class Players extends Table {
  TextColumn get playerId => text()();
  TextColumn get name => text()();
  TextColumn get createdAt => text()();
  TextColumn get lastActive => text()();
  TextColumn get accountId => text()
      .nullable()
      .references(Accounts, #accountId, onDelete: KeyAction.setNull)();
  TextColumn get avatarUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {playerId};
}

class Games extends Table {
  TextColumn get gameId => text()();
  TextColumn get gameType => text()();
  TextColumn get configJson => text()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text().nullable()();
  TextColumn get winnerCompetitorId => text().nullable()();
  IntColumn get isComplete => integer().withDefault(const Constant(0))();
  TextColumn get gameStateJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {gameId};
}

@TableIndex(name: 'idx_competitors_game_id', columns: {#gameId})
class Competitors extends Table {
  TextColumn get competitorId => text()();
  TextColumn get gameId =>
      text().references(Games, #gameId, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {competitorId};
}

@TableIndex(name: 'idx_competitor_players_player_id', columns: {#playerId})
class CompetitorPlayers extends Table {
  TextColumn get competitorId => text()
      .references(Competitors, #competitorId, onDelete: KeyAction.cascade)();
  TextColumn get playerId => text()
      .references(Players, #playerId, onDelete: KeyAction.restrict)();
  IntColumn get rotationPosition => integer()();

  @override
  Set<Column> get primaryKey => {competitorId, playerId};
}

@TableIndex(name: 'idx_dart_throws_game_id', columns: {#gameId})
@TableIndex(name: 'idx_dart_throws_player_id', columns: {#playerId})
@TableIndex(name: 'idx_dart_throws_competitor_id', columns: {#competitorId})
@TableIndex(
  name: 'idx_dart_throws_turn_order',
  columns: {#gameId, #turnNumber, #dartNumber},
)
class DartThrows extends Table {
  TextColumn get dartId => text()();
  TextColumn get gameId =>
      text().references(Games, #gameId, onDelete: KeyAction.cascade)();
  TextColumn get competitorId => text()
      .references(Competitors, #competitorId, onDelete: KeyAction.cascade)();
  TextColumn get playerId =>
      text().references(Players, #playerId, onDelete: KeyAction.restrict)();
  IntColumn get turnNumber => integer()();
  IntColumn get dartNumber => integer()();
  TextColumn get segment => text()();
  IntColumn get score => integer()();
  RealColumn get x => real().nullable()();
  RealColumn get y => real().nullable()();

  @override
  Set<Column> get primaryKey => {dartId};
}

@TableIndex(name: 'idx_game_events_game_id', columns: {#gameId})
@TableIndex(name: 'idx_game_events_sequence', columns: {#gameId, #localSequence})
class GameEvents extends Table {
  TextColumn get eventId => text()();
  TextColumn get gameId =>
      text().references(Games, #gameId, onDelete: KeyAction.cascade)();
  TextColumn get eventType => text()();
  IntColumn get localSequence => integer()();
  TextColumn get occurredAt => text()();
  TextColumn get payloadJson => text()();
  IntColumn get synced => integer().withDefault(const Constant(0))();
  TextColumn get actorId => text()();
  IntColumn get globalSequence => integer().nullable()();
  IntColumn get source => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {eventId};

  @override
  List<Set<Column>> get uniqueKeys => [
    {gameId, localSequence},
  ];
}

class Accounts extends Table {
  TextColumn get accountId => text()();
  TextColumn get email => text()();
  TextColumn get accessToken => text().nullable()();
  TextColumn get refreshToken => text().nullable()();
  TextColumn get backendUrl => text()();
  TextColumn get createdAt => text()();
  TextColumn get lastLoginAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {accountId};
}

@TableIndex(name: 'idx_sync_queue_status', columns: {#status})
class SyncQueue extends Table {
  TextColumn get operationId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operationType => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get lastAttempt => text().nullable()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {operationId};
}

@TableIndex(name: 'idx_game_sessions_game_id', columns: {#gameId})
class GameSessions extends Table {
  TextColumn get sessionId => text()();
  TextColumn get gameId =>
      text().references(Games, #gameId, onDelete: KeyAction.cascade)();
  @ReferenceName('hostedSessions')
  TextColumn get hostPlayerId =>
      text().references(Players, #playerId, onDelete: KeyAction.restrict)();
  TextColumn get status => text()();
  TextColumn get createdAt => text()();
  TextColumn get startedAt => text().nullable()();
  TextColumn get completedAt => text().nullable()();
  @ReferenceName('currentTurnSessions')
  TextColumn get currentTurnPlayerId => text()
      .nullable()
      .references(Players, #playerId, onDelete: KeyAction.setNull)();

  @override
  Set<Column> get primaryKey => {sessionId};
}

@DriftDatabase(
  tables: [
    Players,
    Games,
    Competitors,
    CompetitorPlayers,
    DartThrows,
    GameEvents,
    Accounts,
    SyncQueue,
    GameSessions,
  ],
  daos: [],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  // Drift schema version is decoupled from `DatabaseConstants.databaseVersion`
  // (sqflite) so we can evolve drift independently as we migrate the mobile
  // backend off sqflite. See issue #112.
  // v2: added secondary indexes (`@TableIndex` annotations) to mirror the
  //     sqflite DDL — `idx_competitors_game_id`, `idx_competitor_players_player_id`,
  //     `idx_dart_throws_{game_id,player_id,competitor_id,turn_order}`,
  //     `idx_game_events_{game_id,sequence}`, `idx_sync_queue_status`,
  //     `idx_game_sessions_game_id`.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // Enable foreign key constraints
        await m.database.customStatement('PRAGMA foreign_keys = ON;');

        await m.createAll();
        await m.database.customStatement(
          'CREATE UNIQUE INDEX idx_games_single_active ON games(is_complete) WHERE is_complete = 0;',
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Create secondary indexes that existed in sqflite but were missing
          // from drift v1. The generated `Index` objects live on the database
          // class itself (one per `@TableIndex` annotation).
          await m.createIndex(idxCompetitorsGameId);
          await m.createIndex(idxCompetitorPlayersPlayerId);
          await m.createIndex(idxDartThrowsGameId);
          await m.createIndex(idxDartThrowsPlayerId);
          await m.createIndex(idxDartThrowsCompetitorId);
          await m.createIndex(idxDartThrowsTurnOrder);
          await m.createIndex(idxGameEventsGameId);
          await m.createIndex(idxGameEventsSequence);
          await m.createIndex(idxSyncQueueStatus);
          await m.createIndex(idxGameSessionsGameId);
        }
      },
      beforeOpen: (OpeningDetails details) async {
        // Enable foreign key constraints for every connection
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      for (final stmt in const [
        'DELETE FROM sync_queue;',
        'DELETE FROM game_sessions;',
        'DELETE FROM dart_throws;',
        'DELETE FROM game_events;',
        'DELETE FROM competitor_players;',
        'DELETE FROM competitors;',
        'DELETE FROM games;',
        'DELETE FROM players;',
        'DELETE FROM accounts;',
      ]) {
        await customStatement(stmt);
      }
    });
  }
}
