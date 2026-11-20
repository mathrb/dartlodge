import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_first_nine_mpr_projection.dart';

void main() {
  late CricketFirstNineMprProjection engine;
  var seq = 0;

  GameEvent event(String type, Map<String, dynamic> payload) {
    seq++;
    return GameEvent(
      eventId: 'evt-$seq-$type',
      gameId: 'game-1',
      eventType: type,
      localSequence: seq,
      occurredAt: DateTime(2024),
      payload: payload,
      synced: false,
      actorId: 'p1',
      source: EventSource.client,
    );
  }

  /// One full visit for [playerId]: TurnStarted, 3 darts, TurnEnded.
  void visit(List<String> segments, {String playerId = 'p1'}) {
    engine.apply(event('TurnStarted', {'player_id': playerId}));
    for (final s in segments) {
      engine.apply(event('DartThrown', {'player_id': playerId, 'segment': s}));
    }
    engine.apply(event('TurnEnded', {'player_id': playerId}));
  }

  /// Ends the leg the way ProjectionRunner does: apply, then a leg reset.
  void endLeg() {
    engine.apply(event('LegCompleted', {'winner_player_id': 'p1'}));
    engine.reset(ProjectionScope.leg);
  }

  /// A completed leg of three 3-mark visits → First 9 MPR 3.0.
  void threeMarkLeg() {
    visit(['T20', 'MISS', 'MISS']);
    visit(['T19', 'MISS', 'MISS']);
    visit(['T18', 'MISS', 'MISS']);
    endLeg();
  }

  setUp(() {
    seq = 0;
    engine = CricketFirstNineMprProjection();
    engine.init(const ProjectionContext(
      playerId: 'p1',
      gameType: GameType.cricket,
      inStrategy: 'straight',
      outStrategy: 'straight',
    ));
  });

  test('init: no first-nine average and no best', () {
    final s = engine.snapshot();
    expect(s['firstNineMpr'], isNull);
    expect(s['bestFirstNineMpr'], isNull);
  });

  test('bestFirstNineMpr is the best single-leg first-9 MPR', () {
    // Leg 1: 3 + 3 + 3 marks in the first 3 visits → 3.0.
    visit(['T20', 'MISS', 'MISS']);
    visit(['T19', 'MISS', 'MISS']);
    visit(['T18', 'MISS', 'MISS']);
    endLeg();
    // Leg 2: 9 + 6 + 0 marks → 5.0. The 4th visit is outside the window.
    visit(['T20', 'T19', 'T18']);
    visit(['T17', 'T16', 'MISS']);
    visit(['MISS', 'MISS', 'MISS']);
    visit(['T15', 'DB', 'DB']);
    endLeg();

    final s = engine.snapshot();
    expect(s['bestFirstNineMpr'], closeTo(5.0, 1e-9));
    expect(s['firstNineMpr'], closeTo(24 / 6, 1e-9));
  });

  test('a later weaker leg does not lower the best', () {
    visit(['T20', 'T19', 'T18']);
    visit(['T17', 'T16', 'T15']);
    visit(['DB', 'SB', 'MISS']);
    endLeg(); // 21 marks → 7.0
    visit(['20', 'MISS', 'MISS']);
    visit(['19', 'MISS', 'MISS']);
    visit(['18', 'MISS', 'MISS']);
    endLeg(); // 3 marks → 1.0

    expect(engine.snapshot()['bestFirstNineMpr'], closeTo(7.0, 1e-9));
  });

  test('a leg with fewer than 3 visits never sets the best (#290 gate)', () {
    visit(['T20', 'T19', 'T18']);
    visit(['T17', 'T16', 'T15']);
    endLeg();

    expect(engine.snapshot()['bestFirstNineMpr'], isNull);
  });

  test("an opponent's visits do not count towards the best", () {
    visit(['T20', 'MISS', 'MISS']);
    visit(['T19', 'T18', 'T17'], playerId: 'p2');
    visit(['MISS', 'MISS', 'MISS']);
    visit(['T16', 'T15', 'DB'], playerId: 'p2');
    visit(['MISS', 'MISS', 'MISS']);
    endLeg();

    expect(engine.snapshot()['bestFirstNineMpr'], closeTo(1.0, 1e-9));
  });

  test('a completed leg of three 3-mark visits reads 3.0', () {
    threeMarkLeg();
    final snap = engine.snapshot();
    expect(snap['firstNineMpr'], closeTo(3.0, 1e-9));
    expect(snap['totalFirstNineMarks'], 9);
    expect(snap['totalFirstNineLegs'], 1);
  });

  test('an abandoned leg (no LegCompleted) adds no marks', () {
    threeMarkLeg();
    visit(['T17', 'T16', 'T15']);
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.match);
    final snap = engine.snapshot();
    expect(snap['firstNineMpr'], closeTo(3.0, 1e-9));
    expect(snap['totalFirstNineMarks'], 9);
    expect(snap['totalFirstNineLegs'], 1);
  });

  test('a leg completed in 2 visits adds neither marks nor a leg', () {
    threeMarkLeg();
    visit(['T20', 'T19', 'T18']);
    visit(['T17', 'T16', 'T15']);
    endLeg();
    final snap = engine.snapshot();
    expect(snap['firstNineMpr'], closeTo(3.0, 1e-9));
    expect(snap['totalFirstNineMarks'], 9);
    expect(snap['totalFirstNineLegs'], 1);
  });

  test('only abandoned legs leave the average null and the marks at 0', () {
    visit(['T20', 'T19', 'T18']);
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.match);
    final snap = engine.snapshot();
    expect(snap['firstNineMpr'], isNull);
    expect(snap['totalFirstNineMarks'], 0);
    expect(snap['totalFirstNineLegs'], 0);
  });
}
