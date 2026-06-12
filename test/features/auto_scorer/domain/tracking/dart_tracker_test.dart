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

    test('a dart thrown while a cal dot is occluded still scores (#485)', () {
      final tracker = DartTracker();
      final first = seg(20, rTreble);
      tracker.processFrame(frame([first]));
      tracker.processFrame(frame([first])); // T20 confirmed; transform held.

      // The planted dart (or the player's arm) now masks one cal dot — only
      // 3 of 4 cals visible for the rest of the turn.
      final occluded = cals.sublist(0, 3);
      final second = seg(19, rTreble);
      final sighting = tracker.processFrame(
          DetectionFrame(calPoints: occluded, dartCandidates: [first, second]));
      expect(sighting.newDarts, isEmpty, reason: 'pending after 1 sighting');

      final emitted = tracker.processFrame(
          DetectionFrame(calPoints: occluded, dartCandidates: [first, second]));
      expect(emitted.newDarts, hasLength(1),
          reason: 'the held homography keeps mapping darts (#485)');
      expect(emitted.newDarts.single.score.segment, 'T19');
      expect(emitted.status.dartsOnBoard, 2);
      expect(emitted.status.phase, TrackerPhase.tracking);
    });

    test('without a held transform, occluded-cal darts still do not score',
        () {
      final tracker = DartTracker();
      // Never calibrated: a 3-cal frame with darts must stay status-only.
      final update = tracker.processFrame(DetectionFrame(
          calPoints: cals.sublist(0, 3), dartCandidates: [seg(20, rTreble)]));
      expect(update.newDarts, isEmpty);
      expect(update.status.phase, TrackerPhase.noCalibration);
      expect(tracker.confirmedDarts, isEmpty);
    });

    test('reframing across a re-baseline is NOT a phone bump', () {
      final tracker = DartTracker(
          config: const DartTrackerConfig(emptyFramesToRebaseline: 2));
      final dart = seg(20, rTreble);
      tracker.processFrame(frame([dart]));
      tracker.processFrame(frame([dart])); // confirmed; bump baseline = cals

      // Darts pulled → empty streak → auto re-baseline.
      tracker.processFrame(frame(const []));
      final cleared = tracker.processFrame(frame(const []));
      expect(cleared.status.phase, TrackerPhase.rebaselined);

      // The user reframes the phone between games: the next occupied frame
      // carries shifted cals. The transform is re-derived fresh, so this must
      // NOT fire cameraMoved off the pre-baseline cal set.
      final shifted = [for (final c in cals) (x: c.x + 0.15, y: c.y)];
      tracker.processFrame(frame([dart], c: shifted));
      final emitted = tracker.processFrame(frame([dart], c: shifted));
      expect(emitted.status.phase, TrackerPhase.tracking);
      expect(emitted.newDarts, hasLength(1));
    });

    test('a phone bump during cal occlusion is caught when cals reappear', () {
      final tracker = DartTracker();
      final dart = seg(20, rTreble);
      tracker.processFrame(frame([dart]));
      tracker.processFrame(frame([dart])); // confirmed; _lastCals = cals

      // Occluded frames keep scoring off the held transform...
      tracker.processFrame(
          DetectionFrame(calPoints: cals.sublist(0, 3), dartCandidates: [dart]));

      // ...and when the cals reappear SHIFTED (the phone was bumped while the
      // dots were hidden), the mean-shift check against the pre-occlusion set
      // still fires the re-baseline.
      final shifted = [for (final c in cals) (x: c.x + 0.15, y: c.y)];
      final bumped = tracker.processFrame(frame([dart], c: shifted));
      expect(bumped.status.phase, TrackerPhase.cameraMoved);
      expect(tracker.confirmedDarts, isEmpty);
    });
  });

  group('close grouping (#454)', () {
    // Canonical distance for an image-space offset: cals give centre (0.5,0.5)
    // and radius 0.3, so a normalised point is (img-0.5)/0.3 and a δ in image
    // space is δ/0.3 in board-radius units. An 0.012 image offset ⇒ 0.04
    // board-radius — inside matchTolerance (0.06), i.e. ≈1 cm same-bed grouping.
    final a = seg(20, rTreble);
    final bClose = (x: a.x + 0.012, y: a.y); // ~0.04 board-radius from a

    test('the close offset is genuinely within matchTolerance', () {
      double norm(double v) => (v - 0.5) / 0.3;
      final d = math.sqrt(
        math.pow(norm(a.x) - norm(bClose.x), 2) +
            math.pow(norm(a.y) - norm(bClose.y), 2),
      );
      expect(d, lessThan(const DartTrackerConfig().matchTolerance),
          reason: 'test premise: the two darts are closer than the tolerance');
    });

    test('a 2nd dart thrown next to an existing one is still counted', () {
      final tracker = DartTracker();
      // Dart A lands and confirms.
      tracker.processFrame(frame([a]));
      final afterA = tracker.processFrame(frame([a]));
      expect(afterA.newDarts, hasLength(1));
      expect(afterA.status.dartsOnBoard, 1);

      // Dart B is thrown into the same bed, within matchTolerance of A. A is
      // still physically present, so every frame shows both boxes.
      final b1 = tracker.processFrame(frame([a, bClose]));
      expect(b1.newDarts, isEmpty, reason: 'B pending after 1 frame');
      final b2 = tracker.processFrame(frame([a, bClose]));
      expect(b2.newDarts, hasLength(1), reason: 'B confirms — not swallowed by A');
      expect(b2.status.dartsOnBoard, 2);
      expect(tracker.dartsThisTurn, 2);
    });

    test('detector candidate order does not matter (no phantom)', () {
      // The detector does not guarantee spatial ordering. With B's box listed
      // BEFORE A's, a candidate-driven greedy match would let B claim A's slot
      // and route A's own re-detection into pending → phantom duplicate of A.
      // Confirmed-driven matching recognises A's re-detection regardless.
      final tracker = DartTracker();
      tracker.processFrame(frame([a]));
      tracker.processFrame(frame([a])); // A confirmed

      // bClose first, then a — the order that would trip greedy matching.
      tracker.processFrame(frame([bClose, a]));
      final settled = tracker.processFrame(frame([bClose, a]));
      expect(settled.status.dartsOnBoard, 2, reason: 'A + B, no phantom');
      expect(tracker.dartsThisTurn, 2);
      // Exactly the two physical darts are tracked — not three.
      expect(tracker.confirmedDarts, hasLength(2));
    });

    test('a stationary single dart still emits exactly once (no double-count)',
        () {
      // The dedup this fix preserves: one confirmed dart claims its own
      // re-detection each frame and never spawns a phantom.
      final tracker = DartTracker();
      var emitted = 0;
      for (var i = 0; i < 6; i++) {
        emitted += tracker.processFrame(frame([a])).newDarts.length;
      }
      expect(emitted, 1);
      expect(tracker.confirmedDarts, hasLength(1));
    });

    test('two close darts arriving in the same frame both confirm', () {
      // Guards the pending path stays intact (already one-to-one).
      final tracker = DartTracker();
      tracker.processFrame(frame([a, bClose]));
      final confirmed = tracker.processFrame(frame([a, bClose]));
      expect(confirmed.newDarts, hasLength(2));
      expect(confirmed.status.dartsOnBoard, 2);
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

  group('calibration loss (#377 §5.2)', () {
    const noCalEmpty =
        DetectionFrame(calPoints: [], dartCandidates: []);

    test('sustained no-cal-and-no-darts escalates to needsCalibration', () {
      final tracker =
          DartTracker(config: const DartTrackerConfig(noCalibrationFramesToWarn: 3));
      expect(tracker.processFrame(noCalEmpty).status.phase,
          TrackerPhase.noCalibration);
      expect(tracker.processFrame(noCalEmpty).status.phase,
          TrackerPhase.noCalibration);
      expect(tracker.processFrame(noCalEmpty).status.phase,
          TrackerPhase.needsCalibration);
    });

    test('a no-cal frame that still sees darts resets the warning counter', () {
      final tracker =
          DartTracker(config: const DartTrackerConfig(noCalibrationFramesToWarn: 3));
      final noCalWithDart =
          DetectionFrame(calPoints: const [], dartCandidates: [seg(20, rTreble)]);
      tracker.processFrame(noCalEmpty); // 1
      tracker.processFrame(noCalEmpty); // 2
      // Darts visible but board not located → transient occlusion, not "blind".
      expect(tracker.processFrame(noCalWithDart).status.phase,
          TrackerPhase.noCalibration);
      // Counter reset, so the next empty frame is back to 1 (still transient).
      expect(tracker.processFrame(noCalEmpty).status.phase,
          TrackerPhase.noCalibration);
    });

    test('regaining calibration clears the warning', () {
      final tracker =
          DartTracker(config: const DartTrackerConfig(noCalibrationFramesToWarn: 2));
      tracker.processFrame(noCalEmpty);
      expect(tracker.processFrame(noCalEmpty).status.phase,
          TrackerPhase.needsCalibration);
      // A calibrated (empty board) frame resets and reports idle again.
      expect(tracker.processFrame(frame(const [])).status.phase,
          TrackerPhase.idle);
    });
  });
}
