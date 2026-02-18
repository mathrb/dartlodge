// Database Implementation Tests
// Tests for the database layer implementation

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/core/persistence/persistence.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/game/domain/entities/competitor.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/core/error/repository_exception.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

// Fake path provider for testing
class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final directory = Directory.systemTemp.createTempSync('my_darts_test_');
    return directory.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return getApplicationDocumentsPath();
  }

  @override
  Future<String?> getDownloadsPath() async {
    return null;
  }

  @override
  Future<String?> getLibraryPath() async {
    return null;
  }

  @override
  Future<String?> getApplicationCachePath() async {
    return null;
  }

  Future<String?> getExternalStoragePath() async {
    return null;
  }

  Future<String?> getExternalCachePath() async {
    return null;
  }

  Future<String?> getExternalStorageDirectories({StorageDirectory? type}) async {
    return null;
  }

  Future<List<String>?> getApplicationCacheDirectories() async {
    return null;
  }

  Future<List<String>?> getApplicationSupportDirectories() async {
    return null;
  }

  Future<List<String>?> getExternalCacheDirectories() async {
    return null;
  }

  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Set up path provider for testing
  PathProviderPlatform.instance = FakePathProviderPlatform();

  late DatabaseHelper dbHelper;
  late PlayerRepositoryImpl playerRepo;
  late GameRepositoryImpl gameRepo;

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    playerRepo = PlayerRepositoryImpl(dbHelper);
    gameRepo = GameRepositoryImpl(dbHelper);
  });

  tearDown(() async {
    // Close the database after each test
    await dbHelper.close();
  });

  group('Database Initialization', () {
    test('Database should initialize successfully', () async {
      final db = await dbHelper.database;
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('All tables should be created', () async {
      final db = await dbHelper.database;
      
      // Check that all expected tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );
      
      final tableNames = tables.map((row) => row['name'] as String).toList();
      
      expect(tableNames, contains('players'));
      expect(tableNames, contains('games'));
      expect(tableNames, contains('competitors'));
      expect(tableNames, contains('competitor_players'));
      expect(tableNames, contains('dart_throws'));
      expect(tableNames, contains('game_events'));
    });
  });

  group('Player Repository', () {
    test('Should create and retrieve a player', () async {
      final player = Player(
        playerId: const Uuid().v4(),
        name: 'Test Player',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Create player
      await playerRepo.createPlayer(player);

      // Retrieve player
      final retrievedPlayer = await playerRepo.getPlayer(player.playerId);

      expect(retrievedPlayer, isNotNull);
      expect(retrievedPlayer?.name, equals(player.name));
    });

    test('Should throw exception for duplicate player name', () async {
      final player1 = Player(
        playerId: const Uuid().v4(),
        name: 'Duplicate Name',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      await playerRepo.createPlayer(player1);

      final player2 = Player(
        playerId: const Uuid().v4(),
        name: 'Duplicate Name', // Same name
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      expect(
        () => playerRepo.createPlayer(player2),
        throwsA(isA<DuplicatePlayerException>()),
      );
    });

    test('Should get all players', () async {
      // Create multiple players
      for (int i = 0; i < 3; i++) {
        final player = Player(
          playerId: const Uuid().v4(),
          name: 'Player $i',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
        await playerRepo.createPlayer(player);
      }

      final players = await playerRepo.getAllPlayers();

      expect(players.length, equals(3));
    });
  });

  group('Game Repository', () {
    test('Should create a game with competitors', () async {
      // Create players first
      final player1 = Player(
        playerId: const Uuid().v4(),
        name: 'Game Player 1',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final player2 = Player(
        playerId: const Uuid().v4(),
        name: 'Game Player 2',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      await playerRepo.createPlayer(player1);
      await playerRepo.createPlayer(player2);

      // Create game
      final game = Game(
        gameId: const Uuid().v4(),
        gameType: GameType.x01,
        config: {
          'starting_score': 501,
          'in_strategy': 'double',
          'out_strategy': 'double',
        },
        startTime: DateTime.now(),
        isComplete: false,
      );

      // Create competitors
      final competitors = [
        Competitor(
          competitorId: const Uuid().v4(),
          gameId: game.gameId,
          type: CompetitorType.solo,
          name: 'Player 1',
          players: [
            CompetitorPlayer(
              playerId: player1.playerId,
              rotationPosition: 0,
            )
          ],
        ),
        Competitor(
          competitorId: const Uuid().v4(),
          gameId: game.gameId,
          type: CompetitorType.solo,
          name: 'Player 2',
          players: [
            CompetitorPlayer(
              playerId: player2.playerId,
              rotationPosition: 0,
            )
          ],
        ),
      ];

      // Create game in database
      await gameRepo.createGame(game, competitors);

      // Retrieve game
      final retrievedGame = await gameRepo.getGame(game.gameId);
      expect(retrievedGame, isNotNull);
      expect(retrievedGame?.gameType, equals(GameType.x01));

      // Retrieve competitors
      final retrievedCompetitors = await gameRepo.getCompetitors(game.gameId);
      expect(retrievedCompetitors.length, equals(2));
    });

    test('Should throw exception for player in multiple competitors', () async {
      // Create a player
      final player = Player(
        playerId: const Uuid().v4(),
        name: 'Multi Competitor Player',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      await playerRepo.createPlayer(player);

      // Create game
      final game = Game(
        gameId: const Uuid().v4(),
        gameType: GameType.x01,
        config: {'starting_score': 501},
        startTime: DateTime.now(),
        isComplete: false,
      );

      // Create competitors where same player appears in both (invalid)
      final competitors = [
        Competitor(
          competitorId: const Uuid().v4(),
          gameId: game.gameId,
          type: CompetitorType.solo,
          name: 'Competitor 1',
          players: [
            CompetitorPlayer(
              playerId: player.playerId,
              rotationPosition: 0,
            )
          ],
        ),
        Competitor(
          competitorId: const Uuid().v4(),
          gameId: game.gameId,
          type: CompetitorType.solo,
          name: 'Competitor 2',
          players: [
            CompetitorPlayer(
              playerId: player.playerId, // Same player!
              rotationPosition: 0,
            )
          ],
        ),
      ];

      expect(
        () => gameRepo.createGame(game, competitors),
        throwsA(isA<InvalidCompetitorException>()),
      );
    });

    test('Should complete a game', () async {
      // Create a simple game
      final player = Player(
        playerId: const Uuid().v4(),
        name: 'Game Completion Player',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      await playerRepo.createPlayer(player);

      final game = Game(
        gameId: const Uuid().v4(),
        gameType: GameType.x01,
        config: {'starting_score': 301},
        startTime: DateTime.now(),
        isComplete: false,
      );

      final competitor = Competitor(
        competitorId: const Uuid().v4(),
        gameId: game.gameId,
        type: CompetitorType.solo,
        name: 'Solo Player',
        players: [
          CompetitorPlayer(
            playerId: player.playerId,
            rotationPosition: 0,
          )
        ],
      );

      await gameRepo.createGame(game, [competitor]);

      // Complete the game
      await gameRepo.completeGame(
        gameId: game.gameId,
        winnerCompetitorId: competitor.competitorId,
        endTime: DateTime.now(),
      );

      // Verify game is complete
      final completedGame = await gameRepo.getGame(game.gameId);
      expect(completedGame?.isComplete, isTrue);
      expect(completedGame?.winnerCompetitorId, equals(competitor.competitorId));
    });
  });

  group('Database Schema Validation', () {
    test('Players table should have correct schema', () async {
      final db = await dbHelper.database;
      
      // Get table info
      final tableInfo = await db.rawQuery(
        "PRAGMA table_info(players)"
      );

      final columns = tableInfo.map((row) => row['name'] as String).toList();
      
      expect(columns, contains('player_id'));
      expect(columns, contains('name'));
      expect(columns, contains('created_at'));
      expect(columns, contains('last_active'));
    });

    test('Games table should have correct schema', () async {
      final db = await dbHelper.database;
      
      final tableInfo = await db.rawQuery(
        "PRAGMA table_info(games)"
      );

      final columns = tableInfo.map((row) => row['name'] as String).toList();
      
      expect(columns, contains('game_id'));
      expect(columns, contains('game_type'));
      expect(columns, contains('config_json'));
      expect(columns, contains('start_time'));
      expect(columns, contains('end_time'));
      expect(columns, contains('winner_competitor_id'));
      expect(columns, contains('is_complete'));
      expect(columns, contains('game_state_json'));
    });
  });
}