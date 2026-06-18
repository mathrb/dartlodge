import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/domain/sound/dart_sound_signal.dart';
import 'package:flutter_test/flutter_test.dart';

CompetitorState _competitor({List<String> dartThrows = const []}) =>
    CompetitorState(
      competitorId: 'c1',
      name: 'Alice',
      playerIds: const [],
      score: 501,
      dartThrows: dartThrows,
    );

GameState _state({
  int currentTurnIndex = 0,
  int dartsThrownInTurn = 0,
  List<CompetitorState>? competitors,
}) =>
    GameState(
      gameId: 'g1',
      gameType: GameType.x01,
      competitors: competitors ?? [_competitor()],
      currentTurnIndex: currentTurnIndex,
      dartsThrownInTurn: dartsThrownInTurn,
      isComplete: false,
    );

void main() {
  group('newestDartSegment', () {
    test('returns the just-thrown segment when dartsThrownInTurn += 1', () {
      final prev = _state(dartsThrownInTurn: 0);
      final next = _state(
        dartsThrownInTurn: 1,
        competitors: [_competitor(dartThrows: ['T20'])],
      );
      expect(newestDartSegment(prev, next), 'T20');
    });

    test('returns the latest dart on a later dart of the turn', () {
      final prev = _state(
        dartsThrownInTurn: 1,
        competitors: [_competitor(dartThrows: ['T20'])],
      );
      final next = _state(
        dartsThrownInTurn: 2,
        competitors: [_competitor(dartThrows: ['T20', 'MISS'])],
      );
      expect(newestDartSegment(prev, next), 'MISS');
    });

    test('null when prev is null (initial load, not a new dart)', () {
      expect(newestDartSegment(null, _state(dartsThrownInTurn: 1)), isNull);
    });

    test('null when the count is unchanged', () {
      expect(
        newestDartSegment(_state(dartsThrownInTurn: 1), _state(dartsThrownInTurn: 1)),
        isNull,
      );
    });

    test('null on undo (count decreases)', () {
      expect(
        newestDartSegment(_state(dartsThrownInTurn: 2), _state(dartsThrownInTurn: 1)),
        isNull,
      );
    });

    test('null on turn-end reset (3 -> 0)', () {
      expect(
        newestDartSegment(_state(dartsThrownInTurn: 3), _state(dartsThrownInTurn: 0)),
        isNull,
      );
    });

    test('null when the active competitor changed (turn boundary)', () {
      final prev = _state(currentTurnIndex: 0, dartsThrownInTurn: 2);
      final next = _state(currentTurnIndex: 1, dartsThrownInTurn: 3);
      expect(newestDartSegment(prev, next), isNull);
    });

    test('null on a bust jump (0 -> 3, delta != +1)', () {
      final prev = _state(dartsThrownInTurn: 0);
      final next = _state(
        dartsThrownInTurn: 3,
        competitors: [_competitor(dartThrows: ['T20', 'MISS', 'MISS'])],
      );
      expect(newestDartSegment(prev, next), isNull);
    });
  });
}
