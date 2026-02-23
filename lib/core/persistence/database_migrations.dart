// Database Migrations
// Contains all schema creation and upgrade scripts

import 'package:sqflite/sqflite.dart';
import '../utils/constants.dart';

class DatabaseMigrations {
  static Future createVersion1(Database db) async {
    // Create players table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.playersTable} (
        player_id   TEXT    NOT NULL PRIMARY KEY,
        name        TEXT    NOT NULL,
        created_at  TEXT    NOT NULL,
        last_active TEXT    NOT NULL
      );
    ''');

    // Create games table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.gamesTable} (
        game_id               TEXT     NOT NULL PRIMARY KEY,
        game_type             TEXT     NOT NULL,
        config_json           TEXT     NOT NULL,
        start_time            TEXT     NOT NULL,
        end_time              TEXT,
        winner_competitor_id  TEXT,
        is_complete           INTEGER  NOT NULL DEFAULT 0,
        game_state_json       TEXT
      );
    ''');

    // Create competitors table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.competitorsTable} (
        competitor_id  TEXT  NOT NULL PRIMARY KEY,
        game_id        TEXT  NOT NULL REFERENCES ${DatabaseConstants.gamesTable}(game_id) ON DELETE CASCADE,
        type           TEXT  NOT NULL,
        name           TEXT  NOT NULL
      );
    ''');

    // Create index for competitors
    await db.execute('''
      CREATE INDEX idx_competitors_game_id ON ${DatabaseConstants.competitorsTable}(game_id);
    ''');

    // Create competitor_players table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.competitorPlayersTable} (
        competitor_id     TEXT     NOT NULL REFERENCES ${DatabaseConstants.competitorsTable}(competitor_id) ON DELETE CASCADE,
        player_id         TEXT     NOT NULL REFERENCES ${DatabaseConstants.playersTable}(player_id) ON DELETE RESTRICT,
        rotation_position INTEGER  NOT NULL,
        PRIMARY KEY (competitor_id, player_id)
      );
    ''');

    // Create index for competitor_players
    await db.execute('''
      CREATE INDEX idx_competitor_players_player_id ON ${DatabaseConstants.competitorPlayersTable}(player_id);
    ''');

    // Create dart_throws table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.dartThrowsTable} (
        dart_id        TEXT     NOT NULL PRIMARY KEY,
        game_id        TEXT     NOT NULL REFERENCES ${DatabaseConstants.gamesTable}(game_id) ON DELETE CASCADE,
        competitor_id  TEXT     NOT NULL REFERENCES ${DatabaseConstants.competitorsTable}(competitor_id) ON DELETE CASCADE,
        player_id      TEXT     NOT NULL REFERENCES ${DatabaseConstants.playersTable}(player_id) ON DELETE RESTRICT,
        turn_number    INTEGER  NOT NULL,
        dart_number    INTEGER  NOT NULL,
        segment        TEXT     NOT NULL,
        score          INTEGER  NOT NULL,
        x              REAL,
        y              REAL
      );
    ''');

    // Create indexes for dart_throws
    await db.execute('''
      CREATE INDEX idx_dart_throws_game_id ON ${DatabaseConstants.dartThrowsTable}(game_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_dart_throws_player_id ON ${DatabaseConstants.dartThrowsTable}(player_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_dart_throws_competitor_id ON ${DatabaseConstants.dartThrowsTable}(competitor_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_dart_throws_turn_order ON ${DatabaseConstants.dartThrowsTable}(game_id, turn_number, dart_number);
    ''');

    // Create game_events table (v1 - without actor_id, global_sequence, source)
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.gameEventsTable} (
        event_id        TEXT     NOT NULL PRIMARY KEY,
        game_id         TEXT     NOT NULL REFERENCES ${DatabaseConstants.gamesTable}(game_id) ON DELETE CASCADE,
        event_type      TEXT     NOT NULL,
        local_sequence  INTEGER  NOT NULL,
        occurred_at     TEXT     NOT NULL,
        payload_json    TEXT     NOT NULL,
        synced          INTEGER  NOT NULL DEFAULT 0,
        UNIQUE (game_id, local_sequence)
      );
    ''');

    // Create indexes for game_events
    await db.execute('''
      CREATE INDEX idx_game_events_game_id ON ${DatabaseConstants.gameEventsTable}(game_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_game_events_sequence ON ${DatabaseConstants.gameEventsTable}(game_id, local_sequence);
    ''');
  }

  static Future createVersion2Migration(Database db) async {
    // Add new columns to game_events table for version 2
    await db.execute('''
      ALTER TABLE ${DatabaseConstants.gameEventsTable} ADD COLUMN actor_id TEXT NOT NULL DEFAULT 'system';
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseConstants.gameEventsTable} ADD COLUMN global_sequence INTEGER;
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseConstants.gameEventsTable} ADD COLUMN source INTEGER NOT NULL DEFAULT 0;
    ''');
  }

  static Future createVersion2(Database db) async {
    // Add new columns to game_events table first
    await createVersion2Migration(db);
    
    // Create accounts table
    await db.execute('''
      CREATE TABLE accounts (
        account_id    TEXT NOT NULL PRIMARY KEY,
        email         TEXT NOT NULL UNIQUE,
        access_token  TEXT,
        refresh_token TEXT,
        backend_url   TEXT NOT NULL,
        created_at    TEXT NOT NULL,
        last_login_at TEXT
      );
    ''');

    // Add columns to players table
    await db.execute('''
      ALTER TABLE ${DatabaseConstants.playersTable} ADD COLUMN account_id TEXT;
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseConstants.playersTable} ADD COLUMN avatar_url TEXT;
    ''');

    // Create sync_queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        operation_id   TEXT     NOT NULL PRIMARY KEY,
        entity_type    TEXT     NOT NULL,
        entity_id      TEXT     NOT NULL,
        operation_type TEXT     NOT NULL,
        payload_json   TEXT     NOT NULL,
        status         TEXT     NOT NULL DEFAULT 'pending',
        attempt_count  INTEGER  NOT NULL DEFAULT 0,
        created_at     TEXT     NOT NULL,
        last_attempt   TEXT,
        error_message  TEXT
      );
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_status ON sync_queue(status);
    ''');

    // Create game_sessions table
    await db.execute('''
      CREATE TABLE game_sessions (
        session_id             TEXT NOT NULL PRIMARY KEY,
        game_id                TEXT NOT NULL REFERENCES ${DatabaseConstants.gamesTable}(game_id) ON DELETE CASCADE,
        host_player_id         TEXT NOT NULL REFERENCES ${DatabaseConstants.playersTable}(player_id) ON DELETE RESTRICT,
        status                 TEXT NOT NULL,
        created_at             TEXT NOT NULL,
        started_at             TEXT,
        completed_at           TEXT,
        current_turn_player_id TEXT REFERENCES ${DatabaseConstants.playersTable}(player_id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE INDEX idx_game_sessions_game_id ON game_sessions(game_id);
    ''');
  }

  static Future createVersion3(Database db) async {
    // Add unique partial index to ensure only one active game
    // This prevents multiple games from having is_complete = 0
    try {
      await db.execute('''
        CREATE UNIQUE INDEX idx_games_single_active
        ON ${DatabaseConstants.gamesTable}(is_complete)
        WHERE is_complete = 0;
      ''');
    } catch (e) {
      // Index may already exist or there may be existing data violations
      // For existing data violations, we'll handle them at the application level
      // rethrow if it's not a constraint violation
      if (!e.toString().contains('already exists') && 
          !e.toString().contains('UNIQUE constraint failed')) {
        rethrow;
      }
    }
  }

  static Future createLatestSchema(Database db) async {
    // Create players table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.playersTable} (
        player_id   TEXT    NOT NULL PRIMARY KEY,
        name        TEXT    NOT NULL,
        created_at  TEXT    NOT NULL,
        last_active TEXT    NOT NULL,
        account_id  TEXT,
        avatar_url  TEXT
      );
    ''');

    // Create games table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.gamesTable} (
        game_id               TEXT     NOT NULL PRIMARY KEY,
        game_type             TEXT     NOT NULL,
        config_json           TEXT     NOT NULL,
        start_time            TEXT     NOT NULL,
        end_time              TEXT,
        winner_competitor_id  TEXT,
        is_complete           INTEGER  NOT NULL DEFAULT 0,
        game_state_json       TEXT
      );
    ''');

    // Create unique partial index to ensure only one active game
    await db.execute('''
      CREATE UNIQUE INDEX idx_games_single_active
      ON ${DatabaseConstants.gamesTable}(is_complete)
      WHERE is_complete = 0;
    ''');

    // Create competitors table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.competitorsTable} (
        competitor_id  TEXT  NOT NULL PRIMARY KEY,
        game_id        TEXT  NOT NULL REFERENCES ${DatabaseConstants.gamesTable}(game_id) ON DELETE CASCADE,
        type           TEXT  NOT NULL,
        name           TEXT  NOT NULL
      );
    ''');

    // Create index for competitors
    await db.execute('''
      CREATE INDEX idx_competitors_game_id ON ${DatabaseConstants.competitorsTable}(game_id);
    ''');

    // Create competitor_players table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.competitorPlayersTable} (
        competitor_id     TEXT     NOT NULL REFERENCES ${DatabaseConstants.competitorsTable}(competitor_id) ON DELETE CASCADE,
        player_id         TEXT     NOT NULL REFERENCES ${DatabaseConstants.playersTable}(player_id) ON DELETE RESTRICT,
        rotation_position INTEGER  NOT NULL,
        PRIMARY KEY (competitor_id, player_id)
      );
    ''');

    // Create index for competitor_players
    await db.execute('''
      CREATE INDEX idx_competitor_players_player_id ON ${DatabaseConstants.competitorPlayersTable}(player_id);
    ''');

    // Create dart_throws table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.dartThrowsTable} (
        dart_id        TEXT     NOT NULL PRIMARY KEY,
        game_id        TEXT     NOT NULL REFERENCES ${DatabaseConstants.gamesTable}(game_id) ON DELETE CASCADE,
        competitor_id  TEXT     NOT NULL REFERENCES ${DatabaseConstants.competitorsTable}(competitor_id) ON DELETE CASCADE,
        player_id      TEXT     NOT NULL REFERENCES ${DatabaseConstants.playersTable}(player_id) ON DELETE RESTRICT,
        turn_number    INTEGER  NOT NULL,
        dart_number    INTEGER  NOT NULL,
        segment        TEXT     NOT NULL,
        score          INTEGER  NOT NULL,
        x              REAL,
        y              REAL
      );
    ''');

    // Create indexes for dart_throws
    await db.execute('''
      CREATE INDEX idx_dart_throws_game_id ON ${DatabaseConstants.dartThrowsTable}(game_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_dart_throws_player_id ON ${DatabaseConstants.dartThrowsTable}(player_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_dart_throws_competitor_id ON ${DatabaseConstants.dartThrowsTable}(competitor_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_dart_throws_turn_order ON ${DatabaseConstants.dartThrowsTable}(game_id, turn_number, dart_number);
    ''');

    // Create game_events table with all v2+ columns
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.gameEventsTable} (
        event_id        TEXT     NOT NULL PRIMARY KEY,
        game_id         TEXT     NOT NULL REFERENCES ${DatabaseConstants.gamesTable}(game_id) ON DELETE CASCADE,
        event_type      TEXT     NOT NULL,
        local_sequence  INTEGER  NOT NULL,
        occurred_at     TEXT     NOT NULL,
        payload_json    TEXT     NOT NULL,
        synced          INTEGER  NOT NULL DEFAULT 0,
        actor_id        TEXT     NOT NULL,
        global_sequence INTEGER,
        source          INTEGER  NOT NULL DEFAULT 0,
        UNIQUE (game_id, local_sequence)
      );
    ''');

    // Create indexes for game_events
    await db.execute('''
      CREATE INDEX idx_game_events_game_id ON ${DatabaseConstants.gameEventsTable}(game_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_game_events_sequence ON ${DatabaseConstants.gameEventsTable}(game_id, local_sequence);
    ''');

    // Create accounts table (v2)
    await db.execute('''
      CREATE TABLE accounts (
        account_id    TEXT NOT NULL PRIMARY KEY,
        email         TEXT NOT NULL UNIQUE,
        access_token  TEXT,
        refresh_token TEXT,
        backend_url   TEXT NOT NULL,
        created_at    TEXT NOT NULL,
        last_login_at TEXT
      );
    ''');

    // Create sync_queue table (v2)
    await db.execute('''
      CREATE TABLE sync_queue (
        operation_id   TEXT     NOT NULL PRIMARY KEY,
        entity_type    TEXT     NOT NULL,
        entity_id      TEXT     NOT NULL,
        operation_type TEXT     NOT NULL,
        payload_json   TEXT     NOT NULL,
        status         TEXT     NOT NULL DEFAULT 'pending',
        attempt_count  INTEGER  NOT NULL DEFAULT 0,
        created_at     TEXT     NOT NULL,
        last_attempt   TEXT,
        error_message  TEXT
      );
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_status ON sync_queue(status);
    ''');

    // Create game_sessions table (v2)
    await db.execute('''
      CREATE TABLE game_sessions (
        session_id             TEXT NOT NULL PRIMARY KEY,
        game_id                TEXT NOT NULL REFERENCES ${DatabaseConstants.gamesTable}(game_id) ON DELETE CASCADE,
        host_player_id         TEXT NOT NULL REFERENCES ${DatabaseConstants.playersTable}(player_id) ON DELETE RESTRICT,
        status                 TEXT NOT NULL,
        created_at             TEXT NOT NULL,
        started_at             TEXT,
        completed_at           TEXT,
        current_turn_player_id TEXT REFERENCES ${DatabaseConstants.playersTable}(player_id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE INDEX idx_game_sessions_game_id ON game_sessions(game_id);
    ''');
  }

  static Future createFullMigrationScript(Database db) async {
    // Use the latest schema for new installations
    await createLatestSchema(db);
  }
}