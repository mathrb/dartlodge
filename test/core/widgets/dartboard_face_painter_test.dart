import 'dart:math' as math;

import 'package:dart_lodge/core/widgets/dartboard_face_painter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('board face orientation (#697)', () {
    // Centre angle of the wedge at [index] in the stored canonical frame.
    double centreAngle(int index) =>
        boardSegmentStartAngle(index) + kBoardSegmentSweep / 2;

    test(
        'stored frame: segment 20 sits just clockwise of vertical (5/20 wire '
        'at top)', () {
      // The scorer anchors cal1 (5/20 wire) at the top (-π/2), so the 20 wedge
      // starts there and its centre is half a sweep clockwise.
      expect(boardSegmentStartAngle(0), closeTo(-math.pi / 2, 1e-9));
      expect(centreAngle(0),
          closeTo(-math.pi / 2 + kBoardSegmentSweep / 2, 1e-9));
    });

    test('display rotation brings segment 20 to the vertical top', () {
      // Rotating the wedge layout by the display rotation must put the 20
      // centre straight up (-π/2) — a standard "20 at the top" board.
      expect(
          centreAngle(0) + kBoardDisplayRotation, closeTo(-math.pi / 2, 1e-9));
    });

    test('display rotation is minus half a segment (~9° CCW)', () {
      expect(kBoardDisplayRotation, closeTo(-kBoardSegmentSweep / 2, 1e-12));
      // After rotation the 5/20 wire (stored at top) sits ~9° left of vertical.
      expect(boardSegmentStartAngle(0) + kBoardDisplayRotation,
          closeTo(-math.pi / 2 - kBoardSegmentSweep / 2, 1e-9));
    });
  });

  test('kBoardFaceClockOrder matches a regulation board (20 at top)', () {
    expect(kBoardFaceClockOrder.first, 20);
    expect(kBoardFaceClockOrder.length, 20);
    expect(kBoardFaceClockOrder.toSet().length, 20); // all distinct 1..20
  });

  test('ring radii are ordered from the bull outwards', () {
    expect(kBoardRDoubleBull, lessThan(kBoardRSingleBull));
    expect(kBoardRSingleBull, lessThan(kBoardRTripleInner));
    expect(kBoardRTripleInner, lessThan(kBoardRTripleOuter));
    expect(kBoardRTripleOuter, lessThan(kBoardRDoubleInner));
    expect(kBoardRDoubleInner, lessThan(kBoardRDoubleOuter));
    expect(kBoardRDoubleOuter, lessThan(1.0));
  });
}
