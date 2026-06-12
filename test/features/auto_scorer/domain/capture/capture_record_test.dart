import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/corrected_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/predicted_dart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CaptureRecord sample() => CaptureRecord(
        predictedDarts: const [
          PredictedDart(x: 0.51, y: 0.49, conf: 0.92),
        ],
        calPoints: const [
          (x: 0.5, y: 0.2),
          (x: 0.5, y: 0.8),
          (x: 0.2, y: 0.5),
          (x: 0.8, y: 0.5),
        ],
        modelVersion: 'yolov11n-2026-05-31',
        gameId: 'game-abc',
        handle: const CaptureHandle(turnOrdinal: 3, dartInTurnOrdinal: 2),
        timestamp: DateTime.utc(2026, 6, 2, 12, 30),
      );

  test('sidecar JSON has exactly the probe-contract keys', () {
    final json = sample().toJson();
    // unorderedEquals (not containsAll) so an added/renamed key fails the test —
    // the sidecar shape is the probe ingest contract.
    expect(json.keys, unorderedEquals(<String>{
      'predicted_darts',
      'cal_points',
      'corrected_darts',
      'model_version',
      'game_id',
      'capture_handle',
      'timestamp',
      'was_corrected',
      'frame_space',
      'frame_width',
      'frame_height',
      'trigger',
    }));
    expect(json['capture_handle'], 't3-d2');
    expect(json['was_corrected'], isFalse);
    expect(json['cal_points'], hasLength(4));
    expect((json['predicted_darts'] as List).single, {
      'x': 0.51,
      'y': 0.49,
      'conf': 0.92,
    });
  });

  test('round-trips through JSON', () {
    final original = sample();
    final restored = CaptureRecord.fromJson(original.toJson());
    expect(restored.gameId, original.gameId);
    expect(restored.handle, original.handle);
    expect(restored.modelVersion, original.modelVersion);
    expect(restored.timestamp, original.timestamp);
    expect(restored.predictedDarts.single.conf, 0.92);
    expect(restored.calPoints, original.calPoints);
    expect(restored.wasCorrected, isFalse);
  });

  test('round-trips a corrected-sequence handle (t<turn>-c<seq>)', () {
    final original = CaptureRecord(
      predictedDarts: const [],
      calPoints: const [],
      modelVersion: 'm',
      gameId: 'g',
      handle: const CaptureHandle.corrected(turnOrdinal: 3, sequence: 1),
      timestamp: DateTime.utc(2026, 6, 12),
    ).withCorrection(const [CorrectedDart(x: 0, y: 0, segment: 'T20')]);
    final json = original.toJson();
    expect(json['capture_handle'], 't3-c1');
    final restored = CaptureRecord.fromJson(json);
    expect(restored.handle, const CaptureHandle.corrected(turnOrdinal: 3, sequence: 1));
    expect(restored.wasCorrected, isTrue);
    // No `trigger` key churn: a corrected capture is auto-triggered.
    expect(restored.trigger, CaptureTrigger.auto);
  });

  test('round-trips frame space + dims (raw capture)', () {
    final original = CaptureRecord(
      predictedDarts: const [],
      calPoints: const [],
      modelVersion: 'm',
      gameId: 'g',
      handle: const CaptureHandle(turnOrdinal: 1, dartInTurnOrdinal: 1),
      timestamp: DateTime.utc(2026, 6, 4),
      frameSpace: FrameSpace.raw,
      frameWidth: 1280,
      frameHeight: 720,
    );
    final json = original.toJson();
    expect(json['frame_space'], 'raw');
    expect(json['frame_width'], 1280);
    expect(json['frame_height'], 720);
    final restored = CaptureRecord.fromJson(json);
    expect(restored.frameSpace, FrameSpace.raw);
    expect(restored.frameWidth, 1280);
    expect(restored.frameHeight, 720);
  });

  test('pre-brief sidecars default to 800×800 letterbox', () {
    // An old sidecar written before the frame_space/dims keys existed.
    final legacy = <String, dynamic>{
      'predicted_darts': const [],
      'cal_points': const [],
      'corrected_darts': const [],
      'model_version': 'old',
      'game_id': 'g',
      'capture_handle': 't1-d1',
      'timestamp': DateTime.utc(2026, 5, 1).toIso8601String(),
      'was_corrected': false,
    };
    final restored = CaptureRecord.fromJson(legacy);
    expect(restored.frameSpace, FrameSpace.letterbox800);
    expect(restored.frameWidth, 800);
    expect(restored.frameHeight, 800);
  });

  test('round-trips the capture trigger', () {
    final manual = CaptureRecord(
      predictedDarts: const [],
      calPoints: const [],
      modelVersion: 'm',
      gameId: 'g',
      handle: const CaptureHandle.manual(turnOrdinal: 3, sequence: 1),
      timestamp: DateTime.utc(2026, 6, 11),
      trigger: CaptureTrigger.manual,
    );
    expect(manual.toJson()['trigger'], 'manual');
    expect(CaptureRecord.fromJson(manual.toJson()).trigger,
        CaptureTrigger.manual);
    // A record left at its default serialises as auto.
    expect(sample().toJson()['trigger'], 'auto');
  });

  test('pre-#455 sidecars infer trigger from the handle kind', () {
    // Old sidecars carry no `trigger` key — origin is inferred from the handle
    // (the convention this field replaces): -m ⇒ manual, -d ⇒ auto.
    Map<String, dynamic> legacy(String handle) => <String, dynamic>{
          'predicted_darts': const [],
          'cal_points': const [],
          'corrected_darts': const [],
          'model_version': 'old',
          'game_id': 'g',
          'capture_handle': handle,
          'timestamp': DateTime.utc(2026, 5, 1).toIso8601String(),
          'was_corrected': false,
        };
    expect(CaptureRecord.fromJson(legacy('t3-m1')).trigger,
        CaptureTrigger.manual);
    expect(CaptureRecord.fromJson(legacy('t3-d2')).trigger,
        CaptureTrigger.auto);
  });

  test('withCorrection sets corrected darts and flips was_corrected', () {
    final raw = CaptureRecord(
      predictedDarts: const [],
      calPoints: const [],
      modelVersion: 'm',
      gameId: 'g',
      handle: const CaptureHandle(turnOrdinal: 3, dartInTurnOrdinal: 2),
      timestamp: DateTime.utc(2026, 6, 4),
      frameSpace: FrameSpace.raw,
      frameWidth: 1280,
      frameHeight: 720,
      trigger: CaptureTrigger.manual,
    );
    final corrected = raw.withCorrection(const [
      CorrectedDart(x: 0.55, y: 0.45, segment: 'T20'),
    ]);
    expect(corrected.wasCorrected, isTrue);
    // Frame space + dims + trigger survive a correction (re-attached by handle).
    expect(corrected.frameSpace, FrameSpace.raw);
    expect(corrected.frameWidth, 1280);
    expect(corrected.frameHeight, 720);
    expect(corrected.trigger, CaptureTrigger.manual);
    expect(corrected.correctedDarts.single.segment, 'T20');
    // The handle is unchanged — corrections re-attach by handle, not event id.
    expect(corrected.handle, const CaptureHandle(turnOrdinal: 3, dartInTurnOrdinal: 2));
    final json = corrected.toJson();
    expect(json['was_corrected'], isTrue);
    expect((json['corrected_darts'] as List).single['segment'], 'T20');
  });
}
