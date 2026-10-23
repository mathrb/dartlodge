import 'package:dart_lodge/features/auto_scorer/domain/scoring/dartboard_scorer.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/auto_advance.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracked_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:flutter_test/flutter_test.dart';

TrackerUpdate _update(TrackerPhase phase, {int emitted = 0, int onBoard = 0}) =>
    TrackerUpdate(
      newDarts: [
        for (var i = 0; i < emitted; i++)
          TrackedDart(
            handle: i,
            boardPosition: (x: 0.0, y: -0.5),
            score: scoreDartAt(0.0, -0.5, 1.0),
            emitted: true,
          ),
      ],
      status: TrackerStatus(
        phase: phase,
        dartsOnBoard: onBoard,
        dartsThisTurn: emitted,
      ),
    );

void main() {
  group('AutoAdvanceGate', () {
    test('fires once on the board-clear after a camera dart', () {
      final gate = AutoAdvanceGate();
      expect(gate.onFrame(_update(TrackerPhase.tracking, emitted: 1)), isFalse);
      expect(gate.onFrame(_update(TrackerPhase.rebaselined)), isTrue);
      // The clear used up the arming: a second clear does nothing.
      expect(gate.onFrame(_update(TrackerPhase.rebaselined)), isFalse);
    });

    test('does NOT fire on a clear with no camera dart this turn', () {
      // rebaselined also fires when the board sat empty at turn start
      // (pending-only state); that must never skip a player.
      final gate = AutoAdvanceGate();
      expect(gate.onFrame(_update(TrackerPhase.rebaselined)), isFalse);
    });

    test('a clear the game declined leaves nothing armed for the next turn '
        '(#805)', () {
      final gate = AutoAdvanceGate();
      gate.onFrame(_update(TrackerPhase.tracking, emitted: 3, onBoard: 3));
      // Board cleared, but the sink skipped the advance (e.g. the practice
      // 0-dart guard after NEXT was tapped first) — so no reset() arrives.
      expect(gate.onFrame(_update(TrackerPhase.rebaselined)), isTrue);
      // Next turn: the camera misses dart 1 (one unconfirmed sighting), the
      // player adds it by hand, the board reads empty again.
      expect(gate.onFrame(_update(TrackerPhase.idle)), isFalse);
      expect(gate.onFrame(_update(TrackerPhase.rebaselined)), isFalse);
    });

    test('darts left on the board from the previous turn do not arm it', () {
      final gate = AutoAdvanceGate();
      gate.onFrame(_update(TrackerPhase.tracking, emitted: 3, onBoard: 3));
      gate.reset(); // NEXT tapped with the darts still on the board.
      expect(gate.onFrame(_update(TrackerPhase.tracking, onBoard: 3)), isFalse);
      expect(gate.onFrame(_update(TrackerPhase.rebaselined)), isFalse);
    });

    test('a camera move disarms it', () {
      final gate = AutoAdvanceGate();
      gate.onFrame(_update(TrackerPhase.tracking, emitted: 1, onBoard: 1));
      expect(gate.onFrame(_update(TrackerPhase.cameraMoved)), isFalse);
      expect(gate.onFrame(_update(TrackerPhase.rebaselined)), isFalse);
    });

    test('reset() disarms it', () {
      final gate = AutoAdvanceGate();
      gate.onFrame(_update(TrackerPhase.tracking, emitted: 2, onBoard: 2));
      gate.reset();
      expect(gate.onFrame(_update(TrackerPhase.rebaselined)), isFalse);
    });

    test('fires on no phase other than rebaselined', () {
      for (final phase in TrackerPhase.values
          .where((p) => p != TrackerPhase.rebaselined)) {
        final gate = AutoAdvanceGate();
        expect(gate.onFrame(_update(phase, emitted: 1, onBoard: 1)), isFalse,
            reason: 'phase $phase must not auto-advance');
      }
    });
  });
}
