import 'package:dart_lodge/features/game/domain/turn_dart_resolver.dart';
import 'package:dart_lodge/features/game/domain/usecases/game_use_case_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/features/game/domain/entities/game_event.dart';

GameEvent _dart(String id, int seq, String method) => buildDartThrownEvent(
      gameId: 'g',
      dartId: id,
      competitorId: 'c1',
      actorId: 'c1',
      localSequence: seq,
      segment: 20,
      multiplier: 1,
      inputMethod: method,
    );

void main() {
  group('resolveTurnDart', () {
    test('all-camera turn: cameraDartOrdinal follows throw order', () {
      final events = [
        _dart('d0', 1, 'camera'),
        _dart('d1', 2, 'camera'),
        _dart('d2', 3, 'camera'),
      ];
      for (var i = 0; i < 3; i++) {
        final r = resolveTurnDart(
            events: events,
            competitorId: 'c1',
            dartsThrownInTurn: 3,
            turnDartIndex: i);
        expect(r!.eventId, 'd$i');
        expect(r.cameraDartOrdinal, i + 1);
      }
    });

    test('#469: a manual dart between camera darts keeps camera ordinals aligned',
        () {
      // Throw order: camera(d0), manual(d1), camera(d2).
      final events = [
        _dart('d0', 1, 'camera'),
        _dart('d1', 2, 'manual'),
        _dart('d2', 3, 'camera'),
      ];

      // Dart 0 (camera) → camera ordinal 1.
      expect(
        resolveTurnDart(
                events: events,
                competitorId: 'c1',
                dartsThrownInTurn: 3,
                turnDartIndex: 0)!
            .cameraDartOrdinal,
        1,
      );

      // Dart 1 (manual) → no camera capture → null (correction must skip).
      final manual = resolveTurnDart(
          events: events,
          competitorId: 'c1',
          dartsThrownInTurn: 3,
          turnDartIndex: 1)!;
      expect(manual.eventId, 'd1');
      expect(manual.cameraDartOrdinal, isNull);

      // Dart 2 (camera) → camera ordinal 2 (NOT 3, the throw-order position).
      expect(
        resolveTurnDart(
                events: events,
                competitorId: 'c1',
                dartsThrownInTurn: 3,
                turnDartIndex: 2)!
            .cameraDartOrdinal,
        2,
      );
    });

    test('returns null when out of range', () {
      final events = [_dart('d0', 1, 'camera')];
      expect(
          resolveTurnDart(
              events: events,
              competitorId: 'c1',
              dartsThrownInTurn: 1,
              turnDartIndex: 1),
          isNull);
      expect(
          resolveTurnDart(
              events: events,
              competitorId: 'c1',
              dartsThrownInTurn: 1,
              turnDartIndex: -1),
          isNull);
    });

    test('uses only the last dartsThrownInTurn live darts (excludes corrected)',
        () {
      // A prior turn's dart (d_old) is corrected; the current turn is d0,d1.
      final events = <GameEvent>[
        _dart('d_old', 1, 'camera'),
        buildGameEvent(
          gameId: 'g',
          eventType: 'DartCorrected',
          localSequence: 2,
          actorId: 'system',
          payload: {'original_event_id': 'd_old', 'superseded_event_ids': []},
        ),
        _dart('d0', 3, 'camera'),
        _dart('d1', 4, 'camera'),
      ];
      final r = resolveTurnDart(
          events: events,
          competitorId: 'c1',
          dartsThrownInTurn: 2,
          turnDartIndex: 0);
      expect(r!.eventId, 'd0'); // d_old excluded, so turn dart 0 is d0
      expect(r.cameraDartOrdinal, 1);
    });
  });
}
