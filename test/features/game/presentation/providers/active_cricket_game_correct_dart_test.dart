// Notifier-level coverage for per-dart correction on Cricket (#393 PR5): drives
// the real ActiveCricketGameNotifier.correctTurnDart against in-memory drift
// repos, exercising the on-demand index→eventId resolver and the full wired
// CorrectCricketDart use-case path. Mirrors the X01 correction test, locking in
// the parity that already exists so auto-scored cricket darts stay correctable.

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

import 'package:dart_lodge/core/game/capture_correction_sink.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_cricket_game_provider.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

import '../../../../drift_test_base.dart';

class _FakeCorrectionSink implements CaptureCorrectionSink {
  final calls = <({int dartInTurnOrdinal, String segment})>[];
  @override
  void correctDart({required int dartInTurnOrdinal, required String segment}) =>
      calls.add((dartInTurnOrdinal: dartInTurnOrdinal, segment: segment));
}

void main() {
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

  // Seeds a solo standard cricket game + an opening TurnStarted, routes the
  // notifier through in-memory drift, and returns the loaded notifier.
  Future<ActiveCricketGameNotifier> seedAndLoad() async {
    final playerRepo = await base.createPlayerRepository();
    final gameRepo = await base.createGameRepository();
    final dartRepo = await base.createDartThrowRepository();
    final eventRepo = await base.createGameEventRepository();

    await playerRepo.createPlayer(Player(
        playerId: 'p1',
        name: 'P1',
        createdAt: DateTime.now(),
        lastActive: DateTime.now()));

    await gameRepo.createGame(
      Game(
        gameId: 'g1',
        gameType: GameType.cricket,
        config: GameConfig.cricket(
          scoring: 'standard',
          numbers: const ['15', '16', '17', '18', '19', '20', 'bull'],
          legsToWin: 1,
        ),
        startTime: DateTime.now(),
        isComplete: false,
      ),
      const [
        Competitor(
          competitorId: 'c1',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'P1',
          players: [CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
        ),
      ],
    );
    await eventRepo.appendEvent(GameEvent(
      eventId: 'g1-ts0',
      gameId: 'g1',
      eventType: 'TurnStarted',
      localSequence: 1,
      occurredAt: DateTime.now(),
      payload: const {
        'competitor_id': 'c1',
        'player_id': 'p1',
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
    await container.read(activeCricketGameProvider('g1').future);
    return container.read(activeCricketGameProvider('g1').notifier);
  }

  test('correctTurnDart re-targets the resolved dart and recomputes marks',
      () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('T20'); // dart 1 → 3 marks on 20
    await notifier.processDart('T19'); // dart 2 → 3 marks on 19
    final before = container.read(activeCricketGameProvider('g1')).value!;
    expect(before.gameState.competitors[0].marksPerNumber['20'], 3);
    expect(before.gameState.competitors[0].marksPerNumber['19'], 3);

    await notifier.correctTurnDart(0, 'T18'); // dart 1: T20 → T18

    final gs = container.read(activeCricketGameProvider('g1')).value!.gameState;
    expect(gs.competitors[0].marksPerNumber['20'], isNull); // re-targeted away
    expect(gs.competitors[0].marksPerNumber['18'], 3); // now closed
    expect(gs.competitors[0].marksPerNumber['19'], 3); // untouched
    expect(gs.dartsThrownInTurn, 2);
  });

  test('correctTurnDart to MISS clears the dart\'s marks but keeps the count',
      () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('T20'); // dart 1
    await notifier.processDart('T19'); // dart 2

    await notifier.correctTurnDart(0, 'MISS'); // dart 1: T20 → miss

    final gs = container.read(activeCricketGameProvider('g1')).value!.gameState;
    expect(gs.competitors[0].marksPerNumber['20'], isNull);
    expect(gs.competitors[0].marksPerNumber['19'], 3);
    expect(gs.dartsThrownInTurn, 2);
  });

  test('correctTurnDart is a no-op for an out-of-range dart index', () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('T20'); // only 1 dart this turn
    await notifier.correctTurnDart(2, 'T18'); // index 2 doesn't exist

    final gs = container.read(activeCricketGameProvider('g1')).value!.gameState;
    expect(gs.competitors[0].marksPerNumber['20'], 3); // unchanged
    expect(gs.competitors[0].marksPerNumber['18'], isNull);
    expect(gs.dartsThrownInTurn, 1);
  });

  test('correctTurnDart propagates the correction to the capture sink (#456)',
      () async {
    final notifier = await seedAndLoad();
    final sink = _FakeCorrectionSink();
    container.read(activeCaptureCorrectionSinkProvider.notifier).bind(sink);

    await notifier.processDart('T20'); // dart 1
    await notifier.processDart('T19'); // dart 2
    await notifier.correctTurnDart(0, 'T18'); // correct dart 1 (0-based index 0)

    expect(sink.calls, hasLength(1));
    expect(sink.calls.single.dartInTurnOrdinal, 1); // 1-based handle ordinal
    expect(sink.calls.single.segment, 'T18');
  });

  test('correctTurnDart does NOT propagate a no-op correction (#456)',
      () async {
    final notifier = await seedAndLoad();
    final sink = _FakeCorrectionSink();
    container.read(activeCaptureCorrectionSinkProvider.notifier).bind(sink);

    await notifier.processDart('T20'); // only 1 dart this turn
    await notifier.correctTurnDart(2, 'T18'); // index 2 out of range → early return

    expect(sink.calls, isEmpty);
  });
}
