// An X01 leg decided by the round cap (Table M in
// docs/games/x01.transitions.md: lowest remaining score wins) has no checkout.
// The checkout statistics must not credit the winner's last visit as one,
// while a real checkout on the last dart of the capped round still counts.
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_evaluator.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_metrics.dart';
import 'package:dart_lodge/features/achievements/domain/achievements_registry.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_x01_engine.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/statistics/domain/assemblers/player_stats_assembler.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a two-player 501 event stream in the shape ProcessDartUseCase and
/// ActiveGameNotifier write: TurnStarted{starting_score}, DartThrown{segment,
/// multiplier, score}, TurnEnded{reason, turn_score}, then LegCompleted and
/// GameCompleted.
class _Stream {
  final events = <GameEvent>[];
  final _remaining = {'c1': 501, 'c2': 501};
  static const _pid = {'c1': 'p1', 'c2': 'p2'};
  var _seq = 0;

  _Stream() {
    _add('GameCreated', {});
  }

  void _add(String type, Map<String, dynamic> payload) {
    _seq++;
    events.add(
      GameEvent(
        eventId: 'e$_seq',
        gameId: 'g1',
        eventType: type,
        localSequence: _seq,
        occurredAt: DateTime(2024),
        payload: payload,
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      ),
    );
  }

  static ({int segment, int multiplier, int score}) _parse(String s) {
    if (s == 'MISS') return (segment: 0, multiplier: 1, score: 0);
    final multiplier = s.startsWith('T') ? 3 : (s.startsWith('D') ? 2 : 1);
    final segment = int.parse(multiplier == 1 ? s : s.substring(1));
    return (
      segment: segment,
      multiplier: multiplier,
      score: segment * multiplier,
    );
  }

  /// One visit. [bust] marks the last dart and the TurnEnded as a bust and
  /// restores the visit's starting score, as the engine does.
  void turn(String c, List<String> darts, {bool bust = false}) {
    final start = _remaining[c]!;
    _add('TurnStarted', {
      'competitor_id': c,
      'player_id': _pid[c],
      'starting_score': start,
    });
    var r = start;
    for (var i = 0; i < darts.length; i++) {
      final d = _parse(darts[i]);
      _add('DartThrown', {
        'competitor_id': c,
        'player_id': _pid[c],
        'segment': d.segment,
        'multiplier': d.multiplier,
        'score': d.score,
        'input_method': 'manual',
        if (bust && i == darts.length - 1) 'bust': true,
      });
      r -= d.score;
    }
    if (bust) r = start;
    _remaining[c] = r;
    _add('TurnEnded', {
      'competitor_id': c,
      'player_id': _pid[c],
      'reason': bust ? 'bust' : 'normal',
      'turn_score': start - r,
    });
  }

  void p1Wins() {
    const winner = {'winner_competitor_id': 'c1', 'winner_player_id': 'p1'};
    _add('LegCompleted', winner);
    _add('GameCompleted', winner);
  }
}

const _assembler = PlayerStatsAssembler();

/// p1 starts round 10 on 210 and leaves 207; p2 leaves 471. The 10-round cap
/// (the smallest the config sheet offers) gives the leg to p1.
List<GameEvent> _capWinFrom210() {
  final s = _Stream();
  for (var round = 1; round <= 10; round++) {
    s.turn('c1', switch (round) {
      <= 8 => ['11', '11', '11'],
      9 => ['9', '9', '9'],
      _ => ['1', '1', '1'],
    });
    s.turn('c2', ['1', '1', '1']);
  }
  s.p1Wins();
  return s.events;
}

/// p1 reaches 20 on the last dart of round 9, so only round 10 is thrown from a
/// finish. In round 10 [lastVisit] decides the leg: a
/// checkout (the game ends on that dart) or not (p2 throws, then the cap).
List<GameEvent> _round10From20(
  List<String> lastVisit, {
  required bool checksOut,
  bool bust = false,
}) {
  final s = _Stream();
  for (var round = 1; round <= 9; round++) {
    s.turn('c1', round <= 8 ? ['20', '20', '20'] : ['MISS', 'MISS', '1']);
    s.turn('c2', ['1', '1', '1']);
  }
  s.turn('c1', lastVisit, bust: bust);
  if (!checksOut) s.turn('c2', ['1', '1', '1']);
  s.p1Wins();
  return s.events;
}

