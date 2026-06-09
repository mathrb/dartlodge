import 'package:dart_lodge/features/auto_scorer/domain/tracking/auto_advance.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldAutoAdvance', () {
    test('advances on board-clear when darts were seen and enabled', () {
      expect(
        shouldAutoAdvance(
          phase: TrackerPhase.rebaselined,
          sawDartsThisTurn: true,
          enabled: true,
        ),
        isTrue,
      );
    });

    test('does NOT advance on a clear with no darts thrown this turn', () {
      // The key regression: rebaselined also fires when the board sat empty at
      // turn start (transform-only state). Without the guard this would skip a
      // player who hasn't thrown.
      expect(
        shouldAutoAdvance(
          phase: TrackerPhase.rebaselined,
          sawDartsThisTurn: false,
          enabled: true,
        ),
        isFalse,
      );
    });

    test('does NOT advance when the opt-in is off', () {
      expect(
        shouldAutoAdvance(
          phase: TrackerPhase.rebaselined,
          sawDartsThisTurn: true,
          enabled: false,
        ),
        isFalse,
      );
    });

    test('does NOT advance on any non-rebaselined phase', () {
      for (final phase in TrackerPhase.values
          .where((p) => p != TrackerPhase.rebaselined)) {
        expect(
          shouldAutoAdvance(
            phase: phase,
            sawDartsThisTurn: true,
            enabled: true,
          ),
          isFalse,
          reason: 'phase $phase must not auto-advance',
        );
      }
    });
  });
}
