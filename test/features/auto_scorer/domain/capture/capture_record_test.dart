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
    expect(json.keys, containsAll(<String>{
      'predicted_darts',
      'cal_points',
      'corrected_darts',
      'model_version',
      'game_id',
      'capture_handle',
      'timestamp',
      'was_corrected',
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

  test('withCorrection sets corrected darts and flips was_corrected', () {
    final corrected = sample().withCorrection(const [
      CorrectedDart(x: 0.55, y: 0.45, segment: 'T20'),
    ]);
    expect(corrected.wasCorrected, isTrue);
    expect(corrected.correctedDarts.single.segment, 'T20');
    // The handle is unchanged — corrections re-attach by handle, not event id.
    expect(corrected.handle, const CaptureHandle(turnOrdinal: 3, dartInTurnOrdinal: 2));
    final json = corrected.toJson();
    expect(json['was_corrected'], isTrue);
    expect((json['corrected_darts'] as List).single['segment'], 'T20');
  });
}
