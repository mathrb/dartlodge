// GetGameResultUseCase Unit Tests
//
// End-to-end via in-memory drift: seed players → competitors → game
// (isComplete: false) → events → completeGame, then execute the use case
// against the real practice/Shanghai engines and assert the resulting
// `GameResult` variant matches the expected field values.

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_around_the_clock_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_bobs_27_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_catch_40_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_checkout_practice_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_shanghai_engine.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/models/game_result.dart';
import 'package:dart_lodge/features/game/domain/usecases/game_use_case_helpers.dart';
import 'package:dart_lodge/features/game/domain/usecases/get_game_result_use_case.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

import '../../../../drift_test_base.dart';

void main() {
  final base = DriftTestBase();
  late GetGameResultUseCase useCase;

  setUp(() async {
    await base.setUp();
    useCase = GetGameResultUseCase(
      await base.createGameRepository(),
      await base.createGameEventRepository(),
      StatelessAroundTheClockEngine(),
      StatelessCatch40Engine(),
      StatelessBobs27Engine(),
      StatelessShanghaiEngine(),
      StatelessCheckoutPracticeEngine(),
    );
  });

  tearDown(() async {
    await base.tearDown();
  });

  Future<void> seedGame({
    required String gameId,
    required GameType gameType,
    required GameConfig config,
    required String playerId,
    required String playerName,
    required String competitorId,
  }) async {
    final playerRepo = await base.createPlayerRepository();
    final gameRepo = await base.createGameRepository();
    await playerRepo.createPlayer(Player(
      playerId: playerId,
      name: playerName,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    ));
    await gameRepo.createGame(
      Game(
        gameId: gameId,
        gameType: gameType,
        config: config,
        startTime: DateTime.now(),
        isComplete: false,
      ),
      [
        Competitor(
          competitorId: competitorId,
          gameId: gameId,
          type: CompetitorType.solo,
          name: playerName,
          players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
        ),
      ],
    );
  }

  /// Appends [events] and marks the game complete with [winnerCompetitorId].
  Future<void> completeWithEvents(
    String gameId,
    String? winnerCompetitorId,
    List<GameEvent> events,
  ) async {
    final gameRepo = await base.createGameRepository();
    await gameRepo.appendEventsAndCompleteGame(
      events: events,
      gameId: gameId,
      winnerCompetitorId: winnerCompetitorId,
      endTime: DateTime.now(),
    );
  }

  GameEvent dart(
    String gameId,
    String competitorId,
    String playerId,
    int seq,
    int segment,
    int multiplier,
  ) =>
      buildDartThrownEvent(
        gameId: gameId,
        dartId: 'dart-$gameId-$seq',
        competitorId: competitorId,
        actorId: playerId,
        localSequence: seq,
        segment: segment,
        multiplier: multiplier,
        score: segment * multiplier,
        playerId: playerId,
      );

  group('GetGameResultUseCase', () {
    test('returns null for an unknown gameId', () async {
      final result = await useCase.execute('does-not-exist');
      expect(result, isNull);
    });

    test('returns null for an X01 game (not a covered type)', () async {
      await seedGame(
        gameId: 'g-x01',
        gameType: GameType.x01,
        config: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'straight',
          outStrategy: 'double',
        ),
        playerId: 'p1',
        playerName: 'P1',
        competitorId: 'c1',
      );
      final result = await useCase.execute('g-x01');
      expect(result, isNull);
    });

    test('aroundTheClock: solo player, standard variant, 5 turns to win',
        (() async {
      const gameId = 'g-atc';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.aroundTheClock,
        config: const GameConfig.aroundTheClock(),
        playerId: playerId,
        playerName: 'Alice',
        competitorId: competitorId,
      );

      // 4 full turns of 3 darts each (12 darts hitting targets 1..12),
      // then turn 5: hits 13..20 across 9 more darts — but ATC wins
      // on the dart that clears target 20. To keep this compact: scripted
      // sequence that progresses target 1 → 20 with no misses.
      // Layout: turn N covers targets (3N-2)..(3N). Final turn 7 hits 19, 20
      // and wins on dart 2.

      final events = <GameEvent>[];
      var seq = 1;
      var target = 1;
      for (var turn = 1; turn <= 7; turn++) {
        events.add(buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ));
        // Three darts per turn, each hits the current target unless we've
        // already cleared 20.
        for (var d = 0; d < 3 && target <= 20; d++) {
          events.add(dart(gameId, competitorId, playerId, seq++, target, 1));
          target++;
          if (target > 20) break;
        }
        if (target > 20) break;
        events.add(buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
        ));
      }
      events.add(buildGameCompletedEvent(
        gameId: gameId,
        winnerCompetitorId: competitorId,
        localSequence: seq++,
      ));

      await completeWithEvents(gameId, competitorId, events);

      final result = await useCase.execute(gameId);
      expect(result, isA<AroundTheClockResult>());
      final atc = result as AroundTheClockResult;
      expect(atc.competitors, hasLength(1));
      final alice = atc.competitors.single;
      expect(alice.competitorName, 'Alice');
      // 7 turns scripted, win happens on turn 7 (no TurnEnded after) →
      // practiceRound = 7.
      expect(alice.turnsCompleted, 7);
      // 6 prior turns × 3 darts + 2 winning darts in turn 7 = 20.
      expect(alice.totalDarts, 20);
      expect(alice.finished, isTrue);
      expect(atc.winnerCompetitorId, competitorId);
      expect(atc.doublesOnly, isFalse);
    }));

    test(
        'aroundTheClock: multi-player result lists ALL competitors with the '
        'winner ordered first (#279)',
        (() async {
      // 3 competitors. Alice finishes the sequence (1..20); Bob and Carol
      // start playing but don't finish before Alice wins. Pre-#279 the
      // result discarded Bob/Carol; post-fix `competitors` carries all 3,
      // and `winnerCompetitorId` identifies Alice.
      const gameId = 'g-atc-multi';
      final playerRepo = await base.createPlayerRepository();
      final gameRepo = await base.createGameRepository();
      for (final p in [
        ('p1', 'Alice'),
        ('p2', 'Bob'),
        ('p3', 'Carol'),
      ]) {
        await playerRepo.createPlayer(Player(
          playerId: p.$1,
          name: p.$2,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        ));
      }
      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.aroundTheClock,
          config: const GameConfig.aroundTheClock(),
          startTime: DateTime.now(),
          isComplete: false,
        ),
        const [
          Competitor(
            competitorId: 'c1',
            gameId: gameId,
            type: CompetitorType.solo,
            name: 'Alice',
            players: [CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
          ),
          Competitor(
            competitorId: 'c2',
            gameId: gameId,
            type: CompetitorType.solo,
            name: 'Bob',
            players: [CompetitorPlayer(playerId: 'p2', rotationPosition: 0)],
          ),
          Competitor(
            competitorId: 'c3',
            gameId: gameId,
            type: CompetitorType.solo,
            name: 'Carol',
            players: [CompetitorPlayer(playerId: 'p3', rotationPosition: 0)],
          ),
        ],
      );

      // Build a deterministic event log that has Alice finishing first.
      // Each "turn" is TurnStarted + 3 DartThrown + TurnEnded for one player
      // and rotates Alice → Bob → Carol. Alice hits her target every dart
      // (so she finishes the sequence after exactly 20 darts ≈ 7 turns);
      // Bob hits the first 5 targets then misses; Carol misses every dart.
      int seq = 1;
      final events = <GameEvent>[];
      final rotation = [
        ('c1', 'p1'),
        ('c2', 'p2'),
        ('c3', 'p3'),
      ];
      int aliceTarget = 1;
      int bobTarget = 1;
      // Run up to 10 rounds; Alice should finish before that with 20 hits
      // across 7 turns of 3 darts.
      for (int round = 0; round < 10; round++) {
        for (final (compId, playerId) in rotation) {
          events.add(buildTurnStartedEvent(
            gameId: gameId,
            competitorId: compId,
            playerId: playerId,
            localSequence: seq++,
            turnIndex: round,
            legIndex: 0,
          ));
          for (int d = 0; d < 3; d++) {
            int segment;
            if (compId == 'c1' && aliceTarget <= 20) {
              segment = aliceTarget;
              aliceTarget++;
            } else if (compId == 'c2' && bobTarget <= 5) {
              segment = bobTarget;
              bobTarget++;
            } else {
              segment = 0; // miss
            }
            events.add(dart(gameId, compId, playerId, seq++, segment, 1));
            if (compId == 'c1' && aliceTarget > 20) {
              // Alice has finished — engine ends the game on this dart.
              break;
            }
          }
          if (aliceTarget > 20) break;
          events.add(buildTurnEndedEvent(
            gameId: gameId,
            competitorId: compId,
            playerId: playerId,
            localSequence: seq++,
          ));
        }
        if (aliceTarget > 20) break;
      }
      events.add(buildGameCompletedEvent(
        gameId: gameId,
        winnerCompetitorId: 'c1',
        localSequence: seq++,
      ));

      await completeWithEvents(gameId, 'c1', events);

      final result = await useCase.execute(gameId);
      expect(result, isA<AroundTheClockResult>());
      final atc = result as AroundTheClockResult;
      expect(atc.winnerCompetitorId, 'c1');
      expect(atc.competitors, hasLength(3),
          reason: 'all 3 competitors must appear in the result, not just Alice');
      // Ranking: winner first (Alice), then non-finishers ordered by
      // highest target reached descending — Bob (5) above Carol (0).
      expect(atc.competitors.first.competitorName, 'Alice');
      expect(atc.competitors.first.finished, isTrue);
      expect(atc.competitors[1].competitorName, 'Bob');
      expect(atc.competitors[1].finished, isFalse);
      expect(atc.competitors[1].lastTargetHit, 5);
      expect(atc.competitors[2].competitorName, 'Carol');
      expect(atc.competitors[2].lastTargetHit, 0);
    }));

    test(
        'aroundTheClock: reverse variant with no hits yields lastTargetHit=0 '
        '(not the 21 sentinel)',
        (() async {
      const gameId = 'g-atc-rev';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.aroundTheClock,
        config: const GameConfig.aroundTheClock(variant: 'reverse'),
        playerId: playerId,
        playerName: 'Alice',
        competitorId: competitorId,
      );
      // One turn of 3 misses, then End Game (engine doesn't emit
      // LegCompleted for a 1-leg practice game).
      final events = <GameEvent>[
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 1,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, 2, 0, 1),
        dart(gameId, competitorId, playerId, 3, 0, 1),
        dart(gameId, competitorId, playerId, 4, 0, 1),
        buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 5,
        ),
        buildGameCompletedEvent(
          gameId: gameId,
          winnerCompetitorId: null,
          localSequence: 6,
        ),
      ];
      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId) as AroundTheClockResult;
      final alice = result.competitors.single;
      expect(alice.finished, isFalse);
      // Reverse variant starts at target 20 with no hits → lastTargetHit
      // must be 0 (display as "no hits"), NOT 21 (invalid ATC target).
      expect(alice.lastTargetHit, 0);
    }));

    test('aroundTheClock: doublesOnly variant flag reaches the result',
        (() async {
      const gameId = 'g-atc-do';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.aroundTheClock,
        config: const GameConfig.aroundTheClock(variant: 'doublesOnly'),
        playerId: playerId,
        playerName: 'Alice',
        competitorId: competitorId,
      );
      // Just send GameCompleted (we only assert the variant flag).
      await completeWithEvents(gameId, null, [
        buildGameCompletedEvent(
          gameId: gameId,
          winnerCompetitorId: null,
          localSequence: 1,
        ),
      ]);
      final result = await useCase.execute(gameId);
      expect(result, isA<AroundTheClockResult>());
      expect((result as AroundTheClockResult).doublesOnly, isTrue);
    }));

    test('catch40: score and targetsCleared map from competitor state',
        (() async {
      const gameId = 'g-catch40';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.catch40,
        config: const GameConfig.catch40(),
        playerId: playerId,
        playerName: 'Bob',
        competitorId: competitorId,
      );

      // Round 1, target 61: single 11 (50 remaining) + DB (50 on double) →
      // checkout in 2 darts → +3 pts. After TurnEnded, engine advances
      // practiceRound to 2 and bumps score by 3, practiceSuccesses to 1.
      final events = <GameEvent>[
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 1,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, 2, 11, 1),
        dart(gameId, competitorId, playerId, 3, 25, 2),
        buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 4,
        ),
        // Stop after round 1; GameCompleted marks the game closed in the DB.
        buildGameCompletedEvent(
          gameId: gameId,
          winnerCompetitorId: null,
          localSequence: 5,
        ),
      ];

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId);
      expect(result, isA<Catch40Result>());
      final c40 = result as Catch40Result;
      expect(c40.competitorName, 'Bob');
      expect(c40.targetsCleared, 1);
      expect(c40.score, 3);
    }));

    test("bobs27: completes 20 rounds, finalScore and roundReached map",
        (() async {
      const gameId = 'g-bobs27';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.bobs27,
        config: const GameConfig.bobs27(),
        playerId: playerId,
        playerName: 'Carol',
        competitorId: competitorId,
      );

      // Play 20 rounds, missing every double. Score: 27 - sum(2*r for r in 1..20) = 27 - 420 < 0.
      // Engine ends at round 1 because score <= 0 after first miss (27 - 2 = 25 still > 0).
      // Actually: 27 - 2 = 25 (round 1 miss); - 4 = 21 (r2); - 6 = 15 (r3); - 8 = 7 (r4); - 10 = -3 (r5) → bust.
      // Game ends at round 5 with score = -3.
      final events = <GameEvent>[];
      var seq = 1;
      for (var round = 1; round <= 5; round++) {
        events.add(buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ));
        // Three misses (segment 0 / multiplier 1)
        for (var d = 0; d < 3; d++) {
          events.add(dart(gameId, competitorId, playerId, seq++, 0, 1));
        }
        events.add(buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
        ));
      }
      events.add(buildGameCompletedEvent(
        gameId: gameId,
        winnerCompetitorId: null,
        localSequence: seq++,
      ));

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId);
      expect(result, isA<Bobs27Result>());
      final b27 = result as Bobs27Result;
      expect(b27.competitorName, 'Carol');
      // Round 5 miss takes score to -3 → bust-to-zero.
      expect(b27.finalScore, -3);
      expect(b27.bustedToZero, isTrue);
      // Engine completed game at round 5; practiceRound is then 6.
      expect(b27.roundReached, 5);
    }));

    test("bobs27: full 21-round game (Double-Bull finale) → roundReached 21",
        (() async {
      const gameId = 'g-bobs27-full';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.bobs27,
        config: const GameConfig.bobs27(),
        playerId: playerId,
        playerName: 'Dave',
        competitorId: competitorId,
      );

      // Perfect run: 3 doubles of the round number for rounds 1–20, then three
      // Double Bulls in round 21 → 27 + Σ(3·2r, 1..20) + 3·50 = 1437 (#588).
      final events = <GameEvent>[];
      var seq = 1;
      for (var round = 1; round <= 21; round++) {
        events.add(buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ));
        final segment = round >= 21 ? 25 : round; // 25 = bull
        for (var d = 0; d < 3; d++) {
          events.add(dart(gameId, competitorId, playerId, seq++, segment, 2));
        }
        events.add(buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
        ));
      }
      events.add(buildGameCompletedEvent(
        gameId: gameId,
        winnerCompetitorId: null,
        localSequence: seq++,
      ));

      await completeWithEvents(gameId, null, events);

      final b27 = await useCase.execute(gameId) as Bobs27Result;
      expect(b27.bustedToZero, isFalse);
      expect(b27.finalScore, 1437);
      // The Double-Bull finale is round 21 — roundReached must reach 21, not
      // be clamped to 20 (#588/#600).
      expect(b27.roundReached, 21);
    }));

    test('checkoutPractice: successful checkout records darts and remaining=0',
        (() async {
      const gameId = 'g-co';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.checkoutPractice,
        config: const GameConfig.checkoutPractice(targetSuccesses: 1),
        playerId: playerId,
        playerName: 'Dave',
        competitorId: competitorId,
      );

      // 170: T20 (60) + T20 (60) + DB (50) = 170 checkout in 3 darts.
      final events = <GameEvent>[
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 1,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, 2, 20, 3),
        dart(gameId, competitorId, playerId, 3, 20, 3),
        dart(gameId, competitorId, playerId, 4, 25, 2),
        // Real #254 flow: DartThrown → TurnEnded(reason='checkout') →
        // GameCompleted. The DB dart was thrown at a double, so it's an attempt.
        buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 5,
          reason: 'checkout',
        ),
        buildGameCompletedEvent(
          gameId: gameId,
          winnerCompetitorId: competitorId,
          localSequence: 6,
        ),
      ];

      await completeWithEvents(gameId, competitorId, events);

      final result = await useCase.execute(gameId);
      expect(result, isA<CheckoutPracticeResult>());
      final co = result as CheckoutPracticeResult;
      expect(co.competitorName, 'Dave');
      expect(co.attempts, 1, reason: 'checkout visit threw at a double (#635)');
      expect(co.successes, 1);
      expect(co.dartsThrown, 3);
      expect(co.fromScore, 170);
      expect(co.targetSuccesses, 1, reason: 'quota carried from config (#603)');
    }));

    test('checkoutPractice: a setup-only visit (no dart at a double) is 0 attempts (#635)',
        (() async {
      const gameId = 'g-co-fail';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.checkoutPractice,
        config: const GameConfig.checkoutPractice(),
        playerId: playerId,
        playerName: 'Eve',
        competitorId: competitorId,
      );

      final events = <GameEvent>[
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 1,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, 2, 20, 1), // 170-20 = 150 (setup)
        buildGameCompletedEvent(
          gameId: gameId,
          winnerCompetitorId: null,
          localSequence: 3,
        ),
      ];

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId) as CheckoutPracticeResult;
      expect(result.attempts, 0,
          reason: 'one setup dart at 170 never reached a double (#635)');
      expect(result.successes, 0);
      expect(result.dartsThrown, 1);
      expect(result.fromScore, 170);
    }));

    test(
        'checkoutPractice: multi-attempt session reports aggregate attempts / successes (#316)',
        (() async {
      // The P0 repro from #316:
      //   round 1: T20+T20+DB → successful 170 checkout
      //   round 2: T20+T20+T20 → bust
      //   round 3: MISS+MISS+MISS → no checkout
      //   user taps End Drill (no TurnEnded for round 3 → GameCompleted only)
      // Pre-fix the result reported only the last round's state
      // ('NOT CHECKED OUT, 170 → 170'), ignoring round 1's success.
      const gameId = 'g-co-multi';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.checkoutPractice,
        config: const GameConfig.checkoutPractice(),
        playerId: playerId,
        playerName: 'Frank',
        competitorId: competitorId,
      );

      var seq = 1;
      final events = <GameEvent>[
        // Round 1: T20 + T20 + DB → checkout
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, seq++, 20, 3),
        dart(gameId, competitorId, playerId, seq++, 20, 3),
        dart(gameId, competitorId, playerId, seq++, 25, 2),
        buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
          reason: 'checkout',
        ),
        // Round 2: T20 + T20 + T20 → bust (180 > 170)
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, seq++, 20, 3),
        dart(gameId, competitorId, playerId, seq++, 20, 3),
        dart(gameId, competitorId, playerId, seq++, 20, 3),
        buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
        ),
        // Round 3: MISS + MISS + MISS, then user ends drill (no TurnEnded)
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, seq++, 0, 1),
        dart(gameId, competitorId, playerId, seq++, 0, 1),
        dart(gameId, competitorId, playerId, seq++, 0, 1),
        buildGameCompletedEvent(
          gameId: gameId,
          winnerCompetitorId: null,
          localSequence: seq++,
        ),
      ];

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId) as CheckoutPracticeResult;
      expect(result.competitorName, 'Frank');
      expect(result.attempts, 2,
          reason: 'round 1 checked out (DB) and round 2 reached 50/DB before '
              'busting — both threw at a double; round 3 (three misses from '
              '170) never reached a double, so it is not an attempt (#635)');
      expect(result.successes, 1,
          reason: 'round 1 checked out; rounds 2 and 3 did not');
      expect(result.dartsThrown, 9,
          reason: 'all darts physically thrown count, including the busted '
              "round's darts (#598: busts void the score, not the throw — "
              'aligned with the #634 three-dart-average convention)');
      expect(result.fromScore, 170);
      expect(result.targetSuccesses, isNull,
          reason: '∞ config (no quota) → null target (#603)');
    }));

    test('checkoutPractice: varied target — attempts read the run\'s from_score (#636)',
        (() async {
      const gameId = 'g-co-varied';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.checkoutPractice,
        config: const GameConfig.checkoutPractice(
          targetMode: 'fixed',
          fixedTarget: 50,
        ),
        playerId: playerId,
        playerName: 'Gus',
        competitorId: competitorId,
      );

      // Run starts FROM 50 (stamped on TurnStarted). One dart T16 (48) leaves 2
      // — the dart was thrown from 50 (on DB), so it's an attempt even though
      // the visit didn't check out. If the reconstruction wrongly used 170 the
      // dart would be at 170 (not a double) → 0 attempts.
      final events = <GameEvent>[
        GameEvent(
          eventId: 'g-co-varied-ts',
          gameId: gameId,
          eventType: 'TurnStarted',
          localSequence: 1,
          occurredAt: DateTime.utc(2026, 1, 1),
          payload: const {
            'competitor_id': competitorId,
            'player_id': playerId,
            'from_score': 50,
            'turn_index': 0,
            'leg_index': 0,
          },
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        ),
        dart(gameId, competitorId, playerId, 2, 16, 3), // 50 → 2 (missed DB)
        buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 3,
          reason: 'normal',
        ),
        buildGameCompletedEvent(
          gameId: gameId,
          winnerCompetitorId: null,
          localSequence: 4,
        ),
      ];

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId) as CheckoutPracticeResult;
      expect(result.attempts, 1,
          reason: 'the dart was thrown from 50 (on a double) per from_score');
      expect(result.successes, 0);
      expect(result.targetMode, 'fixed');
      expect(result.fixedTarget, 50);
    }));

    test('shanghai: bestRound observes max single-round score', (() async {
      const gameId = 'g-sh';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.shanghai,
        config: const GameConfig.shanghai(),
        playerId: playerId,
        playerName: 'Faye',
        competitorId: competitorId,
      );

      // 7 rounds. Round 1: hit 1 once → 1pt. Round 2: hit 2 thrice → 6pt.
      // Round 3..7: 3 misses each → 0pt.
      // Expected: totalScore=7, bestRound=6, shanghaiBonuses=0, roundsPlayed=7.
      final events = <GameEvent>[];
      var seq = 1;
      for (var round = 1; round <= 7; round++) {
        events.add(buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ));
        for (var d = 0; d < 3; d++) {
          int seg;
          int mult;
          if (round == 1) {
            seg = d == 0 ? 1 : 0;
            mult = d == 0 ? 1 : 1;
          } else if (round == 2) {
            seg = 2;
            mult = 1;
          } else {
            seg = 0;
            mult = 1;
          }
          events.add(dart(gameId, competitorId, playerId, seq++, seg, mult));
        }
        events.add(buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
        ));
      }
      // Final TurnEnded already fired for round 7 → engine sets isComplete.
      // No additional GameCompleted required, but emit one for cleanliness.

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId);
      expect(result, isA<ShanghaiResult>());
      final sh = result as ShanghaiResult;
      expect(sh.competitors, hasLength(1));
      final faye = sh.competitors.single;
      expect(faye.competitorName, 'Faye');
      expect(faye.totalScore, 7);
      expect(faye.bestRound, 6);
      expect(faye.shanghaiBonuses, 0);
      expect(faye.roundsPlayed, 7);
    }));

    test('shanghai: instant-win counts the shanghai bonus and ends early',
        (() async {
      const gameId = 'g-sh-instant';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.shanghai,
        config: const GameConfig.shanghai(),
        playerId: playerId,
        playerName: 'Gus',
        competitorId: competitorId,
      );

      // Round 1 Shanghai: single + double + triple of round 1 in any order.
      final events = <GameEvent>[
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 1,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, 2, 1, 1), // 1
        dart(gameId, competitorId, playerId, 3, 1, 2), // D1 → +2 = 3 total
        dart(gameId, competitorId, playerId, 4, 1, 3), // T1 → +3 = 6 total (shanghai!)
      ];

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId) as ShanghaiResult;
      final gus = result.competitors.single;
      expect(gus.totalScore, 6);
      expect(gus.shanghaiBonuses, 1);
      // Instant-win on round 1 means the round never ends; practiceRound = 1.
      expect(gus.roundsPlayed, 1);
      // bestRound captures the entire round-1 score: 1+2+3 = 6.
      expect(gus.bestRound, 6);
    }));

    test(
        'shanghai: multi-player instant-win — roundsPlayed matches TurnStarted '
        'count, not the practiceRound bump (#323)',
        (() async {
      // 2 players. Alice finishes turn (TurnEnded → practiceRound 1→2). Bob
      // hits a Shanghai in his turn → GameCompleted with no TurnEnded for
      // Bob's winning turn. Pre-fix: Alice=2, Bob=1. Post-fix both = 1.
      const gameId = 'g-sh-multi';
      final playerRepo = await base.createPlayerRepository();
      final gameRepo = await base.createGameRepository();
      for (final p in [('p1', 'Alice'), ('p2', 'Bob')]) {
        await playerRepo.createPlayer(Player(
          playerId: p.$1,
          name: p.$2,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        ));
      }
      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.shanghai,
          config: const GameConfig.shanghai(),
          startTime: DateTime.now(),
          isComplete: false,
        ),
        const [
          Competitor(
            competitorId: 'c1',
            gameId: gameId,
            type: CompetitorType.solo,
            name: 'Alice',
            players: [CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
          ),
          Competitor(
            competitorId: 'c2',
            gameId: gameId,
            type: CompetitorType.solo,
            name: 'Bob',
            players: [CompetitorPlayer(playerId: 'p2', rotationPosition: 0)],
          ),
        ],
      );

      var seq = 1;
      final events = <GameEvent>[
        // Alice round 1: S-1, MISS, T-1 → 4 points, TurnEnded
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: 'c1',
          playerId: 'p1',
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, 'c1', 'p1', seq++, 1, 1),
        dart(gameId, 'c1', 'p1', seq++, 0, 1),
        dart(gameId, 'c1', 'p1', seq++, 1, 3),
        buildTurnEndedEvent(
          gameId: gameId,
          competitorId: 'c1',
          playerId: 'p1',
          localSequence: seq++,
        ),
        // Bob round 1: S-1, D-1, T-1 → Shanghai, instant win, no TurnEnded
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: 'c2',
          playerId: 'p2',
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, 'c2', 'p2', seq++, 1, 1),
        dart(gameId, 'c2', 'p2', seq++, 1, 2),
        dart(gameId, 'c2', 'p2', seq++, 1, 3),
      ];

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId) as ShanghaiResult;
      final alice = result.competitors.firstWhere((c) => c.competitorId == 'c1');
      final bob = result.competitors.firstWhere((c) => c.competitorId == 'c2');
      expect(alice.roundsPlayed, 1,
          reason: 'Alice played round 1 only — her TurnEnded bumped '
              'practiceRound to 2 but she did not start a second round');
      expect(bob.roundsPlayed, 1,
          reason: 'Bob played one round, winning via Shanghai');
    }));
  });
}
