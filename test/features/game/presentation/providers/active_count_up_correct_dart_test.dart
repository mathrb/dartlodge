// Notifier-level coverage for count-up per-dart correction (#657): drives the
// real ActiveCountUpNotifier.correctTurnDart against in-memory drift repos
// (overriding the repository providers), exercising the on-demand
// index→eventId resolver and the full wired CorrectDartUseCase path.
//
// Count-up is the simplest correction case: purely additive scoring, no bust,
// single leg, and game completion only on TurnEnded — so a correction only ever
// rewrites the running total.

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
import 'package:dart_lodge/features/game/presentation/providers/active_count_up_provider.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

import '../../../../drift_test_base.dart';

/// Records `correctDart` so a test can assert the camera-only correction-capture
/// propagation (#658).
class _FakeCorrectionSink implements CaptureCorrectionSink {
  final List<({int cameraDartOrdinal, String segment})> corrections = [];
  @override
  void captureManualEntry({required String segment}) {}
  @override
  void correctDart({required int cameraDartOrdinal, required String segment}) =>
      corrections.add((cameraDartOrdinal: cameraDartOrdinal, segment: segment));
}

class _BoundCorrectionSink extends ActiveCaptureCorrectionSink {
  _BoundCorrectionSink(this._sink);
  final CaptureCorrectionSink _sink;
  @override
  CaptureCorrectionSink? build() => _sink;
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

  // Seeds a solo count-up game + an opening TurnStarted, builds a container that
  // routes the notifier through in-memory drift, and returns the loaded notifier.
  Future<ActiveCountUpNotifier> seedAndLoad(
      {CaptureCorrectionSink? sink}) async {
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
        gameType: GameType.countUp,
        config: const GameConfig.countUp(totalRounds: 8),
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
      payload: {
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
      if (sink != null)
        activeCaptureCorrectionSinkProvider
            .overrideWith(() => _BoundCorrectionSink(sink)),
    ]);
    await container.read(activeCountUpProvider('g1').future);
    return container.read(activeCountUpProvider('g1').notifier);
  }

  test('correctTurnDart replaces the resolved dart and recomputes the total',
      () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('20'); // dart 1
    await notifier.processDart('20'); // dart 2 → total 40
    expect(
        container.read(activeCountUpProvider('g1')).value!.gameState
            .competitors[0].score,
        40);

    await notifier.correctTurnDart(0, '5'); // first 20 → 5

    final gs = container.read(activeCountUpProvider('g1')).value!.gameState;
    expect(gs.competitors[0].score, 25); // 5 + 20
    expect(gs.dartsThrownInTurn, 2);
    final darts = gs.competitors[0].dartThrows;
    expect(darts.sublist(darts.length - 2), ['5', '20']);
  });

  test('correcting a mid-turn dart preserves the tail darts and total',
      () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('T20'); // 60
    await notifier.processDart('19'); // 79
    await notifier.processDart('T19'); // 136 — full 3-dart turn

    await notifier.correctTurnDart(1, 'T18'); // middle 19 → T18 (54)

    final gs = container.read(activeCountUpProvider('g1')).value!.gameState;
    expect(gs.competitors[0].score, 60 + 54 + 57); // 171
    expect(gs.dartsThrownInTurn, 3);
    final darts = gs.competitors[0].dartThrows;
    expect(darts.sublist(darts.length - 3), ['T20', 'T18', 'T19']);
  });

  test('correctTurnDart is a no-op for an out-of-range dart index', () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('20'); // only 1 dart this turn
    await notifier.correctTurnDart(2, '5'); // index 2 doesn't exist

    final gs = container.read(activeCountUpProvider('g1')).value!.gameState;
    expect(gs.competitors[0].score, 20); // unchanged
    expect(gs.dartsThrownInTurn, 1);
  });

  test('correcting a camera dart propagates correctDart to the capture (#658)',
      () async {
    final sink = _FakeCorrectionSink();
    final notifier = await seedAndLoad(sink: sink);

    await notifier.processDart('20', inputMethod: 'camera'); // camera dart 1
    await notifier.correctTurnDart(0, 'T20');

    // The 1-based camera ordinal re-labels the original captured frame.
    expect(sink.corrections, [(cameraDartOrdinal: 1, segment: 'T20')]);
  });

  test('correcting a manual dart does NOT propagate correctDart (#469/#658)',
      () async {
    final sink = _FakeCorrectionSink();
    final notifier = await seedAndLoad(sink: sink);

    await notifier.processDart('20'); // manual (default) → no camera capture
    await notifier.correctTurnDart(0, 'T20');

    // Manual darts have no camera ordinal, so no capture is touched.
    expect(sink.corrections, isEmpty);
  });
}
