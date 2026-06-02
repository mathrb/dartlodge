import 'dart:math' as math;

import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/scoring/dartboard_scorer.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the per-dart arrival tracker (#380). Frames are built on a
/// centred-square calibration so image space == canonical space (the
/// rectification homography is the identity), letting us place darts at known
/// board positions and assert both the scoring and the state-machine behaviour
/// the acceptance criteria call out.
void main() {
  // Centred-square cals (top, bottom, left, right) → centre (0.5,0.5), r 0.3.
  const cals = <BoardPoint>[
    (x: 0.5, y: 0.2),
    (x: 0.5, y: 0.8),
    (x: 0.2, y: 0.5),
    (x: 0.8, y: 0.5),
  ];

  DetectionFrame frame(List<BoardPoint> darts, {List<BoardPoint> c = cals}) =>
      DetectionFrame(calPoints: c, dartCandidates: darts);

  double degFor(int number) {
    final bin =
        kBoardSectors.entries.firstWhere((e) => e.value == number).key;
    return (bin * 18 + 9).toDouble();
  }

  // A dart image-point for sector [number] at [normRadius] board-radius units.
  BoardPoint seg(int number, double normRadius) {
    final rad = degFor(number) * math.pi / 180;
    return (
      x: 0.5 + normRadius * 0.3 * math.cos(rad),
      y: 0.5 - normRadius * 0.3 * math.sin(rad),
    );
  }

  const rSingle = 0.40;
  const rTreble = 0.61;
  const rDouble = 0.97;

  group('confirm-before-emit', () {
    test('a dart emits only after persisting confirmFrames frames', () {
      final tracker = DartTracker();
      final dart = seg(20, rTreble);

      final first = tracker.processFrame(frame([dart]));
      expect(first.newDarts, isEmpty, reason: 'pending after 1 frame');
      expect(first.status.dartsOnBoard, 0);

      final second = tracker.processFrame(frame([dart]));
      expect(second.newDarts, hasLength(1));
      expect(second.newDarts.single.score.segment, 'T20');
      expect(second.status.dartsThisTurn, 1);
      expect(second.status.dartsOnBoard, 1);
      expect(second.status.phase, TrackerPhase.tracking);
    });

    test('a single-frame blip never emits (no phantom)', () {
      final tracker = DartTracker();
      final blip = seg(5, rSingle); // appears once, far from the real dart
      final real = seg(20, rTreble);

      tracker.processFrame(frame([blip, real])); // both pending
      tracker.processFrame(frame([real])); // real confirms; blip unseen (miss 1)
      tracker.processFrame(frame([real])); // miss 2
      final last = tracker.processFrame(frame([real])); // blip miss 3 → dropped

      expect(last.status.dartsOnBoard, 1);
      expect(tracker.confirmedDarts.single.score.segment, 'T20');
    });
  });

  group('no double-emit', () {
    test('a stationary dart over many frames emits exactly once', () {
      final tracker = DartTracker();
      final dart = seg(20, rTreble);
      var emitted = 0;
      for (var i = 0; i < 6; i++) {
        emitted += tracker.processFrame(frame([dart])).newDarts.length;
      }
      expect(emitted, 1);
      expect(tracker.confirmedDarts, hasLength(1));
      expect(tracker.dartsThisTurn, 1);
    });
  });

  group('occlusion', () {
    test('a confirmed dart persists when later occluded', () {
      final tracker = DartTracker();
      final a = seg(20, rTreble);
      final b = seg(3, rDouble); // bottom of the board, far from a

      tracker.processFrame(frame([a, b]));
      final confirmed = tracker.processFrame(frame([a, b]));
      expect(confirmed.status.dartsOnBoard, 2);

      // b is now occluded; the frame is still non-empty (a is visible).
      final occluded = tracker.processFrame(frame([a]));
      expect(occluded.status.dartsOnBoard, 2, reason: 'occluded dart kept');
      expect(occluded.status.phase, TrackerPhase.tracking);

      // b reappears — still the same physical dart, not a new one.
      final back = tracker.processFrame(frame([a, b]));
      expect(back.status.dartsOnBoard, 2);
      expect(back.newDarts, isEmpty);
    });
  });

  group('3-dart cap', () {
    final d1 = seg(20, rTreble);
    final d2 = seg(6, rTreble);
    final d3 = seg(11, rTreble);
    final d4 = seg(3, rTreble);

    test('a 4th dart on a full turn is tracked but not emitted', () {
      final tracker = DartTracker();
      tracker.processFrame(frame([d1, d2, d3]));
      final confirmed = tracker.processFrame(frame([d1, d2, d3]));
      expect(confirmed.newDarts, hasLength(3));
      expect(tracker.dartsThisTurn, 3);

      tracker.processFrame(frame([d1, d2, d3, d4]));
      final capped = tracker.processFrame(frame([d1, d2, d3, d4]));
      expect(capped.newDarts, isEmpty, reason: '4th dart not emitted');
      expect(capped.status.phase, TrackerPhase.turnFull);
      expect(tracker.dartsThisTurn, 3, reason: 'cap holds');
      expect(tracker.confirmedDarts, hasLength(4), reason: 'still tracked');
      expect(tracker.confirmedDarts.last.emitted, isFalse);
    });

    test('turnFull persists while the over-cap dart stays on the board', () {
      final tracker = DartTracker();
      tracker.processFrame(frame([d1, d2, d3]));
      tracker.processFrame(frame([d1, d2, d3]));
      tracker.processFrame(frame([d1, d2, d3, d4]));
      tracker.processFrame(frame([d1, d2, d3, d4])); // 4th confirms → capped

      // A later steady frame with nothing new to confirm must STILL report
      // turnFull (the prompt is the point of the cap), not revert to tracking.
      final steady = tracker.processFrame(frame([d1, d2, d3, d4]));
      expect(steady.newDarts, isEmpty);
      expect(steady.status.phase, TrackerPhase.turnFull);

      // It clears once the board is re-baselined.
      final cleared = tracker.removeDarts();
      expect(cleared.status.phase, TrackerPhase.rebaselined);
    });

    test('onTurnAdvanced resets the cap and lets the next turn emit', () {
      final tracker = DartTracker();
      tracker.processFrame(frame([d1, d2, d3]));
      tracker.processFrame(frame([d1, d2, d3]));
      expect(tracker.dartsThisTurn, 3);

      tracker.onTurnAdvanced();
      expect(tracker.dartsThisTurn, 0);

      // A new physical dart in the next turn (board not yet cleared).
      final newDart = seg(19, rTreble);
      tracker.processFrame(frame([d1, d2, d3, newDart]));
      final emit = tracker.processFrame(frame([d1, d2, d3, newDart]));
      expect(emit.newDarts, hasLength(1));
      expect(emit.newDarts.single.score.segment, 'T19');
      expect(tracker.dartsThisTurn, 1);
    });
  });

  group('re-baseline paths', () {
    BoardPoint dart() => seg(20, rTreble);

    void confirmOne(DartTracker t) {
      t.processFrame(frame([dart()]));
      t.processFrame(frame([dart()]));
    }

    test('auto re-baseline after K consecutive empty frames', () {
      final tracker = DartTracker(); // K = 3
      confirmOne(tracker);
      expect(tracker.confirmedDarts, hasLength(1));

      final e1 = tracker.processFrame(frame(const []));
      expect(e1.status.dartsOnBoard, 1, reason: '1 empty = occlusion, kept');
      expect(e1.status.phase, TrackerPhase.tracking);
      tracker.processFrame(frame(const [])); // empty 2
      final e3 = tracker.processFrame(frame(const [])); // empty 3 → clear
      expect(e3.status.phase, TrackerPhase.rebaselined);
      expect(tracker.confirmedDarts, isEmpty);
    });

    test('board clear does NOT advance the turn (cap counter survives)', () {
      final tracker = DartTracker();
      confirmOne(tracker);
      expect(tracker.dartsThisTurn, 1);
      for (var i = 0; i < 3; i++) {
        tracker.processFrame(frame(const []));
      }
      expect(tracker.confirmedDarts, isEmpty);
      expect(tracker.dartsThisTurn, 1, reason: 're-baseline is not a turn advance');
    });

    test('manual removeDarts clears the board but not the turn counter', () {
      final tracker = DartTracker();
      confirmOne(tracker);
      expect(tracker.dartsThisTurn, 1);
      final cleared = tracker.removeDarts();
      expect(cleared.status.phase, TrackerPhase.rebaselined);
      expect(tracker.confirmedDarts, isEmpty);
      expect(tracker.dartsThisTurn, 1, reason: 'removeDarts is not a turn advance');
    });

    test('a large cal shift is treated as a phone bump', () {
      final tracker = DartTracker();
      confirmOne(tracker);
      expect(tracker.confirmedDarts, hasLength(1));

      // Shift every cal point well past calShiftThreshold (0.08).
      final shifted = [for (final c in cals) (x: c.x + 0.15, y: c.y)];
      final bumped =
          tracker.processFrame(frame([seg(20, rTreble)], c: shifted));
      expect(bumped.status.phase, TrackerPhase.cameraMoved);
      expect(tracker.confirmedDarts, isEmpty);
    });
  });

  group('degraded input', () {
    test('a frame without 4 cal points keeps state untouched', () {
      final tracker = DartTracker();
      tracker.processFrame(frame([seg(20, rTreble)]));
      final confirmed = tracker.processFrame(frame([seg(20, rTreble)]));
      expect(confirmed.status.dartsOnBoard, 1);

      final noCal = tracker.processFrame(
          DetectionFrame(calPoints: const [], dartCandidates: const []));
      expect(noCal.status.phase, TrackerPhase.noCalibration);
      expect(tracker.confirmedDarts, hasLength(1), reason: 'state preserved');
    });
  });

  group('config', () {
    test('confirmFrames = 1 emits on first sighting', () {
      final tracker =
          DartTracker(config: const DartTrackerConfig(confirmFrames: 1));
      final update = tracker.processFrame(frame([seg(20, rTreble)]));
      expect(update.newDarts, hasLength(1));
      expect(update.newDarts.single.score.segment, 'T20');
    });
  });
}
