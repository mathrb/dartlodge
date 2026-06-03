import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/corrected_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/predicted_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';

/// The sidecar record stored alongside each captured frame (#381 §6).
///
/// Every detection — and especially every correction — is a labelled training
/// example. The JSON shape is the probe's ingest contract; do not add or rename
/// keys without the reciprocal `ddp-preprocess` change in the probe repo.
class CaptureRecord {
  final List<PredictedDart> predictedDarts;
  final List<BoardPoint> calPoints;
  final List<CorrectedDart> correctedDarts;
  final String modelVersion;
  final String gameId;
  final CaptureHandle handle;
  final DateTime timestamp;
  final bool wasCorrected;

  const CaptureRecord({
    required this.predictedDarts,
    required this.calPoints,
    required this.modelVersion,
    required this.gameId,
    required this.handle,
    required this.timestamp,
    this.correctedDarts = const [],
    this.wasCorrected = false,
  });

  Map<String, dynamic> toJson() => {
        'predicted_darts': [for (final d in predictedDarts) d.toJson()],
        'cal_points': [
          for (final p in calPoints) {'x': p.x, 'y': p.y}
        ],
        'corrected_darts': [for (final d in correctedDarts) d.toJson()],
        'model_version': modelVersion,
        'game_id': gameId,
        'capture_handle': handle.key,
        'timestamp': timestamp.toIso8601String(),
        'was_corrected': wasCorrected,
      };

  factory CaptureRecord.fromJson(Map<String, dynamic> json) => CaptureRecord(
        predictedDarts: [
          for (final d in (json['predicted_darts'] as List))
            PredictedDart.fromJson((d as Map).cast<String, dynamic>())
        ],
        calPoints: [
          for (final p in (json['cal_points'] as List))
            (x: ((p as Map)['x'] as num).toDouble(), y: (p['y'] as num).toDouble())
        ],
        correctedDarts: [
          for (final d in (json['corrected_darts'] as List? ?? const []))
            CorrectedDart.fromJson((d as Map).cast<String, dynamic>())
        ],
        modelVersion: json['model_version'] as String,
        gameId: json['game_id'] as String,
        handle: CaptureHandle.parse(json['capture_handle'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        wasCorrected: json['was_corrected'] as bool? ?? false,
      );

  /// Returns a copy with the user's correction applied: replaces
  /// [correctedDarts] and flips [wasCorrected] true. Keyed by [handle], so this
  /// survives the event-id churn that per-dart correction causes (#376 §3.1).
  CaptureRecord withCorrection(List<CorrectedDart> corrected) => CaptureRecord(
        predictedDarts: predictedDarts,
        calPoints: calPoints,
        correctedDarts: corrected,
        modelVersion: modelVersion,
        gameId: gameId,
        handle: handle,
        timestamp: timestamp,
        wasCorrected: true,
      );
}
