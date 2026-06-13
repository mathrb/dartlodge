import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_recorder.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_replayer.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:flutter_test/flutter_test.dart';

// Four calibration points (DeepDarts order) forming a diamond, plus dart
// candidates inside it. classIndex: 0 = dart, 1..4 = cal1..cal4.
// Convention: cal1=top, cal2=bottom, cal3=left, cal4=right (see scorer tests).
const _cals = [
  RawDetection(classIndex: 1, x: 0.5, y: 0.2, conf: 0.9),
  RawDetection(classIndex: 2, x: 0.5, y: 0.8, conf: 0.9),
  RawDetection(classIndex: 3, x: 0.2, y: 0.5, conf: 0.9),
  RawDetection(classIndex: 4, x: 0.8, y: 0.5, conf: 0.9),
];

RawDetection _dart(double x, double y) =>
    RawDetection(classIndex: 0, x: x, y: y, conf: 0.9);

/// Drives a tracker + recorder in lockstep (exactly as the device session does)
/// to produce a trace, so a fresh-tracker replay must reproduce it.
class _Generator {
  _Generator({DartTrackerConfig config = const DartTrackerConfig()})
      : _tracker = DartTracker(config: config),
        _recorder = SessionRecorder(
          header: SessionTraceHeader(
            modelVersion: 'test',
            gameId: 'g',
            startedAt: DateTime.utc(2026, 6, 13),
          ),
          config: config,
        );

  final DartTracker _tracker;
  final SessionRecorder _recorder;

  void frame(List<RawDetection> raw,
      {double cal = 0.25, double dart = 0.25}) {
    final f = buildDetectionFrame(raw,
        calMinConfidence: cal, dartMinConfidence: dart);
    final update = _tracker.processFrame(f);
    _recorder.recordFrame(
        detections: raw,
        calMinConfidence: cal,
        dartMinConfidence: dart,
        update: update);
  }

  void advanceTurn() {
    _tracker.onTurnAdvanced();
    _recorder.recordSignal(TrackerSignalKind.turnAdvanced);
  }

  SessionTrace build() => _recorder.build();
}

int _emissions(SessionTrace t) => t.lines
    .whereType<TraceFrame>()
    .expand((f) => f.outcome.newDarts)
    .where((d) => d.emitted)
    .length;

/// Drop all signal lines from a trace (simulating a recorder that failed to
/// capture turn advances).
SessionTrace _stripSignals(SessionTrace t) => SessionTrace(
      header: t.header,
      lines: [for (final l in t.lines) if (l is! TrackerSignal) l],
    );

void main() {
  group('SessionReplayer fidelity', () {
    test('replays a generated session bit-for-bit', () {
      final gen = _Generator();
      // Establish calibration, then a dart that persists → confirmed + emitted.
      gen.frame(_cals);
      gen.frame(_cals);
      gen.frame([..._cals, _dart(0.5, 0.5)]);
      gen.frame([..._cals, _dart(0.5, 0.5)]);
      gen.frame([..._cals, _dart(0.5, 0.5)]);
      final trace = gen.build();

      expect(_emissions(trace), greaterThan(0),
          reason: 'scenario should exercise at least one emission');

      final result = const SessionReplayer().replay(trace);
      expect(result.isFaithful, isTrue, reason: result.divergences.join('\n'));
    });

    test('reproduces the cap reset across a recorded turn advance', () {
      // Cap of 1: the first dart fills the turn; a second dart in the same turn
      // is cap-blocked; after a turn advance, a new dart emits again.
      final gen = _Generator(
          config: const DartTrackerConfig(maxDartsPerTurn: 1));
      gen.frame(_cals);
      gen.frame([..._cals, _dart(0.5, 0.5)]);
      gen.frame([..._cals, _dart(0.5, 0.5)]); // dart A → emitted (turn full)
      gen.advanceTurn();
      gen.frame([..._cals, _dart(0.5, 0.5), _dart(0.66, 0.5)]);
      gen.frame([..._cals, _dart(0.5, 0.5), _dart(0.66, 0.5)]); // dart B
      final trace = gen.build();

      // Both darts emitted (cap reset by the turn advance).
      expect(_emissions(trace), 2);
      expect(const SessionReplayer().replay(trace).isFaithful, isTrue);
    });

    test('stripping the turn-advance signal makes the replay diverge', () {
      // Same scenario; without the recorded signal the cap never resets, so the
      // second dart stays cap-blocked on replay → divergence. This is why the
      // signals are recorded (#491).
      final gen = _Generator(
          config: const DartTrackerConfig(maxDartsPerTurn: 1));
      gen.frame(_cals);
      gen.frame([..._cals, _dart(0.5, 0.5)]);
      gen.frame([..._cals, _dart(0.5, 0.5)]);
      gen.advanceTurn();
      gen.frame([..._cals, _dart(0.5, 0.5), _dart(0.66, 0.5)]);
      gen.frame([..._cals, _dart(0.5, 0.5), _dart(0.66, 0.5)]);
      final trace = gen.build();

      final stripped = _stripSignals(trace);
      expect(const SessionReplayer().replay(stripped).isFaithful, isFalse);
    });

    test('empty trace (header + segment only) replays faithfully', () {
      final trace = _Generator().build();
      final result = const SessionReplayer().replay(trace);
      expect(result.frames, isEmpty);
      expect(result.isFaithful, isTrue);
    });
  });
}
