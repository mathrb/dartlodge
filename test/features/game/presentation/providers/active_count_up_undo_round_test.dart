// Regression: Count Up undo must preserve the round counter (#656).
//
// Count Up reuses the X01-shaped ProcessDartUseCase, which eagerly persists a
// TurnEnded when the 3rd dart ends the turn. ActiveCountUpNotifier._startNextTurn
// must therefore advance the turn with a TRANSIENT (non-persisted) TurnEnded —
// persisting a second one would put two TurnEnded per round boundary in the log,
// and a full replay (undo or cold-load) would double-advance currentRoundInLeg.
//
// Drives the real notifier over in-memory drift so the persisted event log is
// authoritative, then asserts an undo leaves the round where it should be.

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_count_up_provider.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

import '../../../../drift_test_base.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DriftTestBase base;
  late ProviderContainer container;

  setUp(() async {
    base = DriftTestBase();
    await base.setUp();
  });
  tearDown(() async {
    container.dispose();
    await base.tearDown();
  });

  Future<ActiveCountUpNotifier> seedAndLoad() async {
    final playerRepo = await base.createPlayerRepository();
    final gameRepo = await base.createGameRepository();
    final dartRepo = await base.createDartThrowRepository();
    final eventRepo = await base.createGameEventRepository();

    await playerRepo.createPlayer(Player(
        playerId: 'p1',
        name: 'P1',
        createdAt: DateTime(2025),
        lastActive: DateTime(2025)));

    await gameRepo.createGame(
      Game(
        gameId: 'cu',
        gameType: GameType.countUp,
        config: const GameConfig.countUp(totalRounds: 8),
        startTime: DateTime(2025),
        isComplete: false,
      ),
      const [
        Competitor(
            competitorId: 'c1',
            gameId: 'cu',
            type: CompetitorType.solo,
            name: 'P1',
            players: [CompetitorPlayer(playerId: 'p1', rotationPosition: 0)]),
      ],
    );
    await eventRepo.appendEvent(GameEvent(
      eventId: 'cu-ts0',
      gameId: 'cu',
      eventType: 'TurnStarted',
      localSequence: 1,
      occurredAt: DateTime(2025),
      payload: const {
        'competitor_id': 'c1',
        'player_id': 'p1',
        'starting_score': 0,
        'turn_index': 0,
        'leg_index': 0,
      },
      synced: false,
      actorId: 'system',
      source: EventSource.client,
    ));

    container = ProviderContainer(overrides: [
      gameRepositoryProvider.overrideWithValue(gameRepo),
      gameEventRepositoryProvider.overrideWithValue(eventRepo),
      dartThrowRepositoryProvider.overrideWithValue(dartRepo),
    ]);
    await container.read(activeCountUpProvider('cu').future);
    return container.read(activeCountUpProvider('cu').notifier);
  }

  test('undo of a round-2 dart keeps the round at 2 (single TurnEnded per round)',
      () async {
    final n = await seedAndLoad();
    final eventRepo = await base.createGameEventRepository();

    // Round 1: three T20s (=180), then advance to round 2.
    await n.processDart('T20');
    await n.processDart('T20');
    await n.processDart('T20');
    await n.advanceTurn();

    final r2 = container.read(activeCountUpProvider('cu')).value!.gameState;
    expect(r2.currentRoundInLeg, 2, reason: 'live round after advancing');

    // Exactly ONE TurnEnded should have been persisted for the round boundary
    // (the eager one from ProcessDartUseCase; _startNextTurn uses a transient).
    final log = await eventRepo.getEventsForGame('cu');
    expect(log.where((e) => e.eventType == 'TurnEnded').length, 1,
        reason: 'no duplicate TurnEnded per round boundary');

    // Round 2: one dart, then UNDO it.
    await n.processDart('T20');
    await n.undoDart();

    final afterUndo = container.read(activeCountUpProvider('cu')).value!.gameState;
    expect(afterUndo.currentRoundInLeg, 2,
        reason: 'undo must not double-advance the round (was 3 with a duplicate TurnEnded)');
    expect(afterUndo.competitors[0].score, 180);
    expect(afterUndo.dartsThrownInTurn, 0);
  });
}
