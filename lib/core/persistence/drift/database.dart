// Drift Database Implementation
//
// Drift is the canonical persistence layer on every platform: mobile/desktop
// runs through `NativeDatabase.createInBackground`, web runs through
// `WasmDatabase` over IndexedDB. The table classes in this file are the single
// source of truth for the schema — see `docs/DATABASE_DDL.md` for the rendered
// SQL DDL reference and `CLAUDE.md` for the database rule.

import 'package:drift/drift.dart';
import 'package:dart_lodge/core/utils/constants.dart';

part 'database.g.dart';

// Data classes for all tables.
//
// `winner_competitor_id` on `games` is intentionally NOT a foreign key —
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

/// Per-player achievement unlock facts (#521/#522). One row per unlocked
/// achievement: the row's presence IS "unlocked" — no progress column, no
/// notification flag. `gameId` records the game that earned it (nullable, kept
/// when that game is deleted). Added in schema v2 (first migration).
class UnlockedAchievements extends Table {
  TextColumn get playerId =>
      text().references(Players, #playerId, onDelete: KeyAction.cascade)();
  TextColumn get achievementId => text()(); // catalogue slug, e.g. 'first_180'
  TextColumn get unlockedAt => text()(); // ISO 8601
  TextColumn get gameId =>
      text().nullable().references(Games, #gameId, onDelete: KeyAction.setNull)();

  @override
  Set<Column> get primaryKey => {playerId, achievementId};
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
    UnlockedAchievements,
  ],
  daos: [],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => DatabaseConstants.databaseVersion;

  // Migration history:
  //   v1 → v2 (#522): add `unlocked_achievements` (the project's first
  //   migration). Only a new table is added — no existing table is rebuilt — so
  //   no FK-disable dance is needed, and a `PRAGMA foreign_keys` toggle inside
  //   `onUpgrade` would be a no-op anyway (SQLite ignores it inside the
  //   migration transaction). Live-connection FK enforcement stays guaranteed by
  //   `beforeOpen`. Fresh installs get every table via `m.createAll()` in
  //   `onCreate`. Pre-1.0 caveat from #112 still applies: existing web installs
  //   may miss `@TableIndex` indexes until they clear site data.
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
          await m.createTable(unlockedAchievements);
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
