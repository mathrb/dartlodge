import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the session flushes, so we can assert recording wiring without
/// touching the filesystem.
class _FakeTraceStore implements SessionTraceStore {
  final Map<String, SessionTrace> saved = {};
  int? retainedKeepLast;

  @override
  bool get isSupported => true;

  @override
  Future<void> save(String sessionId, SessionTrace trace) async {
    saved[sessionId] = trace;
  }

  @override
  Future<void> enforceRetention({required int keepLast}) async {
    retainedKeepLast = keepLast;
  }

  @override
  Future<List<String>> list() async => saved.keys.toList();

  @override
  Future<void> clear() async => saved.clear();
}

const _emptyFrame = DetectionFrame(calPoints: [], dartCandidates: []);

void main() {
  test('records each processed frame and flushes the trace on dispose',
      () async {
    final store = _FakeTraceStore();
    final session = AutoScorerSession(
      traceStore: store,
      recordingSessionId: 'sess-1',
      recordingGameId: 'game-1',
      modelVersion: 'model-x',
      recordingStartedAt: DateTime.utc(2026, 6, 13),
    );

    session.processDetectionFrame(
      _emptyFrame,
      rawDetections: const [RawDetection(classIndex: 0, x: 0.5, y: 0.5, conf: 0.8)],
      calConfidence: 0.3,
      dartConfidence: 0.4,
    );
    session.processDetectionFrame(_emptyFrame);

    await session.dispose();

    final trace = store.saved['sess-1'];
    expect(trace, isNotNull);
    expect(trace!.header.gameId, 'game-1');
    expect(trace.header.modelVersion, 'model-x');
    expect(trace.lines.whereType<TrackerSegment>(), hasLength(1));
    final frames = trace.lines.whereType<TraceFrame>().toList();
    expect(frames, hasLength(2));
    expect(frames.first.detections.single.conf, 0.8);
    expect(frames.first.calMinConfidence, 0.3);
    expect(store.retainedKeepLast, 20);
  });

  test('records turn-advance and remove-darts signals between frames', () async {
    final store = _FakeTraceStore();
    final session = AutoScorerSession(
      traceStore: store,
      recordingSessionId: 'sess-sig',
      recordingGameId: 'g',
    );

    session.processDetectionFrame(_emptyFrame);
    session.onTurnAdvanced();
    session.removeDarts();
    session.processDetectionFrame(_emptyFrame);
    await session.dispose();

    final lines = store.saved['sess-sig']!.lines;
    expect(
      lines.whereType<TrackerSignal>().map((s) => s.kind),
      [TrackerSignalKind.turnAdvanced, TrackerSignalKind.removeDarts],
    );
    // The signals sit between the two frames.
    expect(lines.map((l) => l.runtimeType.toString()), [
      'TrackerSegment',
      'TraceFrame',
      'TrackerSignal',
      'TrackerSignal',
      'TraceFrame',
    ]);
  });

  test('no store/sessionId → recording off, dispose writes nothing', () async {
    final session = AutoScorerSession(modelVersion: 'm');
    // Must not throw without a recorder.
    final result = session.processDetectionFrame(_emptyFrame);
    expect(result.emittedDarts, isEmpty);
    await session.dispose(); // no-op flush
  });

  test('zero frames recorded → nothing persisted', () async {
    final store = _FakeTraceStore();
    final session = AutoScorerSession(
      traceStore: store,
      recordingSessionId: 'sess-empty',
      recordingGameId: 'g',
    );
    await session.dispose();
    expect(store.saved, isEmpty);
    expect(store.retainedKeepLast, isNull);
  });
}
