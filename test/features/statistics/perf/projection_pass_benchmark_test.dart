// Performance benchmark for `PlayerStatsAssembler.gameStatsFromEvents` and
// `legCompetitorStatsFromEvents` — the per-player projection-replay hot paths
// (issue #137 §sub-task 5).
//
// Runs against a synthetic 100-game X01 and 100-game cricket dataset and
// prints wall-clock timings. Used for before/after comparisons of the
// O(P × E) → single-pass refactor; no hard threshold is enforced — CI just
// runs the harness and the numbers are captured in PR descriptions.
//
// Run with: `flutter test test/features/statistics/perf/projection_pass_benchmark_test.dart`

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/assemblers/player_stats_assembler.dart';
import 'package:flutter_test/flutter_test.dart';

const _gameCount = 100;
const _playersPerCompetitor = 1;
// A realistic public-darts table fields 4 entrants. We also report a higher
// player-count variant below to make the O(P × E) → O(E) refactor's win
// visible — the per-event filter cost in each engine is small enough that
// the gain stays within run-to-run noise at P=4 but grows sharply with P.
const _competitorsPerGame = 4;
const _competitorsPerGameLarge = 16;
const _legsPerGame = 3;
const _turnsPerLegPerCompetitor = 12;

GameEvent _event({
  required String gameId,
  required int seq,
  required String type,
  required Map<String, dynamic> payload,
  required String actorId,
}) =>
    GameEvent(
      eventId: '$gameId-$seq',
      gameId: gameId,
      eventType: type,
      localSequence: seq,
      occurredAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: seq)),
      payload: payload,
      synced: false,
      actorId: actorId,
      source: EventSource.client,
    );

/// Builds one synthetic game's worth of events + competitor metadata. Mirrors
/// the realistic shape: TurnStarted/DartThrown × 3/TurnEnded × N turns, then
/// LegCompleted; finally GameCompleted at the end.
({
  String gameId,
  List<Competitor> competitors,
  List<GameEvent> events,
  List<({String competitorId, String playerId, int score})> throws,
  Map<String, String> competitorNames,
}) _buildGame(int gameIdx, {int? competitorOverride}) {
  final competitorCount = competitorOverride ?? _competitorsPerGame;
  final gameId = 'g$gameIdx';
  final competitors = <Competitor>[];
  final competitorNames = <String, String>{};
  for (var c = 0; c < competitorCount; c++) {
    final competitorId = '$gameId-c$c';
    final players = <CompetitorPlayer>[
      for (var p = 0; p < _playersPerCompetitor; p++)
        CompetitorPlayer(
          playerId: '$gameId-c$c-p$p',
          rotationPosition: p,
        ),
    ];
    competitors.add(Competitor(
      competitorId: competitorId,
      gameId: gameId,
      type: CompetitorType.solo,
      name: 'Competitor $c',
      players: players,
    ));
    competitorNames[competitorId] = 'Competitor $c';
  }

  final events = <GameEvent>[];
  final throws = <({String competitorId, String playerId, int score})>[];
  var seq = 0;

  for (var legIdx = 0; legIdx < _legsPerGame; legIdx++) {
    for (var turn = 0; turn < _turnsPerLegPerCompetitor; turn++) {
      for (final comp in competitors) {
        final player = comp.players.first;
        events.add(_event(
          gameId: gameId,
          seq: ++seq,
          type: 'TurnStarted',
          actorId: player.playerId,
          payload: {
            'player_id': player.playerId,
            'turn_number': turn + 1,
            'starting_score': 501 - (turn * 60),
          },
        ));
        for (var d = 0; d < 3; d++) {
          // Mix of triples, doubles, singles, misses.
          final segment = (d == 0)
              ? 20
              : (d == 1)
                  ? 19
                  : 5;
          final multiplier = (d == 0) ? 3 : (d == 1 ? 2 : 1);
          final score = segment * multiplier;
          events.add(_event(
            gameId: gameId,
            seq: ++seq,
            type: 'DartThrown',
            actorId: player.playerId,
            payload: {
              'competitor_id': comp.competitorId,
              'player_id': player.playerId,
              'segment': segment,
              'multiplier': multiplier,
              'score': score,
            },
          ));
          throws.add((
            competitorId: comp.competitorId,
            playerId: player.playerId,
            score: score,
          ));
        }
        events.add(_event(
          gameId: gameId,
          seq: ++seq,
          type: 'TurnEnded',
          actorId: player.playerId,
          payload: {'player_id': player.playerId},
        ));
      }
    }
    // Winner rotates across legs.
    final winner = competitors[legIdx % competitors.length];
    events.add(_event(
      gameId: gameId,
      seq: ++seq,
      type: 'LegCompleted',
      actorId: winner.players.first.playerId,
      payload: {
        'winner_competitor_id': winner.competitorId,
        'winner_player_id': winner.players.first.playerId,
      },
    ));
  }
  events.add(_event(
    gameId: gameId,
    seq: ++seq,
    type: 'GameCompleted',
    actorId: competitors.first.players.first.playerId,
    payload: {'winner_competitor_id': competitors.first.competitorId},
  ));

  return (
    gameId: gameId,
    competitors: competitors,
    events: events,
    throws: throws,
    competitorNames: competitorNames,
  );
}

