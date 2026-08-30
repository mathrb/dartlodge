import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/recognition_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// The halo (S1.1) and the pips (S1.2) render this one derived state, so these
/// tests are the contract that keeps the two signals in agreement (#739).
void main() {
  const p = (x: 0.5, y: 0.5);

  RecognitionState state(
    List<BoardPoint?> points,
    List<double?> confidences, {
    double threshold = 0.25,
    bool stable = true,
  }) =>
      recognitionStateOf(
        calBestPoints: points,
        calConfidences: confidences,
        calMinConfidence: threshold,
        isStable: stable,
      );

  test('nothing detected — four missing pips, grade none', () {
    final s = state(
        const [null, null, null, null], const [null, null, null, null]);
    expect(s.markers, everyElement(MarkerRecognition.missing));
    expect(s.grade, RecognitionGrade.none);
    expect(s.foundCount, 0);
  });

  test('all four above threshold and steady — grade ready', () {
    final s = state(const [p, p, p, p], const [0.9, 0.8, 0.7, 0.6]);
    expect(s.markers, everyElement(MarkerRecognition.found));
    expect(s.grade, RecognitionGrade.ready);
    expect(s.foundCount, 4);
  });

  test('all four above threshold but not steady — grade partial', () {
    final s =
        state(const [p, p, p, p], const [0.9, 0.8, 0.7, 0.6], stable: false);
    expect(s.markers, everyElement(MarkerRecognition.found));
    expect(s.grade, RecognitionGrade.partial);
    expect(s.foundCount, 4);
  });

  test('a marker seen below the threshold is weak, not missing', () {
    final s = state(const [p, p, p, p], const [0.9, 0.8, 0.7, 0.1]);
    expect(s.markers.last, MarkerRecognition.weak);
    expect(s.foundCount, 3);
    expect(s.grade, RecognitionGrade.partial);
  });

  test('a marker not seen at all is missing even with a stale confidence', () {
    final s = state(const [p, p, p, null], const [0.9, 0.8, 0.7, 0.9]);
    expect(s.markers.last, MarkerRecognition.missing);
    expect(s.foundCount, 3);
  });

  test('confidence exactly at the threshold counts as found', () {
    final s = state(const [p, p, p, p], const [0.25, 0.25, 0.25, 0.25]);
    expect(s.markers, everyElement(MarkerRecognition.found));
    expect(s.grade, RecognitionGrade.ready);
  });

  test('only weak markers grade as partial, not none — nearly, not nothing', () {
    final s = state(const [p, p, p, p], const [0.1, 0.1, 0.1, 0.1]);
    expect(s.markers, everyElement(MarkerRecognition.weak));
    expect(s.foundCount, 0);
    // Red is reserved for seeing nothing at all: an all-weak frame is a small
    // reframe away, and the pips are already amber — the halo must agree.
    expect(s.grade, RecognitionGrade.partial);
  });

  test('a single weak marker is enough to leave the none grade', () {
    final s = state(const [null, null, null, p], const [null, null, null, 0.1]);
    expect(s.foundCount, 0);
    expect(s.grade, RecognitionGrade.partial);
  });

  test('the threshold moves the pips — the same frame at a lower threshold', () {
    const points = [p, p, p, p];
    const confs = [0.9, 0.8, 0.7, 0.2];
    expect(state(points, confs, threshold: 0.25).foundCount, 3);
    expect(state(points, confs, threshold: 0.15).foundCount, 4);
  });

  test('a short or empty cal list still yields four pips', () {
    final s = state(const [], const []);
    expect(s.markers, hasLength(4));
    expect(s.markers, everyElement(MarkerRecognition.missing));
    expect(s.grade, RecognitionGrade.none);
  });
}
