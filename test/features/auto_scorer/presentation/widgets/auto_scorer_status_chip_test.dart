import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ({String label, IconData icon}) describe(TrackerPhase phase, {int onBoard = 0}) =>
      AutoScorerStatusChip.describe(TrackerStatus(
          phase: phase, dartsOnBoard: onBoard, dartsThisTurn: 0));

  test('maps each phase to a label', () {
    expect(describe(TrackerPhase.noCalibration).label, 'Aim at the board');
    expect(describe(TrackerPhase.needsCalibration).label,
        'Camera needs calibration');
    expect(describe(TrackerPhase.idle).label, 'Ready');
    expect(describe(TrackerPhase.turnFull).label, 'Turn full — advance');
    expect(describe(TrackerPhase.cameraMoved).label, 'Camera moved');
    expect(describe(TrackerPhase.rebaselined).label, 'Board cleared');
  });

  test('tracking label pluralises the dart count', () {
    expect(describe(TrackerPhase.tracking, onBoard: 1).label, '1 dart detected');
    expect(describe(TrackerPhase.tracking, onBoard: 3).label, '3 darts detected');
  });

  testWidgets('label uses the at-distance titleMedium size (#480)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AutoScorerStatusChip(
          status: TrackerStatus(
              phase: TrackerPhase.tracking, dartsOnBoard: 2, dartsThisTurn: 2),
        ),
      ),
    ));

    final label = tester.widget<Text>(find.text('2 darts detected'));
    // titleMedium = 18px — the chip is the at-distance status/alert line now
    // that the camera preview collapses to a vignette.
    expect(label.style?.fontSize, 18);
  });
}