Duration _time(void Function() fn) {
  // Warm-up to remove JIT / first-call noise.
  for (var i = 0; i < 3; i++) {
    fn();
  }
  final sw = Stopwatch()..start();
  fn();
  sw.stop();
  return sw.elapsed;
}

void main() {
  const assembler = PlayerStatsAssembler();

  test('benchmark: gameStatsFromEvents — X01, $_gameCount games', () {
    final games = [for (var i = 0; i < _gameCount; i++) _buildGame(i)];
    final totalEvents = games.fold<int>(0, (s, g) => s + g.events.length);

    final elapsed = _time(() {
      for (final g in games) {
        assembler.gameStatsFromEvents(
          gameId: g.gameId,
          gameType: GameType.x01,
          throws: g.throws,
          competitorNames: g.competitorNames,
          events: g.events,
        );
      }
    });

    // ignore: avoid_print
    print(
      'BENCH gameStatsFromEvents x01: $_gameCount games × '
      '$_competitorsPerGame competitors × $_legsPerGame legs × '
      '$_turnsPerLegPerCompetitor turns/leg = $totalEvents events total → '
      '${elapsed.inMicroseconds} µs (${elapsed.inMilliseconds} ms)',
    );
  });

  test('benchmark: gameStatsFromEvents — cricket, $_gameCount games', () {
    final games = [for (var i = 0; i < _gameCount; i++) _buildGame(i)];
    final totalEvents = games.fold<int>(0, (s, g) => s + g.events.length);

    final elapsed = _time(() {
      for (final g in games) {
        assembler.gameStatsFromEvents(
          gameId: g.gameId,
          gameType: GameType.cricket,
          throws: g.throws,
          competitorNames: g.competitorNames,
          events: g.events,
        );
      }
    });

    // ignore: avoid_print
    print(
      'BENCH gameStatsFromEvents cricket: $_gameCount games × '
      '$_competitorsPerGame competitors × $_legsPerGame legs → '
      '$totalEvents events total → '
      '${elapsed.inMicroseconds} µs (${elapsed.inMilliseconds} ms)',
    );
  });

  test(
      'benchmark: gameStatsFromEvents — X01, $_gameCount games × '
      '$_competitorsPerGameLarge competitors (stresses player-count scaling)',
      () {
    final games = [
      for (var i = 0; i < _gameCount; i++)
        _buildGame(i, competitorOverride: _competitorsPerGameLarge),
    ];
    final totalEvents = games.fold<int>(0, (s, g) => s + g.events.length);

    final elapsed = _time(() {
      for (final g in games) {
        assembler.gameStatsFromEvents(
          gameId: g.gameId,
          gameType: GameType.x01,
          throws: g.throws,
          competitorNames: g.competitorNames,
          events: g.events,
        );
      }
    });

    // ignore: avoid_print
    print(
      'BENCH gameStatsFromEvents x01 (P=$_competitorsPerGameLarge): '
      '$_gameCount games × $_competitorsPerGameLarge competitors × '
      '$_legsPerGame legs → $totalEvents events total → '
      '${elapsed.inMicroseconds} µs (${elapsed.inMilliseconds} ms)',
    );
  });

  test('benchmark: legCompetitorStatsFromEvents — X01, $_gameCount × first leg',
      () {
    final games = [for (var i = 0; i < _gameCount; i++) _buildGame(i)];
    // Slice each game's events to the events of the first leg only (until
    // first LegCompleted inclusive).
    final perGameLegEvents = <
        ({
          List<GameEvent> events,
          List<Competitor> competitors,
        })>[];
    for (final g in games) {
      final legEvents = <GameEvent>[];
      for (final e in g.events) {
        legEvents.add(e);
        if (e.eventType == 'LegCompleted') break;
      }
      perGameLegEvents.add((events: legEvents, competitors: g.competitors));
    }

    final elapsed = _time(() {
      for (final entry in perGameLegEvents) {
        final allPlayerIds = [
          for (final c in entry.competitors)
            for (final p in c.players) p.playerId,
        ];
        for (final c in entry.competitors) {
          assembler.legCompetitorStatsFromEvents(
            events: entry.events,
            competitor: c,
            allPlayerIds: allPlayerIds,
            gameType: GameType.x01,
          );
        }
      }
    });

    // ignore: avoid_print
    print(
      'BENCH legCompetitorStatsFromEvents x01: $_gameCount legs × '
      '$_competitorsPerGame competitors → '
      '${elapsed.inMicroseconds} µs (${elapsed.inMilliseconds} ms)',
    );
  });
}
