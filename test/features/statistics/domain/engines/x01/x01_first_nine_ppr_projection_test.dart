import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_first_nine_ppr_projection.dart';

var _seq = 0;

GameEvent _e(String type, Map<String, dynamic> payload) {
  _seq++;
  return GameEvent(
    eventId: 'evt-$_seq',
    gameId: 'g',
    eventType: type,
    localSequence: _seq,
    occurredAt: DateTime(2024),
    payload: payload,
    synced: false,
    actorId: 'p1',
    source: EventSource.client,
  );
}

const _ctx = ProjectionContext(
  playerId: 'p1',
  gameType: GameType.x01,
  inStrategy: 'straight',
  outStrategy: 'double',
);

/// One 3-dart visit for [pid] of three single [seg]s, with a matching
/// `turn_score`.
void _visit(X01FirstNinePprProjection engine, String pid, int seg) {
  engine.apply(_e('TurnStarted', {'player_id': pid}));
  for (var i = 0; i < 3; i++) {
    engine.apply(_e('DartThrown', {
      'player_id': pid,
      'segment': seg,
      'multiplier': 1,
      'score': seg,
    }));
  }
  engine.apply(_e('TurnEnded', {'player_id': pid, 'turn_score': seg * 3}));
}

void _legEnd(X01FirstNinePprProjection engine) {
  engine.apply(_e('LegCompleted', {'winner_competitor_id': 'c1'}));
  engine.reset(ProjectionScope.leg);
}

void main() {
  late X01FirstNinePprProjection engine;

  setUp(() {
    _seq = 0;
    engine = X01FirstNinePprProjection()..init(_ctx);
  });

  test('a completed leg of 3 visits of 60 reads 60', () {
    for (var i = 0; i < 3; i++) {
      _visit(engine, 'p1', 20);
    }
    _legEnd(engine);
    expect(engine.snapshot()['firstNinePpr'], closeTo(60.0, 1e-9));
    expect(engine.snapshot()['totalFirstNineLegs'], 1);
  });

  test('an abandoned leg (no LegCompleted) adds nothing to the numerator', () {
    for (var i = 0; i < 3; i++) {
      _visit(engine, 'p1', 20);
    }
    _legEnd(engine);
    // Game abandoned after one 180-equivalent visit: closed by GameCompleted,
    // never by LegCompleted, then the runner resets at the game boundary.
    _visit(engine, 'p1', 60);
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.match);
    expect(engine.snapshot()['firstNinePpr'], closeTo(60.0, 1e-9));
    expect(engine.snapshot()['totalFirstNineLegs'], 1);
  });

  test('an abandoned leg of 3+ visits is excluded too', () {
    for (var i = 0; i < 3; i++) {
      _visit(engine, 'p1', 20);
    }
    _legEnd(engine);
    for (var i = 0; i < 3; i++) {
      _visit(engine, 'p1', 60);
    }
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.match);
    expect(engine.snapshot()['firstNinePpr'], closeTo(60.0, 1e-9));
  });

  test('a leg finished in 2 visits adds neither points nor a leg', () {
    for (var i = 0; i < 3; i++) {
      _visit(engine, 'p1', 20);
    }
    _legEnd(engine);
    _visit(engine, 'p1', 60);
    _visit(engine, 'p1', 60);
    _legEnd(engine);
    expect(engine.snapshot()['firstNinePpr'], closeTo(60.0, 1e-9));
    expect(engine.snapshot()['totalFirstNineLegs'], 1);
  });

  test('only abandoned legs leave the average null', () {
    _visit(engine, 'p1', 60);
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.match);
    expect(engine.snapshot()['firstNinePpr'], isNull);
    expect(engine.snapshot()['totalFirstNineLegs'], 0);
  });

  test('visits past the first three and opponent visits do not count', () {
    _visit(engine, 'p1', 20);
    _visit(engine, 'p2', 60);
    _visit(engine, 'p1', 20);
    _visit(engine, 'p1', 20);
    _visit(engine, 'p1', 60);
    _legEnd(engine);
    expect(engine.snapshot()['firstNinePpr'], closeTo(60.0, 1e-9));
  });
}
