import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/calibration_stability.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fully-calibrated frame with the four cals at [pts] (defaults to a fixed
/// reference set). [pts] must have length 4 for `hasCalibration` to be true.
DetectionFrame _calFrame([List<BoardPoint>? pts]) => DetectionFrame(
      calPoints: pts ??
          const [
            (x: 0.5, y: 0.2),
            (x: 0.5, y: 0.8),
            (x: 0.2, y: 0.5),
            (x: 0.8, y: 0.5),
          ],
      dartCandidates: const [],
    );

/// A frame with no calibration (fewer than four cals).
DetectionFrame _noCalFrame() =>
    const DetectionFrame(calPoints: [], dartCandidates: []);

void main() {
  group('CalibrationStabilityGate', () {
    test('becomes ready after requiredStableFrames steady frames', () {
      final gate = CalibrationStabilityGate(requiredStableFrames: 3);
      expect(gate.update(_calFrame()).isReady, isFalse); // 1
      expect(gate.update(_calFrame()).isReady, isFalse); // 2
      final third = gate.update(_calFrame());
      expect(third.stableFrames, 3);
      expect(third.isReady, isTrue);
    });

    test('a frame without calibration resets the counter to zero', () {
      final gate = CalibrationStabilityGate(requiredStableFrames: 3);
      gate.update(_calFrame());
      gate.update(_calFrame());
      final dropped = gate.update(_noCalFrame());
      expect(dropped.stableFrames, 0);
      expect(dropped.isReady, isFalse);
      // And it has to build back up from scratch.
      expect(gate.update(_calFrame()).stableFrames, 1);
    });

    test('a cal jump beyond the shift threshold restarts the count at 1', () {
      final gate = CalibrationStabilityGate(
          requiredStableFrames: 3, calShiftThreshold: 0.08);
      gate.update(_calFrame());
      gate.update(_calFrame());
      // Shift every cal by 0.3 (>> 0.08) → treated as a new baseline.
      final jumped = gate.update(_calFrame(const [
        (x: 0.8, y: 0.5),
        (x: 0.8, y: 1.0),
        (x: 0.5, y: 0.8),
        (x: 1.0, y: 0.8),
      ]));
      expect(jumped.stableFrames, 1);
      expect(jumped.isReady, isFalse);
    });

    test('a tiny sub-threshold jitter still counts as stable', () {
      final gate = CalibrationStabilityGate(
          requiredStableFrames: 2, calShiftThreshold: 0.08);
      gate.update(_calFrame());
      // Nudge each cal by ~0.01 (< 0.08) → still steady.
      final nudged = gate.update(_calFrame(const [
        (x: 0.51, y: 0.21),
        (x: 0.51, y: 0.81),
        (x: 0.21, y: 0.51),
        (x: 0.81, y: 0.51),
      ]));
      expect(nudged.stableFrames, 2);
      expect(nudged.isReady, isTrue);
    });

    test('defaults requiredStableFrames to 3 and threshold to the tracker value',
        () {
      final gate = CalibrationStabilityGate();
      expect(gate.requiredStableFrames, 3);
      expect(gate.calShiftThreshold, 0.08);
    });
  });
}
