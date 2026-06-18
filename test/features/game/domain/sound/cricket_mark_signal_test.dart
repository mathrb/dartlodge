import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/domain/sound/cricket_mark_signal.dart';
import 'package:flutter_test/flutter_test.dart';

CompetitorState _competitor({
  String id = 'c1',
  int score = 0,
  Map<String, int> marksPerNumber = const {},
}) =>
    CompetitorState(
      competitorId: id,
      name: id,
      playerIds: const [],
      score: score,
      marksPerNumber: marksPerNumber,
    );

GameState _state({
  int currentTurnIndex = 0,
  int dartsThrownInTurn = 0,
  List<CompetitorState>? competitors,
}) =>
    GameState(
      gameId: 'g1',
      gameType: GameType.cricket,
      competitors: competitors ?? [_competitor()],
      currentTurnIndex: currentTurnIndex,
      dartsThrownInTurn: dartsThrownInTurn,
      isComplete: false,
    );

void main() {
  group('cricketDartOutcome', () {
    test('single mark (1)', () {
      final prev = _state(dartsThrownInTurn: 0);
      final next = _state(
        dartsThrownInTurn: 1,
        competitors: [_competitor(marksPerNumber: {'20': 1})],
      );
      expect(cricketDartOutcome(prev, next), (marks: 1, scoredPoints: false));
    });

    test('double mark (2)', () {
      final prev = _state(dartsThrownInTurn: 0);
      final next = _state(
        dartsThrownInTurn: 1,
        competitors: [_competitor(marksPerNumber: {'20': 2})],
      );
      expect(cricketDartOutcome(prev, next)?.marks, 2);
    });

    test('triple mark (3)', () {
      final prev = _state(dartsThrownInTurn: 0);
      final next = _state(
        dartsThrownInTurn: 1,
        competitors: [_competitor(marksPerNumber: {'20': 3})],
      );
      expect(cricketDartOutcome(prev, next)?.marks, 3);
    });

    test('triple onto a near-closed number counts only the marks added (cap)',
        () {
      final prev = _state(
        dartsThrownInTurn: 0,
        competitors: [_competitor(marksPerNumber: {'20': 2})],
      );
      final next = _state(
        dartsThrownInTurn: 1,
        competitors: [_competitor(marksPerNumber: {'20': 3})],
      );
      expect(cricketDartOutcome(prev, next)?.marks, 1); // 2 → 3 = +1
    });

    test('bull marks count (marksPerNumber key "Bull")', () {
      final prev = _state(dartsThrownInTurn: 0);
      final next = _state(
        dartsThrownInTurn: 1,
        competitors: [_competitor(marksPerNumber: {'Bull': 2})],
      );
      expect(cricketDartOutcome(prev, next)?.marks, 2);
    });

    test('closed number scoring points: 0 marks, scoredPoints true', () {
      final prev = _state(
        dartsThrownInTurn: 0,
        competitors: [_competitor(score: 0, marksPerNumber: {'20': 3})],
      );
      final next = _state(
        dartsThrownInTurn: 1,
        competitors: [_competitor(score: 60, marksPerNumber: {'20': 3})],
      );
      expect(cricketDartOutcome(prev, next), (marks: 0, scoredPoints: true));
    });

    test('true miss: 0 marks, no points', () {
      final prev = _state(dartsThrownInTurn: 0);
      final next = _state(dartsThrownInTurn: 1);
      expect(cricketDartOutcome(prev, next), (marks: 0, scoredPoints: false));
    });

    test('cut-throat: opponent score rises → scoredPoints true', () {
      final prev = _state(
        dartsThrownInTurn: 0,
        competitors: [
          _competitor(id: 'c1', score: 0, marksPerNumber: {'20': 3}),
          _competitor(id: 'c2', score: 0),
        ],
      );
      final next = _state(
        dartsThrownInTurn: 1,
        competitors: [
          _competitor(id: 'c1', score: 0, marksPerNumber: {'20': 3}),
          _competitor(id: 'c2', score: 60),
        ],
      );
      expect(cricketDartOutcome(prev, next), (marks: 0, scoredPoints: true));
    });

    test('null when not a single new dart', () {
      expect(cricketDartOutcome(null, _state(dartsThrownInTurn: 1)), isNull);
      expect(
        cricketDartOutcome(_state(dartsThrownInTurn: 1), _state(dartsThrownInTurn: 1)),
        isNull,
      );
      expect(
        cricketDartOutcome(
          _state(currentTurnIndex: 0, dartsThrownInTurn: 2),
          _state(currentTurnIndex: 1, dartsThrownInTurn: 3),
        ),
        isNull,
      );
    });
  });
}
