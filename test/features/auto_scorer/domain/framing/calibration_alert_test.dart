import 'package:dart_lodge/features/auto_scorer/domain/framing/calibration_alert.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('phaseImpliesCalibration', () {
    test('the two no-calibration phases prove nothing', () {
      expect(phaseImpliesCalibration(TrackerPhase.noCalibration), isFalse);
      expect(phaseImpliesCalibration(TrackerPhase.needsCalibration), isFalse);
    });

    test('every other phase can only be reached with a calibration', () {
      // idle / rebaselined / cameraMoved come from the tracker's calibrated
      // branch; tracking / turnFull can also come from the held-homography
      // continuation (#485), which needs a transform derived earlier.
      for (final phase in [
        TrackerPhase.idle,
        TrackerPhase.tracking,
        TrackerPhase.turnFull,
        TrackerPhase.cameraMoved,
        TrackerPhase.rebaselined,
      ]) {
        expect(phaseImpliesCalibration(phase), isTrue, reason: '$phase');
      }
    });
  });

  group('calibrationAlertOf', () {
    test('only the sustained loss is classified', () {
      for (final phase in TrackerPhase.values) {
        if (phase == TrackerPhase.needsCalibration) continue;
        expect(
          calibrationAlertOf(phase: phase, everCalibrated: false),
          CalibrationAlert.none,
          reason: '$phase',
        );
        expect(
          calibrationAlertOf(phase: phase, everCalibrated: true),
          CalibrationAlert.none,
          reason: '$phase',
        );
      }
    });

    test('never calibrated → learning mode', () {
      expect(
        calibrationAlertOf(
            phase: TrackerPhase.needsCalibration, everCalibrated: false),
        CalibrationAlert.learningMode,
      );
    });

    test('calibrated then lost → alert', () {
      expect(
        calibrationAlertOf(
            phase: TrackerPhase.needsCalibration, everCalibrated: true),
        CalibrationAlert.lost,
      );
    });

    test('a transient single-frame loss never alarms, calibrated or not', () {
      expect(
        calibrationAlertOf(
            phase: TrackerPhase.noCalibration, everCalibrated: true),
        CalibrationAlert.none,
      );
    });
  });
}
