import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_first_nine_mpr_projection.dart';

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
  gameType: GameType.cricket,
  inStrategy: 'straight',
  outStrategy: 'straight',
);

void _visit(CricketFirstNineMprProjection engine, List<String> segments) {
  engine.apply(_e('TurnStarted', {'player_id': 'p1'}));
  for (final s in segments) {
    engine.apply(_e('DartThrown', {'player_id': 'p1', 'segment': s}));
  }
  engine.apply(_e('TurnEnded', {'player_id': 'p1'}));
}

void _legEnd(CricketFirstNineMprProjection engine) {
  engine.apply(_e('LegCompleted', {'winner_competitor_id': 'c1'}));
  engine.reset(ProjectionScope.leg);
}

/// A completed leg of three 3-mark visits → First 9 MPR 3.0.
void _threeMarkLeg(CricketFirstNineMprProjection engine) {
  _visit(engine, ['T20', 'MISS', 'MISS']);
  _visit(engine, ['T19', 'MISS', 'MISS']);
  _visit(engine, ['T18', 'MISS', 'MISS']);
  _legEnd(engine);
}

void main() {
  late CricketFirstNineMprProjection engine;

  setUp(() {
    _seq = 0;
    engine = CricketFirstNineMprProjection()..init(_ctx);
  });

  test('a completed leg of three 3-mark visits reads 3.0', () {
    _threeMarkLeg(engine);
    final snap = engine.snapshot();
    expect(snap['firstNineMpr'], closeTo(3.0, 1e-9));
    expect(snap['totalFirstNineMarks'], 9);
    expect(snap['totalFirstNineLegs'], 1);
  });

  test('an abandoned leg (no LegCompleted) adds no marks', () {
    _threeMarkLeg(engine);
    _visit(engine, ['T17', 'T16', 'T15']);
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.match);
    final snap = engine.snapshot();
    expect(snap['firstNineMpr'], closeTo(3.0, 1e-9));
    expect(snap['totalFirstNineMarks'], 9);
    expect(snap['totalFirstNineLegs'], 1);
  });

  test('a leg completed in 2 visits adds neither marks nor a leg', () {
    _threeMarkLeg(engine);
    _visit(engine, ['T20', 'T19', 'T18']);
    _visit(engine, ['T17', 'T16', 'T15']);
    _legEnd(engine);
    final snap = engine.snapshot();
    expect(snap['firstNineMpr'], closeTo(3.0, 1e-9));
    expect(snap['totalFirstNineMarks'], 9);
    expect(snap['totalFirstNineLegs'], 1);
  });

  test('only abandoned legs leave the average null and the marks at 0', () {
    _visit(engine, ['T20', 'T19', 'T18']);
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.match);
    final snap = engine.snapshot();
    expect(snap['firstNineMpr'], isNull);
    expect(snap['totalFirstNineMarks'], 0);
    expect(snap['totalFirstNineLegs'], 0);
  });
}
