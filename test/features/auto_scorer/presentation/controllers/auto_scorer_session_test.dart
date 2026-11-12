import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/corrected_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/retention_policy.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:flutter_test/flutter_test.dart';

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
      {void Function(double)? onProgress,
      List<({String archivePath, String content})> extraFiles =
          const []}) async {}
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

  test('start enforces the retention cap (bounds storage growth, #381)', () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(captureStore: store);
    await session.start();
    expect(store.retentionCalls, 1);
  });

  test('start without a capture store is a no-op', () async {
    await AutoScorerSession().start();
  });

  test('counts every persisted frame and reports each one (#742)', () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(captureStore: store);
    final reported = <int>[];
    session.onCapturePersisted = reported.add;

    expect(session.capturesPersisted, 0);

    // Auto capture on emission (two frames confirm one dart).
    session.processDetectionFrame(oneDartFrame);
    final emitted = session.processDetectionFrame(oneDartFrame);
    await session.persistEmittedDarts(oneDartFrame, bytes,
        turnOrdinal: 1,
        firstDartOrdinal: emitted.firstEmittedDartOrdinal!,
        gameId: 'g',
        count: emitted.emittedDarts.length);
    // Manual entry for a dart the model missed, then a correction capture.
    await session.persistManualEntry(oneDartFrame, bytes,
        turnOrdinal: 1, gameId: 'g', segment: 'T20');
    await session.persistCorrectedCapture(
        frame: oneDartFrame,
        bytes: bytes,
        turnOrdinal: 1,
        gameId: 'g',
        segment: 'D5');

    expect(session.capturesPersisted, store.saved.length);
    expect(session.capturesPersisted, 3);
    // Reported once per persist, with the running total.
    expect(reported, [1, 2, 3]);
  });

  test('nothing is counted without a capture store (#742)', () async {
    final session = AutoScorerSession();
    var reports = 0;
    session.onCapturePersisted = (_) => reports++;

    await session.persistEmittedDarts(oneDartFrame, bytes,
        turnOrdinal: 1, firstDartOrdinal: 1, gameId: 'g', count: 1);
    await session.persistManualEntry(oneDartFrame, bytes,
        turnOrdinal: 1, gameId: 'g', segment: 'T20');

    expect(session.capturesPersisted, 0);
    expect(reports, 0);
  });

  test('stamps uncalibrated from the frame: no 4 cals → true, full cals → false',
      () async {
    final store = _FakeCaptureStore();
    final session = AutoScorerSession(captureStore: store);
    // A frame the model couldn't fully calibrate (unsupported config): the
    // manual-entry capture is stamped uncalibrated.
    const uncalFrame =
        DetectionFrame(calPoints: [], dartCandidates: [(x: 0.5, y: 0.35)]);
    await session.persistManualEntry(uncalFrame, bytes,
        turnOrdinal: 1, gameId: 'g', segment: 'T20');
    expect(store.saved.single.uncalibrated, isTrue);
    // A fully-calibrated frame (4 cals) is not flagged.
    await session.persistManualEntry(oneDartFrame, bytes,
        turnOrdinal: 1, gameId: 'g', segment: 'T20');
    expect(store.saved.last.uncalibrated, isFalse);
  });

  test('removeDarts re-baselines (clears the board) and reports status', () {
    final session = AutoScorerSession();
    session.processDetectionFrame(oneDartFrame);
    session.processDetectionFrame(oneDartFrame); // dart on board
    expect(session.dartsOnBoard, 1);
    final status = session.removeDarts();
    expect(status.phase, TrackerPhase.rebaselined);
    expect(session.dartsOnBoard, 0);
  });

  // --- YOLOView streaming path ---

  test('processDetectionFrame emits after confirm', () {
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

  group('board-clear auto-advance (#805)', () {
    const threeDarts = <BoardPoint>[
      (x: 0.5, y: 0.35),
      (x: 0.4, y: 0.45),
      (x: 0.6, y: 0.45),
    ];
    final threeDartFrame =
        DetectionFrame(calPoints: cals, dartCandidates: threeDarts);
    final emptyFrame = DetectionFrame(calPoints: cals, dartCandidates: const []);
    final strayFrame = DetectionFrame(
        calPoints: cals, dartCandidates: const [(x: 0.3, y: 0.6)]);

    // Normal preset: 6 empty frames before the board counts as cleared.
    AutoScorerSession normalSession() => AutoScorerSession(
          tracker: DartTracker(
              config: const DartTrackerConfig(emptyFramesToRebaseline: 6)),
        );

    /// Feeds [frame] [n] times; true if any of them reported a clear-advance.
    bool feed(AutoScorerSession s, DetectionFrame frame, int n) {
      var cleared = false;
      for (var i = 0; i < n; i++) {
        if (s.processDetectionFrame(frame).boardClearedAfterThrow) {
          cleared = true;
        }
      }
      return cleared;
    }

    test('pulling the camera-seen darts advances the turn', () {
      final s = normalSession();
      expect(feed(s, threeDartFrame, 2), isFalse); // 3 darts emitted
      expect(feed(s, emptyFrame, 6), isTrue);
    });

    test('a hand-added dart after NEXT-before-pull never advances the turn',
        () {
      final s = normalSession();
      feed(s, threeDartFrame, 2); // turn N: 3 camera darts
      s.onTurnAdvanced(); // NEXT tapped, darts still on the board
      feed(s, threeDartFrame, 2);
      // Pull: the game declines this clear (0 darts in the new turn).
      expect(feed(s, emptyFrame, 6), isFalse);
      // Turn N+1: the camera catches dart 1 once and never confirms it; the
      // player adds it by hand; the board reads empty. Before #805 this fired.
      expect(feed(s, strayFrame, 1), isFalse);
      expect(feed(s, emptyFrame, 6), isFalse);
      // A normal camera turn afterwards still advances on the pull.
      s.onTurnAdvanced();
      expect(feed(s, threeDartFrame, 2), isFalse);
      expect(feed(s, emptyFrame, 6), isTrue);
    });

    test('remove darts disarms it', () {
      final s = normalSession();
      feed(s, threeDartFrame, 2);
      s.removeDarts();
      feed(s, strayFrame, 1);
      expect(feed(s, emptyFrame, 6), isFalse);
    });
  });
}
