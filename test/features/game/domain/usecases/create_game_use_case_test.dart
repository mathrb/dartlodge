// CreateGameUseCase Unit Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/game/domain/usecases/create_game_use_case.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';

import 'create_game_use_case_test.mocks.dart';

@GenerateMocks([GameRepository, GameEventRepository, PlayerRepository])
void main() {
  late CreateGameUseCase useCase;
  late MockGameRepository mockGameRepo;
  late MockGameEventRepository mockEventRepo;
  late MockPlayerRepository mockPlayerRepo;

  // --- helpers ---

  Game _makeGame({
    int startingScore = 501,
    String inStrategy = 'straight',
    String outStrategy = 'double',
    int legsToWin = 1,
  }) =>
      Game(
        gameId: 'g1',
        gameType: GameType.x01,
        config: GameConfig.x01(
          startingScore: startingScore,
          inStrategy: inStrategy,
          outStrategy: outStrategy,
          legsToWin: legsToWin,
        ),
        startTime: DateTime.now(),
      );

  List<Competitor> _makeCompetitors({int count = 2}) => List.generate(
        count,
        (i) => Competitor(
          competitorId: 'c$i',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'Player $i',
          players: [CompetitorPlayer(playerId: 'p$i', rotationPosition: 0)],
        ),
      );

  setUp(() {
    mockGameRepo = MockGameRepository();
    mockEventRepo = MockGameEventRepository();
    mockPlayerRepo = MockPlayerRepository();
    useCase = CreateGameUseCase(mockGameRepo, mockEventRepo, mockPlayerRepo);

    when(mockGameRepo.createGame(any, any)).thenAnswer((_) async {});
    when(mockEventRepo.getLatestSequence(any)).thenAnswer((_) async => 0);
    when(mockEventRepo.appendEvent(any)).thenAnswer((_) async {});
    when(mockPlayerRepo.touchPlayer(any)).thenAnswer((_) async {});
  });

  // ── Happy path ────────────────────────────────────────────────────────────

  test('returns the game entity on success', () async {
    final game = _makeGame();
    final result = await useCase.execute(game, _makeCompetitors());
    expect(result.gameId, 'g1');
  });

  test('calls createGame before appending events', () async {
    final callOrder = <String>[];
    when(mockGameRepo.createGame(any, any)).thenAnswer((_) async {
      callOrder.add('createGame');
    });
    when(mockEventRepo.appendEvent(any)).thenAnswer((_) async {
      callOrder.add('appendEvent');
    });

    await useCase.execute(_makeGame(), _makeCompetitors());
    expect(callOrder.first, 'createGame');
  });

  test('appends exactly two events: GameCreated then TurnStarted', () async {
    final captured = <GameEvent>[];
    when(mockEventRepo.appendEvent(any)).thenAnswer((inv) async {
      captured.add(inv.positionalArguments[0] as GameEvent);
    });

    await useCase.execute(_makeGame(), _makeCompetitors());

    expect(captured, hasLength(2));
    expect(captured[0].eventType, 'GameCreated');
    expect(captured[1].eventType, 'TurnStarted');
  });

  test('GameCreated event has correct payload shape', () async {
    final captured = <GameEvent>[];
    when(mockEventRepo.appendEvent(any)).thenAnswer((inv) async {
      captured.add(inv.positionalArguments[0] as GameEvent);
    });

    final competitors = _makeCompetitors(count: 2);
    await useCase.execute(_makeGame(), competitors);

    final payload = captured[0].payload;
    expect(payload['ruleset'], 'X01');
    expect(payload['competitors'], containsAll(['c0', 'c1']));
    expect(payload.containsKey('rules_payload'), isTrue);
  });

  test('TurnStarted payload includes gameId, competitorId, turnIndex=0, legIndex=0', () async {
    final captured = <GameEvent>[];
    when(mockEventRepo.appendEvent(any)).thenAnswer((inv) async {
      captured.add(inv.positionalArguments[0] as GameEvent);
    });

    final competitors = _makeCompetitors(count: 2);
    await useCase.execute(_makeGame(), competitors);

    final payload = captured[1].payload;
    expect(payload['game_id'], 'g1');
    expect(payload['competitor_id'], 'c0'); // first competitor in list
    expect(payload['turn_index'], 0);
    expect(payload['leg_index'], 0);
  });

  test('events use ascending local_sequence starting after latest', () async {
    when(mockEventRepo.getLatestSequence(any)).thenAnswer((_) async => 4);

    final captured = <GameEvent>[];
    when(mockEventRepo.appendEvent(any)).thenAnswer((inv) async {
      captured.add(inv.positionalArguments[0] as GameEvent);
    });

    await useCase.execute(_makeGame(), _makeCompetitors());
    expect(captured[0].localSequence, 5);
    expect(captured[1].localSequence, 6);
  });

  test('first competitor in list gets the first turn', () async {
    final captured = <GameEvent>[];
    when(mockEventRepo.appendEvent(any)).thenAnswer((inv) async {
      captured.add(inv.positionalArguments[0] as GameEvent);
    });

    final competitors = [
      Competitor(
        competitorId: 'alice',
        gameId: 'g1',
        type: CompetitorType.solo,
        name: 'Alice',
        players: [const CompetitorPlayer(playerId: 'p0', rotationPosition: 0)],
      ),
      Competitor(
        competitorId: 'bob',
        gameId: 'g1',
        type: CompetitorType.solo,
        name: 'Bob',
        players: [const CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
      ),
    ];
    await useCase.execute(_makeGame(), competitors);
    expect(captured[1].payload['competitor_id'], 'alice');
  });

  test('practice game with single competitor is allowed', () async {
    await expectLater(
      useCase.execute(_makeGame(), _makeCompetitors(count: 1)),
      completes,
    );
  });

  // ── Validation: competitors ───────────────────────────────────────────────

  test('throws ValidationException when competitors list is empty', () async {
    expect(
      () => useCase.execute(_makeGame(), []),
      throwsA(isA<ValidationException>()),
    );
  });

  // ── Validation: startingScore ─────────────────────────────────────────────

  for (final valid in [101, 201, 301, 401, 501, 701, 1001]) {
    test('accepts valid startingScore $valid', () async {
      await expectLater(
        useCase.execute(_makeGame(startingScore: valid), _makeCompetitors()),
        completes,
      );
    });
  }

  test('throws ValidationException for invalid startingScore', () {
    expect(
      () => useCase.execute(_makeGame(startingScore: 999), _makeCompetitors()),
      throwsA(isA<ValidationException>()),
    );
  });

  // ── Validation: inStrategy / outStrategy ──────────────────────────────────

  for (final valid in ['straight', 'double', 'master']) {
    test('accepts valid inStrategy "$valid"', () async {
      await expectLater(
        useCase.execute(_makeGame(inStrategy: valid), _makeCompetitors()),
        completes,
      );
    });
  }

  test('throws ValidationException for invalid inStrategy', () {
    expect(
      () => useCase.execute(_makeGame(inStrategy: 'triple'), _makeCompetitors()),
      throwsA(isA<ValidationException>()),
    );
  });

  test('throws ValidationException for invalid outStrategy', () {
    expect(
      () => useCase.execute(_makeGame(outStrategy: 'bull'), _makeCompetitors()),
      throwsA(isA<ValidationException>()),
    );
  });

  // ── Validation: legsToWin ─────────────────────────────────────────────────

  test('accepts legsToWin = 1', () async {
    await expectLater(
      useCase.execute(_makeGame(legsToWin: 1), _makeCompetitors()),
      completes,
    );
  });

  test('accepts legsToWin > 1', () async {
    await expectLater(
      useCase.execute(_makeGame(legsToWin: 3), _makeCompetitors()),
      completes,
    );
  });

  test('throws ValidationException for legsToWin = 0', () {
    expect(
      () => useCase.execute(_makeGame(legsToWin: 0), _makeCompetitors()),
      throwsA(isA<ValidationException>()),
    );
  });

  test('throws ValidationException for negative legsToWin', () {
    expect(
      () => useCase.execute(_makeGame(legsToWin: -1), _makeCompetitors()),
      throwsA(isA<ValidationException>()),
    );
  });

  // ── Ensures ValidationException never leaks as raw Exception ─────────────

  test('thrown exception is always a RepositoryException', () {
    expect(
      () => useCase.execute(_makeGame(startingScore: 0), _makeCompetitors()),
      throwsA(isA<RepositoryException>()),
    );
  });

  // ── touchPlayer: participation marks last_active ─────────────────────────

  group('touchPlayer', () {
    test('calls touchPlayer exactly once per participating player', () async {
      await useCase.execute(_makeGame(), _makeCompetitors(count: 3));

      verify(mockPlayerRepo.touchPlayer('p0')).called(1);
      verify(mockPlayerRepo.touchPlayer('p1')).called(1);
      verify(mockPlayerRepo.touchPlayer('p2')).called(1);
      verifyNoMoreInteractions(mockPlayerRepo);
    });

    test('touches every player across team competitors', () async {
      final teamCompetitors = [
        const Competitor(
          competitorId: 'team-a',
          gameId: 'g1',
          type: CompetitorType.team,
          name: 'Team A',
          players: [
            CompetitorPlayer(playerId: 'a1', rotationPosition: 0),
            CompetitorPlayer(playerId: 'a2', rotationPosition: 1),
          ],
        ),
        const Competitor(
          competitorId: 'team-b',
          gameId: 'g1',
          type: CompetitorType.team,
          name: 'Team B',
          players: [
            CompetitorPlayer(playerId: 'b1', rotationPosition: 0),
            CompetitorPlayer(playerId: 'b2', rotationPosition: 1),
          ],
        ),
      ];

      await useCase.execute(_makeGame(), teamCompetitors);

      verify(mockPlayerRepo.touchPlayer('a1')).called(1);
      verify(mockPlayerRepo.touchPlayer('a2')).called(1);
      verify(mockPlayerRepo.touchPlayer('b1')).called(1);
      verify(mockPlayerRepo.touchPlayer('b2')).called(1);
    });

    test('PlayerNotFoundException during touch does not abort game creation',
        () async {
      when(mockPlayerRepo.touchPlayer('p0'))
          .thenThrow(PlayerNotFoundException('p0'));

      await expectLater(
        useCase.execute(_makeGame(), _makeCompetitors(count: 2)),
        completes,
      );

      verify(mockPlayerRepo.touchPlayer('p0')).called(1);
      verify(mockPlayerRepo.touchPlayer('p1')).called(1);
    });

    test('touchPlayer runs after game + events are persisted', () async {
      final callOrder = <String>[];
      when(mockGameRepo.createGame(any, any)).thenAnswer((_) async {
        callOrder.add('createGame');
      });
      when(mockEventRepo.appendEvent(any)).thenAnswer((_) async {
        callOrder.add('appendEvent');
      });
      when(mockPlayerRepo.touchPlayer(any)).thenAnswer((_) async {
        callOrder.add('touchPlayer');
      });

      await useCase.execute(_makeGame(), _makeCompetitors(count: 1));

      expect(callOrder.first, 'createGame');
      expect(callOrder.last, 'touchPlayer');
      expect(callOrder.indexOf('appendEvent'),
          lessThan(callOrder.indexOf('touchPlayer')));
    });
  });
}
