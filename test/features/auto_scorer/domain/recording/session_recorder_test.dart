import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_recorder.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/scoring/dartboard_scorer.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracked_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:flutter_test/flutter_test.dart';

SessionRecorder _recorder({DartTrackerConfig config = const DartTrackerConfig()}) =>
    SessionRecorder(
      header: SessionTraceHeader(
        modelVersion: 'm',
        gameId: 'g',
        startedAt: DateTime.utc(2026, 6, 13),
      ),
      config: config,
    );

TrackerUpdate _update(List<TrackedDart> newDarts, TrackerPhase phase,
        {int onBoard = 0, int thisTurn = 0}) =>
    TrackerUpdate(
      newDarts: newDarts,
      status: TrackerStatus(
          phase: phase, dartsOnBoard: onBoard, dartsThisTurn: thisTurn),
    );

TrackedDart _dart(int handle, ScoredDart score, {bool emitted = true}) =>
    TrackedDart(
      handle: handle,
      boardPosition: (x: 0.5, y: 0.5),
      score: score,
      emitted: emitted,
    );

void main() {
  test('emits the initial tracker segment on construction', () {
    final trace = _recorder(
            config: const DartTrackerConfig(confirmFrames: 4, maxDartsPerTurn: 9))
        .build();

    final segment = trace.lines.whereType<TrackerSegment>().single;
    expect(segment.instance, 0);
    expect(segment.config.confirmFrames, 4);
    expect(segment.config.maxDartsPerTurn, 9);
    expect(trace.lines.whereType<TraceFrame>(), isEmpty);
  });

  test('records frames with monotonic indices, thresholds, raw detections', () {
    final rec = _recorder();
    rec.recordFrame(
      detections: const [],
      calMinConfidence: 0.25,
      dartMinConfidence: 0.3,
      update: _update(const [], TrackerPhase.idle),
    );
    rec.recordFrame(
      detections: const [RawDetection(classIndex: 0, x: 0.5, y: 0.5, conf: 0.9)],
      calMinConfidence: 0.4,
      dartMinConfidence: 0.5,
      update: _update(const [], TrackerPhase.tracking, onBoard: 0),
    );

    expect(rec.frameCount, 2);
    final frames = rec.build().lines.whereType<TraceFrame>().toList();
    expect(frames.map((f) => f.frameIndex), [0, 1]);
    expect(frames[0].calMinConfidence, 0.25);
    expect(frames[1].dartMinConfidence, 0.5);
    expect(frames[1].detections.single.conf, 0.9);
  });

  test('maps TrackedDart outcome (handle/segment/emitted) into the frame', () {
    final rec = _recorder();
    rec.recordFrame(
      detections: const [],
      calMinConfidence: 0.25,
      dartMinConfidence: 0.25,
      update: _update(
        [
          _dart(7, ScoredDart.triple(20)),
          _dart(8, ScoredDart.singleBull(), emitted: false), // cap-blocked
        ],
        TrackerPhase.turnFull,
        onBoard: 4,
        thisTurn: 3,
      ),
    );

    final frame = rec.build().lines.whereType<TraceFrame>().single;
    expect(frame.outcome.status.phase, TrackerPhase.turnFull);
    expect(frame.outcome.status.dartsThisTurn, 3);
    expect(frame.outcome.newDarts, hasLength(2));

    final first = frame.outcome.newDarts.first;
    expect(first.handle, 7);
    expect(first.segment, 'T20');
    expect(first.baseNumber, 20);
    expect(first.multiplier, 3);
    expect(first.emitted, isTrue);

    final capped = frame.outcome.newDarts[1];
    expect(capped.handle, 8);
    expect(capped.segment, 'SB');
    expect(capped.emitted, isFalse);
  });

  test('recordSignal appends a signal line without advancing the frame index',
      () {
    final rec = _recorder();
    rec.recordFrame(
      detections: const [],
      calMinConfidence: 0.25,
      dartMinConfidence: 0.25,
      update: _update(const [], TrackerPhase.tracking),
    );
    rec.recordSignal(TrackerSignalKind.turnAdvanced);
    rec.recordFrame(
      detections: const [],
      calMinConfidence: 0.25,
      dartMinConfidence: 0.25,
      update: _update(const [], TrackerPhase.idle),
    );

    expect(rec.frameCount, 2); // the signal does not count as a frame
    final lines = rec.build().lines;
    expect(lines.whereType<TrackerSignal>().single.kind,
        TrackerSignalKind.turnAdvanced);
    // Order preserved: segment, frame, signal, frame.
    expect(lines.map((l) => l.runtimeType.toString()), [
      'TrackerSegment',
      'TraceFrame',
      'TrackerSignal',
      'TraceFrame',
    ]);
  });

  test('built trace round-trips through JSONL', () {
    final rec = _recorder();
    rec.recordFrame(
      detections: const [RawDetection(classIndex: 1, x: 0.1, y: 0.2, conf: 0.7)],
      calMinConfidence: 0.25,
      dartMinConfidence: 0.3,
      update: _update([_dart(1, ScoredDart.single(20))], TrackerPhase.tracking,
          onBoard: 1, thisTurn: 1),
    );
    final jsonl = rec.build().toJsonl();
    expect(SessionTrace.fromJsonl(jsonl).toJsonl(), jsonl);
  });

  test('build() snapshots — later frames do not mutate an earlier snapshot', () {
    final rec = _recorder();
    final before = rec.build();
    rec.recordFrame(
      detections: const [],
      calMinConfidence: 0.25,
      dartMinConfidence: 0.25,
      update: _update(const [], TrackerPhase.idle),
    );
    expect(before.lines.whereType<TraceFrame>(), isEmpty);
    expect(rec.build().lines.whereType<TraceFrame>(), hasLength(1));
  });
}
