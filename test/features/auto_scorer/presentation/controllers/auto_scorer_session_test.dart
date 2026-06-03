import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/corrected_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/retention_policy.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Fake detector that returns a fixed [DetectionFrame] regardless of the bytes,
/// so the session can be driven deterministically without a model/camera.
class _FakeDetector implements DartDetector {
  _FakeDetector(this.frame);
  DetectionFrame frame;
  bool loaded = false;
  @override
  bool get isSupported => true;
  @override
  Future<bool> load() async {
    loaded = true;
    return true;
  }

  @override
  Future<DetectionFrame> detect(Uint8List frameBytes) async => frame;

  @override
  Future<void> dispose() async {}
}

class _FakeCaptureStore implements CaptureStore {
  final List<CaptureRecord> saved = [];
  final List<Uint8List> savedBytes = [];
  @override
  bool get isSupported => true;
  @override
  Future<void> save(CaptureRecord record, Uint8List frameBytes) async {
    saved.add(record);
    savedBytes.add(frameBytes);
  }
  @override
  Future<void> applyCorrection(
      String gameId, CaptureHandle handle, List<CorrectedDart> c) async {}
  @override
  Future<List<CaptureRecord>> list() async => saved;
  int retentionCalls = 0;
  @override
  Future<void> enforceRetention(RetentionPolicy policy) async =>
      retentionCalls++;
  @override
  Future<Uint8List> buildExportZip() async => Uint8List(0);
  @override
  Future<void> clear() async => saved.clear();
}

void main() {
  // Centred-square cals → image space == canonical; a candidate at (0.5,0.35)
  // is above centre (single 5 region) and scores once confirmed.
  const cals = <BoardPoint>[
    (x: 0.5, y: 0.2),
    (x: 0.5, y: 0.8),
    (x: 0.2, y: 0.5),
    (x: 0.8, y: 0.5),
  ];
  final oneDartFrame = DetectionFrame(
    calPoints: cals,
    dartCandidates: const [(x: 0.5, y: 0.35)],
  );
  final bytes = Uint8List.fromList(const [1, 2, 3]);

  test('start loads the detector', () async {
    final detector = _FakeDetector(oneDartFrame);
    final session = AutoScorerSession(detector: detector);
    expect(await session.start(), isTrue);
    expect(detector.loaded, isTrue);
  });

  test('start enforces the retention cap (bounds storage growth, #381)', () async {
    final store = _FakeCaptureStore();
    final session =
        AutoScorerSession(detector: _FakeDetector(oneDartFrame), captureStore: store);
    await session.start();
    expect(store.retentionCalls, 1);
  });

  test('emits a dart after confirm-before-emit (2 frames)', () async {
    final session = AutoScorerSession(detector: _FakeDetector(oneDartFrame));
    final first = await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    expect(first.emittedDarts, isEmpty);
    final second = await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    expect(second.emittedDarts, hasLength(1));
  });

  test('onFrame reports detect + track timings (#377 §3 diagnostics)', () async {
    final session = AutoScorerSession(detector: _FakeDetector(oneDartFrame));
    final result = await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    // Capture is filled in by the camera caller, not the session.
    expect(result.timings.capture, Duration.zero);
    expect(result.timings.detect, greaterThanOrEqualTo(Duration.zero));
    expect(result.timings.track, greaterThanOrEqualTo(Duration.zero));
  });


  test('captures the frame when data collection is on', () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(
        detector: _FakeDetector(oneDartFrame),
        captureStore: store,
        modelVersion: 'test-v1');
    await session.onFrame(bytes, turnOrdinal: 4, gameId: 'g', collectData: true);
    await session.onFrame(bytes, turnOrdinal: 4, gameId: 'g', collectData: true);
    expect(store.saved, hasLength(1));
    expect(store.saved.single.gameId, 'g');
    expect(store.saved.single.handle, const CaptureHandle(turnOrdinal: 4, dartInTurnOrdinal: 1));
    expect(store.saved.single.modelVersion, 'test-v1');
  });

  test('stores the raw frame unchanged (detections are normalised to it)', () async {
    // Inference runs on the raw frame, so coords are normalised to it — the
    // stored image must be that same raw frame, not a cropped/resized one
    // (#377 §3; the alignment invariant of #390, now on the raw frame).
    final raw = img.encodePng(img.Image(width: 1200, height: 800));
    final store = _FakeCaptureStore();
    final session =
        AutoScorerSession(detector: _FakeDetector(oneDartFrame), captureStore: store);
    await session.onFrame(raw, turnOrdinal: 1, gameId: 'g', collectData: true);
    await session.onFrame(raw, turnOrdinal: 1, gameId: 'g', collectData: true);

    expect(store.savedBytes, hasLength(1));
    expect(store.savedBytes.single, same(raw)); // stored verbatim, no resize
  });

  test('does not capture when data collection is off', () async {
    final store = _FakeCaptureStore();
    final session =
        AutoScorerSession(detector: _FakeDetector(oneDartFrame), captureStore: store);
    await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    expect(store.saved, isEmpty);
  });

  test('captureCurrentFrame stores the raw frame under a manual handle (missed dart)',
      () async {
    final raw = img.encodePng(img.Image(width: 1200, height: 800));
    final store = _FakeCaptureStore();
    final session =
        AutoScorerSession(detector: _FakeDetector(oneDartFrame), captureStore: store);

    final saved = await session.captureCurrentFrame(raw, turnOrdinal: 2, gameId: 'g');
    expect(saved, isTrue);
    expect(store.saved, hasLength(1));
    expect(store.saved.single.handle,
        const CaptureHandle.manual(turnOrdinal: 2, sequence: 1));
    expect(store.savedBytes.single, same(raw)); // raw frame stored verbatim
  });

  test('captureCurrentFrame is a no-op without a capture store', () async {
    final session = AutoScorerSession(detector: _FakeDetector(oneDartFrame));
    expect(
        await session.captureCurrentFrame(bytes, turnOrdinal: 1, gameId: 'g'),
        isFalse);
  });

  test('removeDarts re-baselines (clears the board) and reports status', () async {
    final session = AutoScorerSession(detector: _FakeDetector(oneDartFrame));
    await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g'); // dart on board
    expect(session.dartsOnBoard, 1);
    final status = session.removeDarts();
    expect(status.phase, TrackerPhase.rebaselined);
    expect(session.dartsOnBoard, 0);
  });
}
