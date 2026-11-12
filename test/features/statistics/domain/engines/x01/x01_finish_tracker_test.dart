import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_finish_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

GameEvent _e(String type, Map<String, dynamic> payload) => GameEvent(
  eventId: 'e-$type',
  gameId: 'g1',
  eventType: type,
  localSequence: 1,
  occurredAt: DateTime(2024),
  payload: payload,
  synced: false,
  actorId: 'p1',
  source: EventSource.client,
);

GameEvent _started(int score, {String player = 'p1'}) =>
    _e('TurnStarted', {'player_id': player, 'starting_score': score});

GameEvent _dart(int score, {String player = 'p1', bool bust = false}) => _e(
  'DartThrown',
  {'player_id': player, 'score': score, if (bust) 'bust': true},
);

GameEvent _ended({int? turnScore, String reason = 'normal'}) =>
    _e('TurnEnded', {
      'player_id': 'p1',
      'reason': reason,
      'turn_score': ?turnScore,
    });

X01FinishTracker _run(List<GameEvent> events) {
  final t = X01FinishTracker('p1');
  for (final e in events) {
    t.apply(e);
  }
  return t;
}

void main() {
  test(
    'a TurnEnded whose turn_score equals the starting score is a checkout',
    () {
      final t = _run([_started(40), _dart(40), _ended(turnScore: 40)]);
      expect(t.lastVisitCheckedOut, isTrue);
      expect(t.lastVisitStartingScore, 40);
    },
  );

  test('a TurnEnded that leaves points is not a checkout (round cap)', () {
    final t = _run([
      _started(210),
      _dart(1),
      _dart(1),
      _dart(1),
      _ended(turnScore: 3),
    ]);
    expect(t.lastVisitCheckedOut, isFalse);
  });

  test('a busted visit is not a checkout', () {
    final t = _run([
      _started(20),
      _dart(20, bust: true),
      _ended(turnScore: 0, reason: 'bust'),
    ]);
    expect(t.lastVisitCheckedOut, isFalse);
  });

  test('without turn_score (legacy events) the darts must reach 0', () {
    expect(
      _run([_started(40), _dart(40), _ended()]).lastVisitCheckedOut,
      isTrue,
    );
    expect(
      _run([_started(40), _dart(20), _ended()]).lastVisitCheckedOut,
      isFalse,
    );
  });

  test('without a TurnEnded the darts decide', () {
    expect(_run([_started(40), _dart(40)]).lastVisitCheckedOut, isTrue);
    expect(_run([_started(40), _dart(20)]).lastVisitCheckedOut, isFalse);
    expect(
      _run([_started(40), _dart(40, bust: true)]).lastVisitCheckedOut,
      isFalse,
    );
  });

  test('a visit with no evidence still counts as a checkout', () {
    expect(_run([_started(120)]).lastVisitCheckedOut, isTrue);
    expect(_run([]).lastVisitCheckedOut, isTrue);
  });

  test("other players' events are ignored", () {
    final t = _run([
      _started(40),
      _dart(40),
      _ended(turnScore: 40),
      _started(501, player: 'p2'),
      _dart(1, player: 'p2'),
    ]);
    expect(t.lastVisitCheckedOut, isTrue);
    expect(t.lastVisitStartingScore, 40);
  });

  test('a new visit clears the previous verdict', () {
    final t = _run([
      _started(60),
      _dart(1),
      _ended(turnScore: 1),
      _started(59),
    ]);
    expect(t.lastVisitCheckedOut, isTrue);
    expect(t.lastVisitStartingScore, 59);
  });
}
