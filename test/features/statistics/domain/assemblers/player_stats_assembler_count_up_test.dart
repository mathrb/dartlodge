// PlayerStatsAssembler integration tests for count-up game type.
//
// Locks down the contract that count-up snapshots produce the X01-shaped
// fields (threeDartAverage, firstNinePpr, high-score buckets) and leave
// X01-specific fields (checkoutPercentage, highestCheckout, bustRate, etc.)
// at default/null values.

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/assemblers/player_stats_assembler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const assembler = PlayerStatsAssembler();
  const playerId = 'p1';
  const gameId = 'g1';
  final fixedTime = DateTime.utc(2026, 1, 1);

  int seq = 0;
  GameEvent event(String type, Map<String, dynamic> payload) {
    seq++;
    return GameEvent(
      eventId: 'e$seq',
      gameId: gameId,
      eventType: type,
      localSequence: seq,
      occurredAt: fixedTime,
      payload: payload,
      synced: false,
      actorId: playerId,
      source: EventSource.client,
    );
  }

  setUp(() {
    seq = 0;
  });

  GameEvent dart(int segment, int multiplier, {String pid = playerId}) =>
      event('DartThrown', {
        'player_id': pid,
        'competitor_id': 'c_$pid',
        'segment': segment,
        'multiplier': multiplier,
        'score': segment * multiplier,
      });

  GameEvent turnStarted({String pid = playerId}) =>
      event('TurnStarted', {'player_id': pid, 'competitor_id': 'c_$pid'});

  GameEvent turnEnded({String pid = playerId}) => event(
        'TurnEnded',
        {'player_id': pid, 'competitor_id': 'c_$pid', 'reason': 'normal'},
      );

  GameEvent legCompleted() =>
      event('LegCompleted', {'winner_competitor_id': 'c_$playerId'});

  GameEvent gameCompleted() =>
      event('GameCompleted', {'winner_id': 'c_$playerId'});

  /// Builds 3 darts + TurnEnded for [pid].
  List<GameEvent> turn(String pid, List<({int s, int m})> darts) => [
        turnStarted(pid: pid),
        for (final d in darts) dart(d.s, d.m, pid: pid),
        turnEnded(pid: pid),
      ];

  group('fromEvents (career stats)', () {
    test('empty events → zero PlayerStats with no checkout fields', () {
      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.countUp,
        events: const [],
        totalGames: 0,
        totalDartsThrown: 0,
      );

      expect(stats.gameType, GameType.countUp);
      expect(stats.threeDartAverage, 0.0);
      expect(stats.firstNinePpr, isNull);
      expect(stats.sixtyPlusTurns, 0);
      expect(stats.oneHundredPlusTurns, 0);
      expect(stats.oneFortyPlusTurns, 0);
      expect(stats.oneEightyTurns, 0);

      // X01-only fields stay null/zero — checkout doesn't apply to count-up.
      expect(stats.checkoutPercentage, isNull);
      expect(stats.highestCheckout, isNull);
      expect(stats.bustRate, 0.0);
    });

    test('three full T20 turns + LegCompleted yields PPR=180 and 1 oneEighty bucket', () {
      final events = [
        ...turn(playerId, [(s: 20, m: 3), (s: 20, m: 3), (s: 20, m: 3)]),
        ...turn(playerId, [(s: 20, m: 3), (s: 20, m: 3), (s: 20, m: 3)]),
        ...turn(playerId, [(s: 20, m: 3), (s: 20, m: 3), (s: 20, m: 3)]),
        legCompleted(),
        gameCompleted(),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.countUp,
        events: events,
        totalGames: 1,
        totalDartsThrown: 9,
      );

      expect(stats.threeDartAverage, 180.0);
      expect(stats.firstNinePpr, 180.0);
      expect(stats.oneEightyTurns, 3);
      expect(stats.oneFortyPlusTurns, 0);
    });

    test('mixed turns hit the right buckets', () {
      final events = [
        // Turn 1: T20+T20+T20 = 180
        ...turn(playerId, [(s: 20, m: 3), (s: 20, m: 3), (s: 20, m: 3)]),
        // Turn 2: T20+T20+S20 = 140
        ...turn(playerId, [(s: 20, m: 3), (s: 20, m: 3), (s: 20, m: 1)]),
        // Turn 3: T20+S20+S20 = 100
        ...turn(playerId, [(s: 20, m: 3), (s: 20, m: 1), (s: 20, m: 1)]),
        // Turn 4: T20+MISS+MISS = 60
        ...turn(playerId, [(s: 20, m: 3), (s: 0, m: 1), (s: 0, m: 1)]),
        // Turn 5: S20+MISS+MISS = 20 (no bucket)
        ...turn(playerId, [(s: 20, m: 1), (s: 0, m: 1), (s: 0, m: 1)]),
        legCompleted(),
        gameCompleted(),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.countUp,
        events: events,
        totalGames: 1,
        totalDartsThrown: 15,
      );

      expect(stats.oneEightyTurns, 1);
      expect(stats.oneFortyPlusTurns, 1);
      expect(stats.oneHundredPlusTurns, 1);
      expect(stats.sixtyPlusTurns, 1);
    });

    test('totalGames / totalDartsThrown values are preserved', () {
      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.countUp,
        events: const [],
        totalGames: 7,
        totalDartsThrown: 168,
      );
      expect(stats.totalGames, 7);
      expect(stats.totalDartsThrown, 168);
    });
  });

  group('gameStatsFromEvents', () {
    test('empty throws → empty byCompetitor with gameType=countUp', () {
      final stats = assembler.gameStatsFromEvents(
        gameId: gameId,
        gameType: GameType.countUp,
        throws: const [],
        competitorNames: const {},
        events: const [],
      );
      expect(stats.byCompetitor, isEmpty);
      expect(stats.gameType, 'countUp');
    });

    test('byCompetitor entry contains 3-dart average and high-score bucket counts', () {
      final events = [
        ...turn(playerId, [(s: 20, m: 3), (s: 20, m: 3), (s: 20, m: 3)]),
        legCompleted(),
        gameCompleted(),
      ];
      final stats = assembler.gameStatsFromEvents(
        gameId: gameId,
        gameType: GameType.countUp,
        throws: [
          (competitorId: 'c_$playerId', playerId: playerId, score: 60),
          (competitorId: 'c_$playerId', playerId: playerId, score: 60),
          (competitorId: 'c_$playerId', playerId: playerId, score: 60),
        ],
        competitorNames: const {'c_$playerId': 'P1'},
        events: events,
      );

      expect(stats.byCompetitor, hasLength(1));
      final cs = stats.byCompetitor.first;
      expect(cs.threeDartAverage, 180.0);
      expect(cs.oneEightyTurns, 1);
      // Checkout-related fields not populated for count-up.
      expect(cs.checkoutPercentage, isNull);
      expect(cs.highestCheckout, isNull);
    });
  });

  group('legCompetitorStatsFromEvents', () {
    test('returns 3-dart average + high-score buckets, no checkout fields', () {
      final events = [
        ...turn(playerId, [(s: 20, m: 3), (s: 20, m: 3), (s: 20, m: 1)]),
        legCompleted(),
      ];

      final competitor = Competitor(
        competitorId: 'c_$playerId',
        gameId: gameId,
        type: CompetitorType.solo,
        name: 'P1',
        players: const [
          CompetitorPlayer(playerId: playerId, rotationPosition: 0),
        ],
      );

      final out = assembler.legCompetitorStatsFromEvents(
        events: events,
        competitor: competitor,
        allPlayerIds: [playerId],
        gameType: GameType.countUp,
      );

      expect(out.threeDartAverage, 140.0); // 140 over 3 darts × 3 = 140
      expect(out.oneFortyPlusTurns, 1);
      expect(out.checkoutPercentage, isNull);
      expect(out.highestCheckout, isNull);
    });
  });

  group('playerStatsForGameFromEvents', () {
    test('builds count-up-shaped per-game PlayerStats', () {
      final events = [
        ...turn(playerId, [(s: 20, m: 3), (s: 20, m: 3), (s: 20, m: 3)]),
        ...turn(playerId, [(s: 20, m: 3), (s: 20, m: 3), (s: 20, m: 3)]),
        ...turn(playerId, [(s: 20, m: 3), (s: 20, m: 3), (s: 20, m: 3)]),
        legCompleted(),
        gameCompleted(),
      ];

      final stats = assembler.playerStatsForGameFromEvents(
        playerId: playerId,
        gameType: GameType.countUp,
        playerDartsInGame: 9,
        playerScoreInGame: 540,
        events: events,
      );

      expect(stats.threeDartAverage, 180.0); // (540/9)*3
      expect(stats.firstNinePpr, 180.0);
      expect(stats.oneEightyTurns, 3);
      expect(stats.totalDartsThrown, 9);
      // Count-up has no per-leg-checkout / bust semantics.
      expect(stats.checkoutPercentage, isNull);
      expect(stats.highestCheckout, isNull);
      expect(stats.bustRate, 0.0);
    });
  });
}
