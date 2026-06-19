import 'dart:typed_data';
import 'package:dart_lodge/features/auto_scorer/data/preprocessing/image_frame_preprocessor.dart';

import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/corrected_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/retention_policy.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
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

  /// Records the most recent args so tests can assert threading.
  bool lastSkipPreprocess = false;
  double lastCalConfidence = -1;
  double lastDartConfidence = -1;
  @override
  Future<DetectionFrame> detect(
    Uint8List frameBytes, {
    bool skipPreprocess = false,
    double calConfidence = 0.25,
    double dartConfidence = 0.25,
  }) async {
    lastSkipPreprocess = skipPreprocess;
    lastCalConfidence = calConfidence;
    lastDartConfidence = dartConfidence;
    return frame;
  }

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
  final List<({String gameId, CaptureHandle handle, List<CorrectedDart> corrected})>
      corrections = [];
  @override
  Future<void> applyCorrection(
      String gameId, CaptureHandle handle, List<CorrectedDart> c) async {
    corrections.add((gameId: gameId, handle: handle, corrected: c));
  }
  @override
  Future<List<CaptureRecord>> list() async => saved;
  int retentionCalls = 0;
  @override
  Future<void> enforceRetention(RetentionPolicy policy) async =>
      retentionCalls++;
  @override
  Future<void> writeExportZip(String destPath,
      {void Function(double)? onProgress}) async {}
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
    final session = AutoScorerSession(preprocessor: const ImageFramePreprocessor(), detector: detector);
    expect(await session.start(), isTrue);
    expect(detector.loaded, isTrue);
  });

  test('start enforces the retention cap (bounds storage growth, #381)', () async {
    final store = _FakeCaptureStore();
    final session =
        AutoScorerSession(preprocessor: const ImageFramePreprocessor(), detector: _FakeDetector(oneDartFrame), captureStore: store);
    await session.start();
    expect(store.retentionCalls, 1);
  });

  test('emits a dart after confirm-before-emit (2 frames)', () async {
    final session = AutoScorerSession(preprocessor: const ImageFramePreprocessor(), detector: _FakeDetector(oneDartFrame));
    final first = await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    expect(first.emittedDarts, isEmpty);
    final second = await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    expect(second.emittedDarts, hasLength(1));
  });

  test('onFrame reports detect + track timings (#377 §3 diagnostics)', () async {
    final session = AutoScorerSession(preprocessor: const ImageFramePreprocessor(), detector: _FakeDetector(oneDartFrame));
    final result = await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    // Capture is filled in by the camera caller, not the session.
    expect(result.timings.capture, Duration.zero);
    expect(result.timings.detect, greaterThanOrEqualTo(Duration.zero));
    expect(result.timings.track, greaterThanOrEqualTo(Duration.zero));
  });

  test('skipPreprocess threads to the detector', () async {
    final detector = _FakeDetector(oneDartFrame);
    final session = AutoScorerSession(preprocessor: const ImageFramePreprocessor(), detector: detector);
    await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g', skipPreprocess: true);
    expect(detector.lastSkipPreprocess, isTrue);
  });

  test('confidence thresholds thread to the detector', () async {
    final detector = _FakeDetector(oneDartFrame);
    final session = AutoScorerSession(
        preprocessor: const ImageFramePreprocessor(), detector: detector);
    await session.onFrame(bytes,
        turnOrdinal: 1, gameId: 'g', calConfidence: 0.12, dartConfidence: 0.4);
    expect(detector.lastCalConfidence, 0.12);
    expect(detector.lastDartConfidence, 0.4);
  });

  test('detectOnly returns the detector frame and threads its args', () async {
    final detector = _FakeDetector(oneDartFrame);
    final session = AutoScorerSession(
        preprocessor: const ImageFramePreprocessor(), detector: detector);
    final frame = await session.detectOnly(bytes,
        skipPreprocess: true, calConfidence: 0.1, dartConfidence: 0.4);
    expect(identical(frame, oneDartFrame), isTrue);
    expect(detector.lastSkipPreprocess, isTrue);
    expect(detector.lastCalConfidence, 0.1);
    expect(detector.lastDartConfidence, 0.4);
  });

  test('detectOnly runs neither the tracker nor capture', () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(
        preprocessor: const ImageFramePreprocessor(),
        detector: _FakeDetector(oneDartFrame),
        captureStore: store);
    // Two onFrame calls would confirm+emit a dart and capture it; detectOnly
    // must do neither, no matter how many times it's called.
    await session.detectOnly(bytes);
    await session.detectOnly(bytes);
    expect(session.dartsOnBoard, 0);
    expect(store.saved, isEmpty);
  });

  test('onFrame surfaces the detector cal confidences', () async {
    final frame = DetectionFrame(
      calPoints: const [],
      dartCandidates: const [],
      calConfidences: const [0.9, null, 0.3, 0.8],
    );
    final session = AutoScorerSession(
        preprocessor: const ImageFramePreprocessor(),
        detector: _FakeDetector(frame));
    final result = await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    expect(result.calConfidences, const [0.9, null, 0.3, 0.8]);
  });

  test('skipPreprocess stores the raw frame verbatim with raw-space sidecar',
      () async {
    // A real (non-square) camera frame so we can confirm it is stored as-is,
    // not re-encoded to 800×800 (raw-capture brief).
    final raw = img.encodePng(img.Image(width: 1200, height: 800));
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(
        preprocessor: const ImageFramePreprocessor(),
        detector: _FakeDetector(oneDartFrame),
        captureStore: store);
    // Two frames confirm+emit a dart, which is captured.
    await session.onFrame(raw,
        turnOrdinal: 1, gameId: 'g', collectData: true, skipPreprocess: true);
    await session.onFrame(raw,
        turnOrdinal: 1, gameId: 'g', collectData: true, skipPreprocess: true);

    expect(store.savedBytes, hasLength(1));
    // Stored bytes are the raw frame, byte-for-byte (no re-encode).
    expect(store.savedBytes.single, raw);
    final record = store.saved.single;
    expect(record.frameSpace, FrameSpace.raw);
    expect(record.frameWidth, 1200);
    expect(record.frameHeight, 800);
  });

  test('captures the frame when data collection is on', () async {
    // A decodable frame: the non-skip path letterboxes it (an undecodable
    // frame can't be aligned and is intentionally not captured).
    final raw = img.encodePng(img.Image(width: 1200, height: 800));
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(preprocessor: const ImageFramePreprocessor(),
        detector: _FakeDetector(oneDartFrame),
        captureStore: store,
        modelVersion: 'test-v1');
    await session.onFrame(raw, turnOrdinal: 4, gameId: 'g', collectData: true);
    await session.onFrame(raw, turnOrdinal: 4, gameId: 'g', collectData: true);
    expect(store.saved, hasLength(1));
    expect(store.saved.single.gameId, 'g');
    expect(store.saved.single.handle, const CaptureHandle(turnOrdinal: 4, dartInTurnOrdinal: 1));
    expect(store.saved.single.modelVersion, 'test-v1');
    expect(store.saved.single.trigger, CaptureTrigger.auto);
  });

  test('stores the 800×800 preprocessed frame, not the raw camera bytes', () async {
    // A real (non-square) camera frame so we can see it gets cropped+resized.
    final raw = img.encodePng(img.Image(width: 1200, height: 800));
    final store = _FakeCaptureStore();
    final session =
        AutoScorerSession(preprocessor: const ImageFramePreprocessor(), detector: _FakeDetector(oneDartFrame), captureStore: store);
    await session.onFrame(raw, turnOrdinal: 1, gameId: 'g', collectData: true);
    await session.onFrame(raw, turnOrdinal: 1, gameId: 'g', collectData: true);

    expect(store.savedBytes, hasLength(1));
    final stored = img.decodeImage(store.savedBytes.single)!;
    expect(stored.width, 800);
    expect(stored.height, 800); // aligns with the 800×800-normalised sidecar coords
    final record = store.saved.single;
    expect(record.frameSpace, FrameSpace.letterbox800);
    expect(record.frameWidth, 800);
    expect(record.frameHeight, 800);
  });

  test('non-skip mode skips capture when the frame cannot be letterboxed', () async {
    // Undecodable bytes: the detector's coords would be 800-space but there is
    // no 800 image to align them to, so nothing is stored (no mislabeled raw).
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(
        preprocessor: const ImageFramePreprocessor(),
        detector: _FakeDetector(oneDartFrame),
        captureStore: store);
    await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g', collectData: true);
    await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g', collectData: true);
    expect(store.saved, isEmpty);
    // Manual capture likewise reports "not saved".
    expect(
        await session.captureCurrentFrame(bytes, turnOrdinal: 1, gameId: 'g'),
        isFalse);
  });

  test('does not capture when data collection is off', () async {
    final store = _FakeCaptureStore();
    final session =
        AutoScorerSession(preprocessor: const ImageFramePreprocessor(), detector: _FakeDetector(oneDartFrame), captureStore: store);
    await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    expect(store.saved, isEmpty);
  });

  test('captureCurrentFrame stores a manual-handle 800×800 frame (missed dart)', () async {
    final raw = img.encodePng(img.Image(width: 1200, height: 800));
    final store = _FakeCaptureStore();
    final session =
        AutoScorerSession(preprocessor: const ImageFramePreprocessor(), detector: _FakeDetector(oneDartFrame), captureStore: store);

    final saved = await session.captureCurrentFrame(raw, turnOrdinal: 2, gameId: 'g');
    expect(saved, isTrue);
    expect(store.saved, hasLength(1));
    expect(store.saved.single.handle,
        const CaptureHandle.manual(turnOrdinal: 2, sequence: 1));
    expect(store.saved.single.trigger, CaptureTrigger.manual);
    final stored = img.decodeImage(store.savedBytes.single)!;
    expect(stored.width, 800);
    expect(stored.height, 800);
  });

  test('captureCurrentFrame stores the raw frame verbatim in skip mode', () async {
    final raw = img.encodePng(img.Image(width: 1200, height: 800));
    final store = _FakeCaptureStore();
    final detector = _FakeDetector(oneDartFrame);
    final session = AutoScorerSession(
        preprocessor: const ImageFramePreprocessor(),
        detector: detector,
        captureStore: store);

    final saved = await session.captureCurrentFrame(raw,
        turnOrdinal: 2, gameId: 'g', skipPreprocess: true);
    expect(saved, isTrue);
    // skipPreprocess threads through to the detector too.
    expect(detector.lastSkipPreprocess, isTrue);
    expect(store.savedBytes.single, raw); // verbatim, no re-encode
    final record = store.saved.single;
    expect(record.frameSpace, FrameSpace.raw);
    expect(record.frameWidth, 1200);
    expect(record.frameHeight, 800);
  });

  test('captureCurrentFrame is a no-op without a capture store', () async {
    final session = AutoScorerSession(preprocessor: const ImageFramePreprocessor(), detector: _FakeDetector(oneDartFrame));
    expect(
        await session.captureCurrentFrame(bytes, turnOrdinal: 1, gameId: 'g'),
        isFalse);
  });

  test('removeDarts re-baselines (clears the board) and reports status', () async {
    final session = AutoScorerSession(preprocessor: const ImageFramePreprocessor(), detector: _FakeDetector(oneDartFrame));
    await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g');
    await session.onFrame(bytes, turnOrdinal: 1, gameId: 'g'); // dart on board
    expect(session.dartsOnBoard, 1);
    final status = session.removeDarts();
    expect(status.phase, TrackerPhase.rebaselined);
    expect(session.dartsOnBoard, 0);
  });

  // --- YOLOView streaming path (no predict detector) ---

  test('processDetectionFrame emits after confirm, with NO detector', () {
    // Constructed without a detector/preprocessor (the YOLOView path).
    final session = AutoScorerSession();
    expect(session.processDetectionFrame(oneDartFrame).emittedDarts, isEmpty);
    expect(
        session.processDetectionFrame(oneDartFrame).emittedDarts, hasLength(1));
  });

  test('emitted darts carry the normalised canonical impact position', () {
    // Centred-square cals (centre (0.5,0.5), radius 0.3); candidate at image
    // (0.5, 0.35) → canonical ((0.5-0.5)/0.3, (0.35-0.5)/0.3) = (0.0, -0.5):
    // dead-centre horizontally, half-way to the top double ring.
    final session = AutoScorerSession();
    session.processDetectionFrame(oneDartFrame); // pending
    final r = session.processDetectionFrame(oneDartFrame); // confirm + emit
    expect(r.emittedDarts, hasLength(1));
    final d = r.emittedDarts.single;
    expect(d.x, isNotNull);
    expect(d.y, isNotNull);
    expect(d.x!, closeTo(0.0, 1e-9));
    expect(d.y!, closeTo(-0.5, 1e-9));
    expect(d.segment, d.score.segment); // getter mirrors the score
  });

  test('processDetectionFrame surfaces status + cal confidences (track-only)',
      () {
    final frame = DetectionFrame(
      calPoints: const [],
      dartCandidates: const [],
      calConfidences: const [0.9, null, 0.3, 0.8],
    );
    final session = AutoScorerSession();
    final result = session.processDetectionFrame(frame);
    expect(result.calConfidences, const [0.9, null, 0.3, 0.8]);
    expect(result.timings.detect, Duration.zero); // no detector ran
    expect(result.timings.track, greaterThanOrEqualTo(Duration.zero));
  });

  test('persistEmittedDarts stores raw-space records with correct handles', () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(captureStore: store);
    // Confirm+emit one dart so dartsThisTurn == 1.
    session.processDetectionFrame(oneDartFrame);
    final r = session.processDetectionFrame(oneDartFrame);
    expect(r.emittedDarts, hasLength(1));
    expect(r.firstEmittedDartOrdinal, 1); // snapshotted at emission time

    final raw = Uint8List.fromList(const [9, 9, 9]);
    await session.persistEmittedDarts(oneDartFrame, raw,
        turnOrdinal: 3,
        firstDartOrdinal: r.firstEmittedDartOrdinal!,
        gameId: 'g',
        count: r.emittedDarts.length);

    expect(store.savedBytes, hasLength(1));
    expect(store.savedBytes.single, raw); // verbatim
    final record = store.saved.single;
    expect(record.frameSpace, FrameSpace.raw);
    expect(record.frameWidth, 0);
    expect(record.frameHeight, 0);
    expect(record.handle,
        const CaptureHandle(turnOrdinal: 3, dartInTurnOrdinal: 1));
    expect(record.trigger, CaptureTrigger.auto);
  });

  test('persistEmittedDarts records the model conf, not a placeholder (#501)',
      () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(captureStore: store);
    // A frame built through the real detector mapping carries dartConfidences.
    final confFrame = buildDetectionFrame(const [
      RawDetection(classIndex: 1, x: 0.5, y: 0.2, conf: 0.9),
      RawDetection(classIndex: 2, x: 0.5, y: 0.8, conf: 0.9),
      RawDetection(classIndex: 3, x: 0.2, y: 0.5, conf: 0.9),
      RawDetection(classIndex: 4, x: 0.8, y: 0.5, conf: 0.9),
      RawDetection(classIndex: 0, x: 0.5, y: 0.35, conf: 0.73), // the dart
    ]);
    session.processDetectionFrame(confFrame);
    final r = session.processDetectionFrame(confFrame);
    expect(r.emittedDarts, hasLength(1));

    await session.persistEmittedDarts(confFrame, Uint8List.fromList(const [1]),
        turnOrdinal: 1,
        firstDartOrdinal: r.firstEmittedDartOrdinal!,
        gameId: 'g',
        count: r.emittedDarts.length);

    final record = store.saved.single;
    expect(record.predictedDarts.single.conf, closeTo(0.73, 1e-9));
  });

  test('persistEmittedDarts falls back to conf 1.0 for a frame without '
      'dartConfidences', () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(captureStore: store);
    // oneDartFrame is built manually (no dartConfidences) — must not throw and
    // records the 1.0 placeholder.
    session.processDetectionFrame(oneDartFrame);
    final r = session.processDetectionFrame(oneDartFrame);
    await session.persistEmittedDarts(oneDartFrame, Uint8List.fromList(const [1]),
        turnOrdinal: 1,
        firstDartOrdinal: r.firstEmittedDartOrdinal!,
        gameId: 'g',
        count: r.emittedDarts.length);
    expect(store.saved.single.predictedDarts.single.conf, 1.0);
  });

  test('persistEmittedDarts is a no-op without a store or with count 0', () async {
    final store = _FakeCaptureStore();
    final withStore = AutoScorerSession(captureStore: store);
    await withStore.persistEmittedDarts(oneDartFrame,
        Uint8List.fromList(const [1]),
        turnOrdinal: 1, firstDartOrdinal: 1, gameId: 'g', count: 0);
    expect(store.saved, isEmpty);

    final noStore = AutoScorerSession();
    // Must not throw without a store.
    await noStore.persistEmittedDarts(oneDartFrame, Uint8List.fromList(const [1]),
        turnOrdinal: 1, firstDartOrdinal: 1, gameId: 'g', count: 1);
  });

  test('persistManualCapture stores a raw-space manual-handle record', () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(captureStore: store);
    final raw = Uint8List.fromList(const [7, 7]);
    final saved = await session.persistManualCapture(oneDartFrame, raw,
        turnOrdinal: 2, gameId: 'g');
    expect(saved, isTrue);
    expect(store.savedBytes.single, raw);
    final record = store.saved.single;
    expect(record.frameSpace, FrameSpace.raw);
    expect(record.handle,
        const CaptureHandle.manual(turnOrdinal: 2, sequence: 1));
    expect(record.trigger, CaptureTrigger.manual);
  });

  test('persistManualCapture returns false without a capture store', () async {
    final session = AutoScorerSession();
    expect(
        await session.persistManualCapture(
            oneDartFrame, Uint8List.fromList(const [1]),
            turnOrdinal: 1, gameId: 'g'),
        isFalse);
  });

  test('persistManualEntry stores a manual-trigger labelled-mistake record (#537)',
      () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(captureStore: store);
    final raw = Uint8List.fromList(const [5, 5]);

    await session.persistManualEntry(oneDartFrame, raw,
        turnOrdinal: 2, gameId: 'g', segment: 'T20');

    expect(store.savedBytes.single, raw); // verbatim
    final record = store.saved.single;
    expect(record.frameSpace, FrameSpace.raw);
    // Manual-triggered (user-initiated), under a manual handle.
    expect(record.trigger, CaptureTrigger.manual);
    expect(record.handle,
        const CaptureHandle.manual(turnOrdinal: 2, sequence: 1));
    // Flagged as a mistake, with the entered segment as ground truth — so it
    // lands in the "mistakes only" dataset as well as "all".
    expect(record.wasCorrected, isTrue);
    expect(record.correctedDarts.single.segment, 'T20');
  });

  test('persistManualEntry is a no-op without a capture store (#537)', () async {
    final session = AutoScorerSession();
    // Must not throw without a store.
    await session.persistManualEntry(
        oneDartFrame, Uint8List.fromList(const [1]),
        turnOrdinal: 1, gameId: 'g', segment: '20');
  });

  test('applyDartCorrection forwards a handle + corrected segment (#456)',
      () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(captureStore: store);
    await session.applyDartCorrection(
        gameId: 'g', turnOrdinal: 3, dartInTurnOrdinal: 2, segment: 'T20');
    expect(store.corrections, hasLength(1));
    final c = store.corrections.single;
    expect(c.gameId, 'g');
    expect(c.handle, const CaptureHandle(turnOrdinal: 3, dartInTurnOrdinal: 2));
    expect(c.corrected.single.segment, 'T20');
    // The game knows only the segment — no position is recorded here.
    expect(c.corrected.single.x, 0);
    expect(c.corrected.single.y, 0);
  });

  test('applyDartCorrection is a no-op without a capture store', () async {
    final session = AutoScorerSession();
    // Must not throw.
    await session.applyDartCorrection(
        gameId: 'g', turnOrdinal: 1, dartInTurnOrdinal: 1, segment: 'MISS');
  });

  test('persistCorrectedCapture saves a new corrected capture (#457 partial)',
      () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(captureStore: store);
    final raw = Uint8List.fromList(const [4, 2]);
    await session.persistCorrectedCapture(
        frame: oneDartFrame,
        bytes: raw,
        turnOrdinal: 3,
        gameId: 'g',
        segment: 'T20');
    expect(store.saved, hasLength(1));
    expect(store.savedBytes.single, raw);
    final record = store.saved.single;
    expect(record.wasCorrected, isTrue);
    expect(record.correctedDarts.single.segment, 'T20');
    expect(record.handle,
        const CaptureHandle.corrected(turnOrdinal: 3, sequence: 1));
    expect(record.trigger, CaptureTrigger.auto);
    expect(record.frameSpace, FrameSpace.raw);
  });

  test('persistCorrectedCapture keys each correction uniquely (no overwrite)',
      () async {
    // Same (turn, dart) repeated — the old (turn,dart) key collided and the
    // store overwrote, losing all but one frame (#468 follow-up). The monotonic
    // correction sequence must give each correction its own handle.
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(captureStore: store);
    await session.persistCorrectedCapture(
        frame: oneDartFrame,
        bytes: Uint8List.fromList(const [1]),
        turnOrdinal: 1,
        gameId: 'g',
        segment: 'T20');
    await session.persistCorrectedCapture(
        frame: oneDartFrame,
        bytes: Uint8List.fromList(const [2]),
        turnOrdinal: 1,
        gameId: 'g',
        segment: 'T19');
    expect(store.saved.map((r) => r.handle.key), ['t1-c1', 't1-c2']);
  });

  test('persistCorrectedCapture is a no-op without a capture store', () async {
    final session = AutoScorerSession();
    await session.persistCorrectedCapture(
        frame: oneDartFrame,
        bytes: Uint8List.fromList(const [1]),
        turnOrdinal: 1,
        gameId: 'g',
        segment: 'T20');
  });
}
