// Regression for #663 — resuming an in-progress multi-leg X01/Cricket match
// must not inflate the leg count.
//
// X01/Cricket engines fold the leg win into the deciding `DartThrown` (and the
// round-cap `TurnEnded`), while the use-case layer ALSO persists a separate
// `LegCompleted`/`GameCompleted`. Live play never re-applies those persisted
// events, but the cold-load replay (`replayEvents` → `loadedGameState`) does —
// so before the fix `_applyLegCompleted` incremented `legsWon`/`currentLegIndex`
// a SECOND time and a resumed match showed double the legs.
//
// These tests drive the REAL notifiers, capture the REAL persisted event log
// (the #664 lesson: hand-built logs can diverge from what the notifier actually
// writes), then cold-replay that log and assert it reproduces the live counts.
//
// The mocks are reused from `active_game_notifier_test.mocks.dart` to avoid a
// second generated file — `GameRepository`/`GameEventRepository`/
// `DartThrowRepository` are interface-generic.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/event_replay.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_cricket_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_x01_engine.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_cricket_game_provider.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_game_provider.dart';

import 'active_game_notifier_test.mocks.dart';

void main() {
  late ProviderContainer container;
  late MockGameRepository mockGameRepo;
  late MockGameEventRepository mockEventRepo;
  late MockDartThrowRepository mockDartRepo;

  // Captured live log + a monotonic sequence counter so each ProcessDart batch
  // appends after the previous one (the real getLatestSequence behaviour).
  late List<GameEvent> appended;
  late int latestSeq;

  List<Competitor> twoCompetitors() => [
        Competitor(
          competitorId: 'c1',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'Player 1',
          players: [CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
        ),
        Competitor(
          competitorId: 'c2',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'Player 2',
          players: [CompetitorPlayer(playerId: 'p2', rotationPosition: 1)],
        ),
      ];

  GameEvent turnStarted({
    String competitorId = 'c1',
    int turnIndex = 0,
    required int seq,
  }) =>
      GameEvent(
        eventId: 'e-turn-$seq',
        gameId: 'g1',
        eventType: 'TurnStarted',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {
          'competitor_id': competitorId,
          'turn_index': turnIndex,
          'leg_index': 0,
        },
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );

  GameEvent dartThrown({
    required String competitorId,
    required int segment,
    required int multiplier,
    required int seq,
  }) =>
      GameEvent(
        eventId: 'e-dart-$seq',
        gameId: 'g1',
        eventType: 'DartThrown',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {
          'competitor_id': competitorId,
          'segment': segment,
          'multiplier': multiplier,
          'input_method': 'manual',
        },
        synced: false,
        actorId: competitorId == 'c1' ? 'p1' : 'p2',
        source: EventSource.client,
      );

  /// Wires the mocks for [game]/[comps] with [buildEvents] as the persisted log
  /// at launch, capturing everything the notifier appends afterwards into
  /// [appended] while keeping sequence numbers monotonic.
  void wire({
    required Game game,
    required List<Competitor> comps,
    required List<GameEvent> buildEvents,
  }) {
    appended = [];
    latestSeq = buildEvents.isEmpty
        ? 0
        : buildEvents.map((e) => e.localSequence).reduce((a, b) => a > b ? a : b);

    mockGameRepo = MockGameRepository();
    mockEventRepo = MockGameEventRepository();
    mockDartRepo = MockDartThrowRepository();

    when(mockGameRepo.getGame('g1')).thenAnswer((_) async => game);
    when(mockGameRepo.getCompetitors('g1')).thenAnswer((_) async => comps);
    when(mockEventRepo.getEventsForGame('g1'))
        .thenAnswer((_) async => buildEvents);
    when(mockEventRepo.getLatestSequence(any)).thenAnswer((_) async => latestSeq);
    when(mockDartRepo.insertDart(any)).thenAnswer((_) async {});
    when(mockDartRepo.deleteDart(any)).thenAnswer((_) async {});
    when(mockEventRepo.appendEvent(any)).thenAnswer((inv) async {
      final e = inv.positionalArguments[0] as GameEvent;
      appended.add(e);
      if (e.localSequence > latestSeq) latestSeq = e.localSequence;
    });
    when(mockEventRepo.appendEvents(any)).thenAnswer((inv) async {
      final evs = (inv.positionalArguments[0] as List).cast<GameEvent>();
      appended.addAll(evs);
      for (final e in evs) {
        if (e.localSequence > latestSeq) latestSeq = e.localSequence;
      }
    });
    when(mockGameRepo.completeGame(
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    )).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        gameRepositoryProvider.overrideWithValue(mockGameRepo),
        gameEventRepositoryProvider.overrideWithValue(mockEventRepo),
        dartThrowRepositoryProvider.overrideWithValue(mockDartRepo),
      ],
    );
  }

  /// Cold-load replay of the full persisted log (build + captured), the state
  /// the app reconstructs on resume.
  GameState replayFull(
    Game game,
    List<Competitor> comps,
    List<GameEvent> buildEvents,
    GameEngine engine,
  ) {
    final all = [...buildEvents, ...appended]
      ..sort((a, b) => a.localSequence.compareTo(b.localSequence));
    return replayEvents(
      initial: GameState.initial(game, comps),
      events: all,
      engine: engine,
    );
  }

  int legsWonOf(GameState s, String competitorId) =>
      s.competitors.firstWhere((c) => c.competitorId == competitorId).legsWon;

  tearDown(() => container.dispose());

  Game x01Game({required int legsToWin, int? totalRounds}) => Game(
        gameId: 'g1',
        gameType: GameType.x01,
        config: GameConfig.x01(
          startingScore: 40,
          inStrategy: 'straight',
          outStrategy: 'double',
          legsToWin: legsToWin,
          totalRounds: totalRounds,
        ),
        startTime: DateTime(2025),
        isComplete: false,
      );

  test(
      'X01 checkout-decided leg: resumed leg count matches live (not doubled) #663',
      () async {
    final game = x01Game(legsToWin: 2);
    final comps = twoCompetitors();
    final build = [turnStarted(seq: 1)];
    wire(game: game, comps: comps, buildEvents: build);

    await container.read(activeGameProvider('g1').future);
    // D20 from 40 = exact double-out → c1 wins leg 1 (game continues, legsToWin 2).
    await container.read(activeGameProvider('g1').notifier).processDart('D20');

    final live = container.read(activeGameProvider('g1')).value!.gameState;
    expect(legsWonOf(live, 'c1'), 1, reason: 'live count after one leg');

    final replayed = replayFull(game, comps, build, StatelessX01Engine());
    expect(legsWonOf(replayed, 'c1'), legsWonOf(live, 'c1'),
        reason: 'resumed leg count must equal live (was 2 before #663 fix)');
    expect(replayed.currentLegIndex, live.currentLegIndex,
        reason: 'currentLegIndex must not double on resume');
  });

  test(
      'X01 round-cap-decided leg: resumed leg count matches live (not doubled) #663',
      () async {
    // totalRounds: 1 → the cap fires after round 1; lower remaining score wins.
    final game = x01Game(legsToWin: 2, totalRounds: 1);
    final comps = twoCompetitors();
    final build = [turnStarted(seq: 1)];
    wire(game: game, comps: comps, buildEvents: build);

    final notifier = container.read(activeGameProvider('g1').notifier);
    await container.read(activeGameProvider('g1').future);

    // Round 1, c1: 1 + 1 + 1 → 37 remaining (no checkout, no bust).
    await notifier.processDart('1');
    await notifier.processDart('1');
    await notifier.processDart('1');
    await notifier.advanceTurn();
    // Round 1, c2: three misses → stays at 40 (> c1's 37).
    await notifier.processDart('MISS');
    await notifier.processDart('MISS');
    await notifier.processDart('MISS');
    await notifier.advanceTurn(); // cap reached → c1 wins the leg on standing.

    final live = container.read(activeGameProvider('g1')).value!.gameState;
    expect(legsWonOf(live, 'c1'), 1, reason: 'cap winner has 1 leg live');

    final replayed = replayFull(game, comps, build, StatelessX01Engine());
    expect(legsWonOf(replayed, 'c1'), legsWonOf(live, 'c1'),
        reason: 'round-cap leg win must not double on resume');
  });

  // ── Cricket ────────────────────────────────────────────────────────────────

  Game cricketGame({required int legsToWin}) => Game(
        gameId: 'g1',
        gameType: GameType.cricket,
        config: GameConfig.cricket(
          scoring: 'standard',
          numbers: const ['15', '16', '17', '18', '19', '20', 'bull'],
          legsToWin: legsToWin,
        ),
        startTime: DateTime(2025),
        isComplete: false,
      );

  // 18 events leaving c1 with all 6 numbers closed and 2 Bull marks; the next
  // dart ('SB') closes the 3rd Bull mark → c1 wins the leg. Mirrors the helper
  // in active_cricket_game_notifier_test.dart.
  List<GameEvent> cricketNearComplete() {
    int seq = 0;
    GameEvent ts(String c, int ti) => turnStarted(competitorId: c, turnIndex: ti, seq: ++seq);
    GameEvent dt(String c, int s, int m) =>
        dartThrown(competitorId: c, segment: s, multiplier: m, seq: ++seq);
    return [
      ts('c1', 0), dt('c1', 20, 3), dt('c1', 19, 3), dt('c1', 18, 3),
      ts('c2', 1), dt('c2', 0, 1), dt('c2', 0, 1), dt('c2', 0, 1),
      ts('c1', 0), dt('c1', 17, 3), dt('c1', 16, 3), dt('c1', 15, 3),
      ts('c2', 1), dt('c2', 0, 1), dt('c2', 0, 1), dt('c2', 0, 1),
      ts('c1', 0), dt('c1', 25, 2), // DB = 2 Bull marks, turn still active
    ];
  }

  test(
      'Cricket checkout-decided leg: resumed leg count matches live (not doubled) #663',
      () async {
    final game = cricketGame(legsToWin: 2);
    final comps = twoCompetitors();
    final build = cricketNearComplete();
    wire(game: game, comps: comps, buildEvents: build);

    await container.read(activeCricketGameProvider('g1').future);
    // 3rd Bull mark closes the board → c1 wins leg 1 (game continues).
    await container.read(activeCricketGameProvider('g1').notifier).processDart('SB');

    final live = container.read(activeCricketGameProvider('g1')).value!.gameState;
    expect(legsWonOf(live, 'c1'), 1, reason: 'live count after one cricket leg');

    final replayed = replayFull(game, comps, build, StatelessCricketEngine());
    expect(legsWonOf(replayed, 'c1'), legsWonOf(live, 'c1'),
        reason: 'resumed cricket leg count must equal live (was 2 before #663 fix)');
    expect(replayed.currentLegIndex, live.currentLegIndex,
        reason: 'currentLegIndex must not double on resume');
  });
}
