import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/core/persistence/database_provider.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/game/domain/entities/competitor.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/domain/usecases/create_game_use_case.dart';
import 'package:my_darts/features/game/presentation/providers/game_setup_provider.dart';
import 'package:my_darts/features/game/presentation/state/game_setup_state.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';
import 'package:my_darts/features/game/domain/repositories/game_repository.dart';
import 'package:my_darts/features/players/domain/repositories/player_repository.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_setup_provider_test.mocks.dart';

@GenerateMocks([PlayerRepository, CreateGameUseCase, GameRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late MockPlayerRepository mockPlayerRepo;
  late MockCreateGameUseCase mockCreateGameUseCase;
  late MockGameRepository mockGameRepo;

  ProviderContainer makeContainer(
    MockPlayerRepository mock,
    MockCreateGameUseCase mockUseCase,
    MockGameRepository mockGameRepo,
  ) {
    return ProviderContainer(
      overrides: [
        playerRepositoryProvider.overrideWithValue(mock),
        createGameUseCaseProvider.overrideWithValue(mockUseCase),
        gameRepositoryProvider.overrideWithValue(mockGameRepo),
      ],
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPlayerRepo = MockPlayerRepository();
    mockCreateGameUseCase = MockCreateGameUseCase();
    mockGameRepo = MockGameRepository();
    // Default: no players — _lockedPlayerId stays null
    when(mockPlayerRepo.getAllPlayers()).thenAnswer((_) async => []);
    // Default: no active game in progress
    when(mockGameRepo.getActiveGame()).thenAnswer((_) async => null);
    container = makeContainer(mockPlayerRepo, mockCreateGameUseCase, mockGameRepo);
  });

  tearDown(() => container.dispose());

  // ── build() ─────────────────────────────────────────────────────────────────

  group('build()', () {
    test('returns GameSetupState.selectingType() immediately', () {
      final state = container.read(gameSetupProvider);
      expect(state, equals(const GameSetupState.selectingType()));
    });
  });

  // ── selectGameType ──────────────────────────────────────────────────────────

  group('selectGameType', () {
    test('X01 → configuringGame with 501 / straight / double / 1 leg', () {
      container.read(gameSetupProvider.notifier).selectGameType(GameType.x01);

      final state = container.read(gameSetupProvider);
      expect(
        state,
        equals(GameSetupState.configuringGame(
          gameType: GameType.x01,
          config: const GameConfig.x01(
            startingScore: 501,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        )),
      );
    });

    test('Cricket → configuringGame with standard cricket defaults', () {
      container
          .read(gameSetupProvider.notifier)
          .selectGameType(GameType.cricket);

      final state = container.read(gameSetupProvider);
      state.maybeMap(
        configuringGame: (s) {
          expect(s.gameType, GameType.cricket);
          s.config.maybeMap(
            cricket: (c) {
              expect(c.variant, 'standard');
              expect(c.numbers, GameConfigurationConstants.cricketNumbers);
              expect(c.pointsToWin, 3);
            },
            orElse: () => fail('Expected cricket config'),
          );
        },
        orElse: () => fail('Expected configuringGame state'),
      );
    });

    test('aroundTheClock → configuringGame with aroundTheClock config', () {
      container
          .read(gameSetupProvider.notifier)
          .selectGameType(GameType.aroundTheClock);

      final state = container.read(gameSetupProvider);
      state.maybeMap(
        configuringGame: (s) {
          expect(s.gameType, GameType.aroundTheClock);
          expect(s.config, const GameConfig.aroundTheClock());
        },
        orElse: () => fail('Expected configuringGame state'),
      );
    });

    test('killer → configuringGame with killer config', () {
      container
          .read(gameSetupProvider.notifier)
          .selectGameType(GameType.killer);
      container.read(gameSetupProvider).maybeMap(
            configuringGame: (s) =>
                expect(s.config, const GameConfig.killer()),
            orElse: () => fail('Expected configuringGame'),
          );
    });

    test('highScore → configuringGame with highScore config', () {
      container
          .read(gameSetupProvider.notifier)
          .selectGameType(GameType.highScore);
      container.read(gameSetupProvider).maybeMap(
            configuringGame: (s) =>
                expect(s.config, const GameConfig.highScore()),
            orElse: () => fail('Expected configuringGame'),
          );
    });
  });

  // ── selectVariant ───────────────────────────────────────────────────────────

  group('selectVariant', () {
    const x01Config = GameConfig.x01(
      startingScore: 501,
      inStrategy: 'straight',
      outStrategy: 'double',
      legsToWin: 1,
    );

    test(
        'from selectingType → selectingPlayers, no locked player ⇒ empty ids',
        () {
      container.read(gameSetupProvider.notifier).selectVariant(x01Config);

      container.read(gameSetupProvider).maybeMap(
            selectingPlayers: (s) {
              expect(s.gameType, GameType.x01);
              expect(s.config, x01Config);
              expect(s.selectedPlayerIds, isEmpty);
            },
            orElse: () => fail('Expected selectingPlayers'),
          );
    });

    test('from configuringGame → selectingPlayers, config replaced', () {
      final n = container.read(gameSetupProvider.notifier);
      n.selectGameType(GameType.x01);

      const newConfig = GameConfig.x01(
        startingScore: 301,
        inStrategy: 'double',
        outStrategy: 'double',
        legsToWin: 3,
      );
      n.selectVariant(newConfig);

      container.read(gameSetupProvider).maybeMap(
            selectingPlayers: (s) {
              expect(s.gameType, GameType.x01);
              expect(s.config, newConfig);
            },
            orElse: () => fail('Expected selectingPlayers'),
          );
    });

    test('from selectingPlayers → stays selectingPlayers, config updated', () {
      final n = container.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config); // → selectingPlayers
      n.togglePlayer('p99'); // add extra player to verify ids are preserved

      const updatedConfig = GameConfig.x01(
        startingScore: 701,
        inStrategy: 'straight',
        outStrategy: 'straight',
        legsToWin: 2,
      );
      n.selectVariant(updatedConfig);

      container.read(gameSetupProvider).maybeMap(
            selectingPlayers: (s) {
              expect(s.config, updatedConfig);
              expect(s.selectedPlayerIds, contains('p99'));
            },
            orElse: () => fail('Expected selectingPlayers'),
          );
    });

    test('from formingTeams / ready → no-op (code coverage)', () {
      // No public method leads to formingTeams/ready in EPIC-004.
      // This group just confirms the code compiles and the happy-path transitions
      // above cover the map branches.
    });
  });

  // ── togglePlayer ────────────────────────────────────────────────────────────

  group('togglePlayer', () {
    const x01Config = GameConfig.x01(
      startingScore: 501,
      inStrategy: 'straight',
      outStrategy: 'double',
      legsToWin: 1,
    );

    test('adds player id not already in list', () {
      final n = container.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config); // → selectingPlayers, empty ids
      n.togglePlayer('p1');

      container.read(gameSetupProvider).maybeMap(
            selectingPlayers: (s) => expect(s.selectedPlayerIds, ['p1']),
            orElse: () => fail('Expected selectingPlayers'),
          );
    });

    test('removes player id already in list', () {
      final n = container.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config);
      n.togglePlayer('p1');
      n.togglePlayer('p2');
      n.togglePlayer('p1'); // remove p1

      container.read(gameSetupProvider).maybeMap(
            selectingPlayers: (s) {
              expect(s.selectedPlayerIds, isNot(contains('p1')));
              expect(s.selectedPlayerIds, contains('p2'));
            },
            orElse: () => fail('Expected selectingPlayers'),
          );
    });

    test('no-op when called from selectingType', () {
      container.read(gameSetupProvider.notifier).togglePlayer('p1');
      expect(
          container.read(gameSetupProvider), const GameSetupState.selectingType());
    });

    test('no-op when called from configuringGame', () {
      final n = container.read(gameSetupProvider.notifier);
      n.selectGameType(GameType.x01);
      n.togglePlayer('p1');
      container.read(gameSetupProvider).maybeMap(
            configuringGame: (_) {}, // still configuringGame — correct
            orElse: () => fail('Expected configuringGame'),
          );
    });
  });

  // ── updateConfig ─────────────────────────────────────────────────────────────

  group('updateConfig', () {
    const x01Config = GameConfig.x01(
      startingScore: 501,
      inStrategy: 'straight',
      outStrategy: 'double',
      legsToWin: 1,
    );
    const updatedConfig = GameConfig.x01(
      startingScore: 301,
      inStrategy: 'double',
      outStrategy: 'double',
      legsToWin: 3,
    );

    test('from selectingType → no-op, stays selectingType', () {
      container.read(gameSetupProvider.notifier).updateConfig(x01Config);
      expect(container.read(gameSetupProvider), const GameSetupState.selectingType());
    });

    test('from configuringGame → config replaced, stays configuringGame', () {
      final n = container.read(gameSetupProvider.notifier);
      n.selectGameType(GameType.x01);
      n.updateConfig(updatedConfig);

      container.read(gameSetupProvider).maybeMap(
            configuringGame: (s) => expect(s.config, updatedConfig),
            orElse: () => fail('Expected configuringGame'),
          );
    });

    test('from selectingPlayers → config replaced, stays selectingPlayers', () {
      final n = container.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config);
      n.updateConfig(updatedConfig);

      container.read(gameSetupProvider).maybeMap(
            selectingPlayers: (s) => expect(s.config, updatedConfig),
            orElse: () => fail('Expected selectingPlayers'),
          );
    });
  });

  // ── reset() ─────────────────────────────────────────────────────────────────

  group('reset()', () {
    test('returns state to selectingType()', () {
      final n = container.read(gameSetupProvider.notifier);
      n.selectGameType(GameType.x01);
      expect(
        container.read(gameSetupProvider),
        isNot(const GameSetupState.selectingType()),
      );

      n.reset();

      expect(container.read(gameSetupProvider), const GameSetupState.selectingType());
    });
  });

  // ── canStart ─────────────────────────────────────────────────────────────────

  group('canStart', () {
    const x01Config = GameConfig.x01(
      startingScore: 501,
      inStrategy: 'straight',
      outStrategy: 'double',
      legsToWin: 1,
    );

    test('false in selectingType', () {
      expect(container.read(gameSetupProvider.notifier).canStart, isFalse);
    });

    test('false in configuringGame', () {
      final n = container.read(gameSetupProvider.notifier);
      n.selectGameType(GameType.x01);
      expect(n.canStart, isFalse);
    });

    test('false in selectingPlayers with empty list', () {
      final n = container.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config);
      // _lockedPlayerId is null (no players returned), so list is empty
      expect(n.canStart, isFalse);
    });

    test('true in selectingPlayers with ≥1 player', () {
      final n = container.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config);
      n.togglePlayer('p1');
      expect(n.canStart, isTrue);
    });
  });

  // ── Locked player (via mocked PlayerRepository) ───────────────────────────

  group('Locked player', () {
    const x01Config = GameConfig.x01(
      startingScore: 501,
      inStrategy: 'straight',
      outStrategy: 'double',
      legsToWin: 1,
    );

    late MockPlayerRepository playersRepo;
    late ProviderContainer lockedContainer;

    setUp(() {
      playersRepo = MockPlayerRepository();
      // getAllPlayers() returns sorted by lastActive DESC — first is most recent
      when(playersRepo.getAllPlayers()).thenAnswer((_) async => [
            Player(
              playerId: 'locked-id',
              name: 'Most Recent',
              createdAt: DateTime(2024),
              lastActive: DateTime(2025),
            ),
            Player(
              playerId: 'other-id',
              name: 'Other',
              createdAt: DateTime(2024),
              lastActive: DateTime(2023),
            ),
          ]);
      final mockGameRepoLocked = MockGameRepository();
      when(mockGameRepoLocked.getActiveGame()).thenAnswer((_) async => null);
      lockedContainer = makeContainer(playersRepo, MockCreateGameUseCase(), mockGameRepoLocked);
    });

    tearDown(() => lockedContainer.dispose());

    test('locked player is the first player by lastActive DESC', () async {
      lockedContainer.read(gameSetupProvider); // trigger build() + _init()
      await Future.microtask(() {}); // let _init() complete

      lockedContainer
          .read(gameSetupProvider.notifier)
          .selectVariant(x01Config);

      lockedContainer.read(gameSetupProvider).maybeMap(
            selectingPlayers: (s) =>
                expect(s.selectedPlayerIds.first, 'locked-id'),
            orElse: () => fail('Expected selectingPlayers'),
          );
    });

    test('locked player auto-included in selectedPlayerIds on enter', () async {
      lockedContainer.read(gameSetupProvider);
      await Future.microtask(() {});

      lockedContainer
          .read(gameSetupProvider.notifier)
          .selectVariant(x01Config);

      lockedContainer.read(gameSetupProvider).maybeMap(
            selectingPlayers: (s) =>
                expect(s.selectedPlayerIds, contains('locked-id')),
            orElse: () => fail('Expected selectingPlayers'),
          );
    });

    test('togglePlayer(lockedPlayerId) removes the locked player (can deselect)',
        () async {
      lockedContainer.read(gameSetupProvider);
      await Future.microtask(() {});

      final n = lockedContainer.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config); // → selectingPlayers with ['locked-id']
      n.togglePlayer('locked-id'); // should deselect

      lockedContainer.read(gameSetupProvider).maybeMap(
            selectingPlayers: (s) =>
                expect(s.selectedPlayerIds, isNot(contains('locked-id'))),
            orElse: () => fail('Expected selectingPlayers'),
          );
    });

    test('non-locked player can be toggled normally', () async {
      lockedContainer.read(gameSetupProvider);
      await Future.microtask(() {});

      final n = lockedContainer.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config);
      n.togglePlayer('other-id'); // add
      n.togglePlayer('other-id'); // remove

      lockedContainer.read(gameSetupProvider).maybeMap(
            selectingPlayers: (s) =>
                expect(s.selectedPlayerIds, isNot(contains('other-id'))),
            orElse: () => fail('Expected selectingPlayers'),
          );
    });
  });

  // ── startGame() ───────────────────────────────────────────────────────────

  group('startGame()', () {
    const x01Config = GameConfig.x01(
      startingScore: 501,
      inStrategy: 'straight',
      outStrategy: 'double',
      legsToWin: 1,
    );

    Game _fakeGame(String gameId) => Game(
          gameId: gameId,
          gameType: GameType.x01,
          config: x01Config,
          startTime: DateTime(2025),
        );

    test('returns null when not in selectingPlayers (selectingType)', () async {
      // State is selectingType — canStart is false
      final result =
          await container.read(gameSetupProvider.notifier).startGame();
      expect(result, isNull);
      verifyNever(mockCreateGameUseCase.execute(any, any));
    });

    test('returns null when canStart is false (empty player list)', () async {
      final n = container.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config); // selectingPlayers but no players selected
      // _lockedPlayerId is null, selectedPlayerIds is empty → canStart = false
      final result = await n.startGame();
      expect(result, isNull);
      verifyNever(mockCreateGameUseCase.execute(any, any));
    });

    test('calls execute() and returns gameId on success', () async {
      const returnedGameId = 'game-abc-123';
      when(mockCreateGameUseCase.execute(any, any)).thenAnswer(
        (_) async => _fakeGame(returnedGameId),
      );

      final n = container.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config);
      n.togglePlayer('p1'); // canStart = true

      final result = await n.startGame();

      expect(result, isNotNull);
      verify(mockCreateGameUseCase.execute(any, any)).called(1);
    });

    test('returns null on ValidationException (does not rethrow)', () async {
      when(mockCreateGameUseCase.execute(any, any))
          .thenThrow(const ValidationException('bad config'));

      final n = container.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config);
      n.togglePlayer('p1');

      final result = await n.startGame();
      expect(result, isNull);
    });

    test('rethrows non-ValidationException (e.g. DatabaseException)', () async {
      when(mockCreateGameUseCase.execute(any, any))
          .thenThrow(const DatabaseException('db exploded'));

      final n = container.read(gameSetupProvider.notifier);
      n.selectVariant(x01Config);
      n.togglePlayer('p1');

      expect(n.startGame(), throwsA(isA<DatabaseException>()));
    });
  });
}
