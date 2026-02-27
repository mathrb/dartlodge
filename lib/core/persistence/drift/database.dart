// Drift Database Implementation
// IndexedDB-based database for web using drift

import 'package:drift/drift.dart';
import 'package:my_darts/core/utils/constants.dart';

part 'database.g.dart';

// Data classes for all tables
class Players extends Table {
  TextColumn get playerId => text()();
  TextColumn get name => text()();
  TextColumn get createdAt => text()();
  TextColumn get lastActive => text()();
  TextColumn get accountId => text().nullable()();
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

class Competitors extends Table {
  TextColumn get competitorId => text()();
  TextColumn get gameId => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {competitorId};
}

class CompetitorPlayers extends Table {
  TextColumn get competitorId => text()();
  TextColumn get playerId => text()();
  IntColumn get rotationPosition => integer()();

  @override
  Set<Column> get primaryKey => {competitorId, playerId};
}

class DartThrows extends Table {
  TextColumn get dartId => text()();
  TextColumn get gameId => text()();
  TextColumn get competitorId => text()();
  TextColumn get playerId => text()();
  IntColumn get turnNumber => integer()();
  IntColumn get dartNumber => integer()();
  TextColumn get segment => text()();
  IntColumn get score => integer()();
  RealColumn get x => real().nullable()();
  RealColumn get y => real().nullable()();

  @override
  Set<Column> get primaryKey => {dartId};
}

class GameEvents extends Table {
  TextColumn get eventId => text()();
  TextColumn get gameId => text()();
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

class GameSessions extends Table {
  TextColumn get sessionId => text()();
  TextColumn get gameId => text()();
  TextColumn get hostPlayerId => text()();
  TextColumn get status => text()();
  TextColumn get createdAt => text()();
  TextColumn get startedAt => text().nullable()();
  TextColumn get completedAt => text().nullable()();
  TextColumn get currentTurnPlayerId => text().nullable()();

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

  @override
  int get schemaVersion => DatabaseConstants.databaseVersion;

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
      beforeOpen: (OpeningDetails details) async {
        // Enable foreign key constraints for every connection
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }
}