GameState _initialState() => const GameState(
  gameId: 'g1',
  gameType: GameType.x01,
  competitors: [
    CompetitorState(
      competitorId: 'c1',
      name: 'P1',
      playerIds: ['p1'],
      score: 501,
      startingScore: 501,
    ),
    CompetitorState(
      competitorId: 'c2',
      name: 'P2',
      playerIds: ['p2'],
      score: 501,
      startingScore: 501,
    ),
  ],
  currentTurnIndex: 0,
  dartsThrownInTurn: 0,
  isComplete: false,
  legsToWin: 1,
  x01TotalRounds: 10,
  inStrategy: 'straight',
  outStrategy: 'double',
  startingScore: 501,
);

/// Replays the stream (up to the leg result) through the real engine and
/// returns the outcome that decided the leg: the checkout dart's, or the cap's
/// on the last TurnEnded.
({EngineResult result, GameState state}) _replay(List<GameEvent> events) {
  final engine = StatelessX01Engine();
  var gs = _initialState();
  EngineResult? decisive;
  for (final e in events) {
    if (e.eventType == 'LegCompleted') break;
    final result = engine.apply(gs, e);
    if (result.outcome != LegOutcome.none) decisive = result;
    gs = result.state;
  }
  return (result: decisive!, state: gs);
}

PlayerStats _stats(List<GameEvent> events) => _assembler.fromEvents(
  playerId: 'p1',
  gameType: GameType.x01,
  events: events,
  totalGames: 1,
  totalDartsThrown: 30,
);

int? _legCheckoutScore(List<GameEvent> events) => _assembler
    .legHistoryFromEvents(
      playerId: 'p1',
      gameId: 'g1',
      gameDate: DateTime(2024),
      gameType: GameType.x01,
      startingScore: 501,
      events: events,
    )
    .single
    .checkoutScore;

void main() {
  group('a leg won on the round cap', () {
    test('fixture: the engine decides it by the cap, with 207 left', () {
      final r = _replay(_capWinFrom210());
      expect(r.result.outcome, LegOutcome.gameCompleted);
      expect(r.result.winnerCompetitorId, 'c1');
      expect(r.state.competitors[0].score, 207);
    });

    test('is not a highest checkout and does not unlock Big Fish', () {
      final m = _assembler.achievementMetricsFromEvents(
        playerId: 'p1',
        events: _capWinFrom210(),
        totalDartsThrown: 30,
        gameTypesById: const {'g1': GameType.x01},
      );
      final bigFish = const AchievementEvaluator().evaluate(
        kAchievements.firstWhere((a) => a.id == 'big_fish'),
        AchievementMetrics(highestCheckout: m.highestCheckout),
      );
      expect(m.highestCheckout, 0);
      expect(bigFish.unlocked, isFalse);
    });

    test('adds no checkout to the career stats but still counts as won', () {
      final s = _stats(_capWinFrom210());
      expect(s.highestCheckout, isNull);
      expect(s.avgCheckoutScore, isNull);
      expect(s.legsWon, 1);
    });

    test('has no per-leg checkout score', () {
      expect(_legCheckoutScore(_capWinFrom210()), isNull);
    });

    test('after a missed finish is 0% checkout and 0% double-out', () {
      final events = _round10From20(['D5', 'MISS', 'MISS'], checksOut: false);
      final r = _replay(events);
      expect(r.result.outcome, LegOutcome.gameCompleted);
      expect(r.state.competitors[0].score, 10);

      final s = _stats(events);
      expect(s.checkoutPercentage, 0.0);
      expect(s.bestGameCheckoutPercentage, 0.0);
      expect(s.doubleOutSuccessRate, 0.0);
      expect(s.highestCheckout, isNull);
      expect(_legCheckoutScore(events), isNull);
    });

    test('after a bust on the finish is not a checkout', () {
      final events = _round10From20(['20'], checksOut: false, bust: true);
      final r = _replay(events);
      expect(r.result.outcome, LegOutcome.gameCompleted);
      expect(r.state.competitors[0].score, 20);

      final s = _stats(events);
      expect(s.highestCheckout, isNull);
      expect(s.checkoutPercentage, 0.0);
      expect(_legCheckoutScore(events), isNull);
    });
  });

  test('a checkout on the last dart of the capped round still counts', () {
    final events = _round10From20(['D10'], checksOut: true);
    final r = _replay(events);
    expect(r.result.outcome, LegOutcome.gameCompleted);
    expect(r.result.winnerCompetitorId, 'c1');

    final s = _stats(events);
    expect(s.highestCheckout, 20);
    expect(s.avgCheckoutScore, 20.0);
    expect(s.checkoutPercentage, 100.0);
    expect(s.bestGameCheckoutPercentage, 100.0);
    expect(s.doubleOutSuccessRate, 100.0);
    expect(_legCheckoutScore(events), 20);
  });
}
