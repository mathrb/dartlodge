import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/widgets/live_average.dart';
import 'package:flutter_test/flutter_test.dart';

CompetitorState _cs(List<String> dartThrows) => CompetitorState(
      competitorId: 'c1',
      name: 'Alice',
      playerIds: const [],
      score: 501,
      dartThrows: dartThrows,
    );

void main() {
  group('x01LivePprDisplay', () {
    test('returns the em-dash until a full visit (3 darts) is thrown', () {
      expect(x01LivePprDisplay(_cs(const [])), '—');
      expect(x01LivePprDisplay(_cs(const ['T20', '20'])), '—');
    });

    test('is the 3-dart average of dart values (incl. busts as scored)', () {
      // 60+60+60 = 180 over 3 darts → 180/3*3 = 180.
      expect(x01LivePprDisplay(_cs(const ['T20', 'T20', 'T20'])), '180');
      // 60+20+0 (miss) = 80 over 3 darts → 80.
      expect(x01LivePprDisplay(_cs(const ['T20', '20', 'MISS'])), '80');
    });
  });

  group('cricketLiveMpr', () {
    final fixed = {15, 16, 17, 18, 19, 20, 25};

    test('is 0 until a full round is thrown', () {
      expect(cricketLiveMpr(_cs(const ['T20', 'T20']), targets: fixed), 0.0);
      expect(cricketLiveMprDisplay(_cs(const []), targets: fixed), '0');
    });

    test('counts marks over rounds, including overflow on a closed number', () {
      // 1 round of three T20 = 9 marks → 9.0.
      expect(cricketLiveMpr(_cs(const ['T20', 'T20', 'T20']), targets: fixed),
          9.0);
      // 2 rounds of T20 = 18 marks / 2 → 9.0 (overflow still counts).
      expect(
        cricketLiveMpr(
            _cs(const ['T20', 'T20', 'T20', 'T20', 'T20', 'T20']),
            targets: fixed),
        9.0,
      );
    });

    test('respects a non-fixed target set (Random/Crazy)', () {
      final crazy = {10, 11, 12, 13, 14, 25};
      // T10 is a target here (3 marks); T20 is NOT → 0 marks.
      expect(
        cricketLiveMpr(_cs(const ['T10', 'MISS', 'MISS']), targets: crazy),
        3.0,
      );
      expect(
        cricketLiveMpr(_cs(const ['T20', 'MISS', 'MISS']), targets: crazy),
        0.0,
      );
    });

    test('display formats via StatFormatter (trailing zeros stripped)', () {
      expect(cricketLiveMprDisplay(_cs(const ['T20', '20', 'MISS']),
              targets: fixed),
          '4'); // (3+1+0)/1 = 4.0 → '4'
    });
  });
}
